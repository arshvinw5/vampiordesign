import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vampiordesigns/core/auth/auth_tokens.dart';
import 'package:vampiordesigns/core/error/failures.dart';
import 'package:vampiordesigns/core/presentation/form_controller.dart';
import 'package:vampiordesigns/features/auth/domain/entities/auth_session.dart';
import 'package:vampiordesigns/features/auth/domain/entities/user.dart';
import 'package:vampiordesigns/features/auth/domain/repositories/auth_repository.dart';
import 'package:vampiordesigns/features/auth/domain/usecases/get_remembered_identifier.dart';
import 'package:vampiordesigns/features/auth/domain/usecases/login_user.dart';
import 'package:vampiordesigns/features/auth/domain/usecases/request_password_reset.dart';
import 'package:vampiordesigns/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:vampiordesigns/features/auth/presentation/controllers/login_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  final session = AuthSession(
    user: User(
      id: 1,
      fullName: 'Jane Doe',
      email: 'jane@doe.com',
      mobile: '712345678',
      createdAt: DateTime.utc(2026),
    ),
    tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', accessExpiresAt: DateTime.utc(2030)),
  );

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.setRememberedIdentifier(any())).thenAnswer((_) async => const Right(unit));
    when(() => repo.setKeepSignedIn(any())).thenAnswer((_) async => const Right(unit));
    when(() => repo.getRememberedIdentifier()).thenReturn(const Right('saved@x.com'));
  });

  group('LoginUser', () {
    test('saves identifier when rememberMe is on', () async {
      when(
        () => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(session));
      final r = await LoginUser(repo)(
        const LoginParams(identifier: 'jane@doe.com', password: 'secret1', rememberMe: true),
      );
      expect(r, Right<Failure, AuthSession>(session));
      verify(() => repo.setRememberedIdentifier('jane@doe.com')).called(1);
      verify(() => repo.setKeepSignedIn(true)).called(1);
    });

    test('clears identifier when rememberMe is off', () async {
      when(
        () => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(session));
      await LoginUser(repo)(
        const LoginParams(identifier: 'jane@doe.com', password: 'secret1', rememberMe: false),
      );
      verify(() => repo.setRememberedIdentifier(null)).called(1);
      verify(() => repo.setKeepSignedIn(false)).called(1);
    });

    test('does not touch prefs on failure', () async {
      when(
        () => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));
      final r = await LoginUser(repo)(
        const LoginParams(identifier: 'x@y.com', password: 'nope12', rememberMe: true),
      );
      expect(r.isLeft(), isTrue);
      verifyNever(() => repo.setRememberedIdentifier(any()));
    });
  });

  group('LoginController', () {
    LoginController build() =>
        LoginController(loginUser: LoginUser(repo), getRemembered: GetRememberedIdentifier(repo));

    test('prefills remembered identifier', () => expect(build().initialIdentifier, 'saved@x.com'));

    test('idle → loading → success', () async {
      when(
        () => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(session));
      final c = build();
      final seen = <RequestStatus>[];
      c.addListener(() => seen.add(c.status));
      final result = await c.login(identifier: ' jane@doe.com ', password: 'secret1');
      expect(result, session);
      expect(seen, [RequestStatus.loading, RequestStatus.success]);
      verify(() => repo.login(identifier: 'jane@doe.com', password: 'secret1')).called(1);
    });

    test('failure exposes the message', () async {
      when(
        () => repo.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      final c = build();
      expect(await c.login(identifier: 'a@b.co', password: '123456'), isNull);
      expect(c.status, RequestStatus.failure);
      expect(c.errorMessage, const NetworkFailure().message);
    });
  });

  group('ForgotPasswordController', () {
    test('send success starts a cooldown; editing hides the notice', () async {
      when(() => repo.requestPasswordReset(any())).thenAnswer((_) async => const Right(unit));
      final c = ForgotPasswordController(
        requestReset: RequestPasswordReset(repo),
        cooldownSeconds: 30,
      );
      addTearDown(c.dispose);
      expect(await c.send('a@b.co'), isTrue);
      expect(c.sentTo, 'a@b.co');
      expect(c.cooldown, 30);
      expect(c.canResend, isFalse);
      c.onIdentifierChanged();
      expect(c.sentTo, isNull);
      expect(c.cooldown, 0);
    });
  });
}
