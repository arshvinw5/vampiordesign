import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vampiordesigns/core/auth/auth_tokens.dart';
import 'package:vampiordesigns/core/auth/session_events.dart';
import 'package:vampiordesigns/core/error/failures.dart';
import 'package:vampiordesigns/core/network/api_endpoints.dart';
import 'package:vampiordesigns/core/network/auth_interceptor.dart';
import 'package:vampiordesigns/core/network/dio_error_mapper.dart';
import 'package:vampiordesigns/core/storage/preferences_data_source.dart';
import 'package:vampiordesigns/core/storage/token_storage.dart';
import 'package:vampiordesigns/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vampiordesigns/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vampiordesigns/mock_backend/database/app_database.dart';
import 'package:vampiordesigns/mock_backend/mock_api_interceptor.dart';
import 'package:vampiordesigns/mock_backend/mock_auth_server.dart';
import 'package:vampiordesigns/mock_backend/security/mock_token_service.dart';

import '../helpers/fakes.dart';

/// Real client stack (Dio + AuthInterceptor + repository) against the real
/// mock server. Client and server get separate clocks so clock skew can be
/// simulated.
class _Stack {
  _Stack._(this.repo, this.tokens, this.sessions, this.events, this.client, this.server);

  static Future<_Stack> build({TestClock? clientClock, TestClock? serverClock}) async {
    final client = clientClock ?? TestClock();
    final serverTime = serverClock ?? client;
    final sessions = FakeSessionStore();
    final mock = MockApiInterceptor(
      MockAuthServer(
        users: FakeUserStore(),
        sessions: sessions,
        tokens: MockTokenService(clock: serverTime.call),
      ),
      latency: Duration.zero,
    );
    final tokens = InMemoryTokenStorage();
    final events = SessionEvents();
    Dio dio(List<Interceptor> i) =>
        Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))..interceptors.addAll(i);
    final bare = dio([mock]);
    final main = dio([
      AuthInterceptor(storage: tokens, bareDio: bare, events: events, clock: client.call),
      mock,
    ]);
    SharedPreferences.setMockInitialValues({});
    final repo = AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(main, clock: client.call),
      tokens: tokens,
      prefs: PreferencesDataSource(await SharedPreferences.getInstance()),
    );
    return _Stack._(repo, tokens, sessions, events, client, serverTime);
  }

  final AuthRepositoryImpl repo;
  final InMemoryTokenStorage tokens;
  final FakeSessionStore sessions;
  final SessionEvents events;
  final TestClock client;
  final TestClock server;

  /// Each login and each refresh creates exactly one server session.
  int get refreshCount => sessions.sessions.length - 1;

  Future<void> login() async {
    final r = await repo.login(
      identifier: AppDatabase.demoEmail,
      password: AppDatabase.demoPassword,
    );
    expect(r.isRight(), isTrue);
  }
}

class _MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  group('Login / register persist tokens', () {
    test('login saves the token pair', () async {
      final s = await _Stack.build();
      await s.login();
      expect(s.tokens.tokens?.accessToken.split('.'), hasLength(3));
      expect(s.tokens.tokens?.accessExpiresAt, s.client.now.add(const Duration(seconds: 60)));
    });

    test('failed login stores nothing', () async {
      final s = await _Stack.build();
      final r = await s.repo.login(identifier: AppDatabase.demoEmail, password: 'wrong1');
      expect(r.fold((f) => f, (_) => null), isA<InvalidCredentialsFailure>());
      expect(s.tokens.tokens, isNull);
    });

    test('register saves the token pair', () async {
      final s = await _Stack.build();
      final r = await s.repo.register(
        fullName: 'Jane Doe',
        email: 'jane@doe.com',
        mobile: '712345678',
        password: 'abcdefg1',
      );
      expect(r.isRight(), isTrue);
      expect(s.tokens.tokens, isNotNull);
    });
  });

  group('AuthInterceptor', () {
    test('valid token: /auth/me succeeds without refreshing', () async {
      final s = await _Stack.build();
      await s.login();
      final r = await s.repo.getCurrentSession();
      expect(r.getOrElse(() => throw StateError('left')).user.email, AppDatabase.demoEmail);
      expect(s.refreshCount, 0);
    });

    test('expired access token is refreshed before the request (rotation)', () async {
      final s = await _Stack.build();
      await s.login();
      final before = s.tokens.tokens!;
      s.client.advance(const Duration(seconds: 61));

      final r = await s.repo.getCurrentSession();
      expect(r.isRight(), isTrue);
      expect(s.refreshCount, 1);
      expect(s.tokens.tokens!.refreshToken, isNot(before.refreshToken));
      expect(s.sessions.sessions[before.refreshToken]!.revoked, isTrue);
    });

    test('server says 401 (clock skew): refresh once, retry, succeed', () async {
      final client = TestClock();
      final server = TestClock();
      final s = await _Stack.build(clientClock: client, serverClock: server);
      await s.login();
      server.advance(const Duration(seconds: 90)); // client still thinks it's valid

      final r = await s.repo.getCurrentSession();
      expect(r.isRight(), isTrue);
      expect(s.refreshCount, 1);
    });

    test('concurrent 401s trigger a single refresh', () async {
      final client = TestClock();
      final server = TestClock();
      final s = await _Stack.build(clientClock: client, serverClock: server);
      await s.login();
      server.advance(const Duration(seconds: 90));

      final results = await Future.wait([
        s.repo.getCurrentSession(),
        s.repo.getCurrentSession(),
        s.repo.getCurrentSession(),
      ]);
      expect(results.every((r) => r.isRight()), isTrue);
      expect(s.refreshCount, 1);
    });

    test('revoked refresh token → tokens cleared, session-expired event, failure', () async {
      final s = await _Stack.build();
      await s.login();
      final refresh = s.tokens.tokens!.refreshToken;
      await s.sessions.revoke(refresh); // e.g. logged out on another device
      s.client.advance(const Duration(seconds: 61));

      var fired = 0;
      final sub = s.events.onSessionExpired.listen((_) => fired++);
      addTearDown(sub.cancel);

      final r = await s.repo.getCurrentSession();
      await Future<void>.delayed(Duration.zero);
      expect(r.fold((f) => f, (_) => null), isA<SessionExpiredFailure>());
      expect(s.tokens.tokens, isNull);
      expect(fired, 1);
    });

    test('no stored tokens → /auth/me 401 → SessionExpiredFailure', () async {
      final s = await _Stack.build();
      final r = await s.repo.getCurrentSession();
      expect(r.fold((f) => f, (_) => null), isA<SessionExpiredFailure>());
    });
  });

  group('restoreSession (auto-login)', () {
    Future<void> keepSignedIn(_Stack s, bool v) => s.repo.setKeepSignedIn(v);

    test('no stored tokens → SessionExpiredFailure', () async {
      final s = await _Stack.build();
      final r = await s.repo.restoreSession();
      expect(r.fold((f) => f, (_) => null), isA<SessionExpiredFailure>());
    });

    test('tokens + keepSignedIn → session restored via /auth/me', () async {
      final s = await _Stack.build();
      await s.login();
      await keepSignedIn(s, true);
      final r = await s.repo.restoreSession();
      expect(r.getOrElse(() => throw StateError('left')).user.email, AppDatabase.demoEmail);
    });

    test('expired access token → refreshed during restore', () async {
      final s = await _Stack.build();
      await s.login();
      await keepSignedIn(s, true);
      s.client.advance(const Duration(minutes: 5));
      expect((await s.repo.restoreSession()).isRight(), isTrue);
      expect(s.refreshCount, 1);
    });

    test('keepSignedIn off → tokens cleared, nothing restored', () async {
      final s = await _Stack.build();
      await s.login();
      await keepSignedIn(s, false);
      final r = await s.repo.restoreSession();
      expect(r.fold((f) => f, (_) => null), isA<SessionExpiredFailure>());
      expect(s.tokens.tokens, isNull);
    });

    test('revoked refresh token → SessionExpiredFailure, tokens cleared', () async {
      final s = await _Stack.build();
      await s.login();
      await keepSignedIn(s, true);
      await s.sessions.revoke(s.tokens.tokens!.refreshToken);
      s.client.advance(const Duration(minutes: 5));
      final r = await s.repo.restoreSession();
      expect(r.fold((f) => f, (_) => null), isA<SessionExpiredFailure>());
      expect(s.tokens.tokens, isNull);
    });
  });

  group('Logout', () {
    test('revokes the server session and clears secure storage', () async {
      final s = await _Stack.build();
      await s.login();
      final refresh = s.tokens.tokens!.refreshToken;
      expect(await s.repo.logout(), const Right<Failure, Unit>(unit));
      expect(s.tokens.tokens, isNull);
      expect(s.sessions.sessions[refresh]!.revoked, isTrue);
    });

    test('clears local tokens even when the server is unreachable', () async {
      final remote = _MockRemote();
      when(() => remote.logout(any())).thenThrow(
        DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline'),
      );
      final tokens = InMemoryTokenStorage()
        ..tokens = AuthTokens(
          accessToken: 'a',
          refreshToken: 'r',
          accessExpiresAt: DateTime.utc(2030),
        );
      SharedPreferences.setMockInitialValues({});
      final repo = AuthRepositoryImpl(
        remote: remote,
        tokens: tokens,
        prefs: PreferencesDataSource(await SharedPreferences.getInstance()),
      );
      expect((await repo.logout()).isRight(), isTrue);
      expect(tokens.tokens, isNull);
    });
  });

  group('SecureTokenStorage', () {
    test('round-trips the pair and clears it', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureTokenStorage();
      expect(await storage.read(), isNull);
      final t = AuthTokens(
        accessToken: 'acc',
        refreshToken: 'ref',
        accessExpiresAt: DateTime.utc(2026, 11, 2, 12),
      );
      await storage.save(t);
      expect(await storage.read(), t);
      await storage.clear();
      expect(await storage.read(), isNull);
    });

    test('partial data is treated as no session', () async {
      FlutterSecureStorage.setMockInitialValues({SecureTokenStorage.accessTokenKey: 'acc'});
      expect(await SecureTokenStorage().read(), isNull);
    });
  });

  test('AuthTokens expiry uses a 10s safety margin', () {
    final t = AuthTokens(
      accessToken: 'a',
      refreshToken: 'r',
      accessExpiresAt: DateTime.utc(2026, 1, 1, 0, 1),
    );
    expect(t.isAccessExpired(DateTime.utc(2026, 1, 1, 0, 0, 49)), isFalse);
    expect(t.isAccessExpired(DateTime.utc(2026, 1, 1, 0, 0, 50)), isTrue);
  });

  group('DioErrorMapper', () {
    final opts = RequestOptions(path: '/x');
    Failure map(int c, [Object? d]) => DioErrorMapper.map(
      DioException.badResponse(
        statusCode: c,
        requestOptions: opts,
        response: Response(requestOptions: opts, statusCode: c, data: d),
      ),
    );

    test('timeouts / connection → NetworkFailure', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          DioErrorMapper.map(DioException(requestOptions: opts, type: t)),
          isA<NetworkFailure>(),
        );
      }
    });

    test('status codes', () {
      expect(map(401), isA<InvalidCredentialsFailure>());
      expect(map(404), isA<UserNotFoundFailure>());
      expect(
        map(409, {'message': 'Mobile number already registered'}),
        const ConflictFailure('Mobile number already registered'),
      );
      expect(map(500), isA<ServerFailure>());
    });
  });
}
