import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vampiordesigns/core/database/app_database.dart';
import 'package:vampiordesigns/core/error/exceptions.dart';
import 'package:vampiordesigns/core/error/failures.dart';
import 'package:vampiordesigns/core/network/dio_error_mapper.dart';
import 'package:vampiordesigns/core/network/mock/mock_api_interceptor.dart';
import 'package:vampiordesigns/core/network/mock/mock_auth_server.dart';
import 'package:vampiordesigns/core/storage/preferences_data_source.dart';
import 'package:vampiordesigns/core/utils/password_hasher.dart';
import 'package:vampiordesigns/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vampiordesigns/features/auth/data/datasources/user_local_data_source.dart';
import 'package:vampiordesigns/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vampiordesigns/features/auth/domain/entities/auth_session.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late UserLocalDataSourceImpl users;

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    users = UserLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  group('UserLocalDataSource (SQLite)', () {
    test('seeds the demo user', () async {
      final demo = await users.findByIdentifier(AppDatabase.demoEmail);
      expect(demo?.fullName, 'Demo User');
      expect(PasswordHasher.verify(AppDatabase.demoPassword, demo!.passwordHash), isTrue);
    });

    test('inserts and finds by email (case-insensitive) or any mobile format', () async {
      await users.insertUser(
        fullName: 'Jane Doe',
        email: 'Jane@Doe.com',
        mobile: '712345678',
        passwordHash: 'h',
      );
      expect((await users.findByIdentifier('JANE@doe.com'))?.fullName, 'Jane Doe');
      expect((await users.findByIdentifier('0712345678'))?.email, 'jane@doe.com');
      expect((await users.findByIdentifier('+94 71 234 5678'))?.email, 'jane@doe.com');
      expect(await users.findByIdentifier('nobody@x.com'), isNull);
    });

    test('rejects duplicate email / mobile', () async {
      expect(
        () => users.insertUser(fullName: 'A B', email: AppDatabase.demoEmail, mobile: '700000000', passwordHash: 'h'),
        throwsA(isA<DuplicateUserException>().having((e) => e.field, 'field', 'email')),
      );
      expect(
        () => users.insertUser(fullName: 'A B', email: 'new@x.com', mobile: AppDatabase.demoMobile, passwordHash: 'h'),
        throwsA(isA<DuplicateUserException>().having((e) => e.field, 'field', 'mobile')),
      );
    });
  });

  group('Dio + MockApiInterceptor + repository', () {
    late AuthRepositoryImpl repo;
    late PreferencesDataSource prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = PreferencesDataSource(await SharedPreferences.getInstance());
      final dio = Dio(BaseOptions(baseUrl: 'https://api.vampior.mock/v1'))
        ..interceptors.add(MockApiInterceptor(MockAuthServer(users), latency: Duration.zero));
      repo = AuthRepositoryImpl(AuthRemoteDataSourceImpl(dio), prefs);
    });

    test('login 200 → Right(session)', () async {
      final r = await repo.login(identifier: AppDatabase.demoEmail, password: AppDatabase.demoPassword);
      final session = r.getOrElse(() => throw StateError('expected Right'));
      expect(session.user.email, AppDatabase.demoEmail);
      expect(session.token, startsWith('mock.'));
    });

    test('login with mobile works', () async {
      final r = await repo.login(identifier: '0771234567', password: AppDatabase.demoPassword);
      expect(r.isRight(), isTrue);
    });

    test('login 401 → InvalidCredentialsFailure', () async {
      final r = await repo.login(identifier: AppDatabase.demoEmail, password: 'wrongpass');
      expect(r, const Left<Failure, AuthSession>(InvalidCredentialsFailure('Incorrect email/mobile or password')));
    });

    test('register 201 then 409 on duplicate', () async {
      Future<Either<Failure, AuthSession>> reg() =>
          repo.register(fullName: 'Jane Doe', email: 'jane@doe.com', mobile: '712345678', password: 'abcdefg1');
      expect((await reg()).isRight(), isTrue);
      final dup = await reg();
      expect(dup.fold((f) => f, (_) => null), const ConflictFailure('Email already registered'));
      // The new user can log in.
      expect((await repo.login(identifier: 'jane@doe.com', password: 'abcdefg1')).isRight(), isTrue);
    });

    test('forgot password: 200 for known user, 404 otherwise', () async {
      expect((await repo.requestPasswordReset(AppDatabase.demoEmail)).isRight(), isTrue);
      final r = await repo.requestPasswordReset('ghost@x.com');
      expect(r.fold((f) => f, (_) => null), isA<UserNotFoundFailure>());
    });

    test('network@ → NetworkFailure, server@ → ServerFailure', () async {
      final net = await repo.login(identifier: 'network@x.com', password: '123456');
      expect(net.fold((f) => f, (_) => null), isA<NetworkFailure>());
      final srv = await repo.login(identifier: 'server@x.com', password: '123456');
      expect(srv.fold((f) => f, (_) => null), isA<ServerFailure>());
    });

    test('remembered identifier round-trips through prefs', () async {
      await repo.setRememberedIdentifier(' demo@vampior.com ');
      expect(repo.getRememberedIdentifier(), const Right<Failure, String?>('demo@vampior.com'));
      await repo.setRememberedIdentifier(null);
      expect(repo.getRememberedIdentifier(), const Right<Failure, String?>(null));
    });
  });

  group('DioErrorMapper', () {
    final opts = RequestOptions(path: '/x');
    Response<dynamic> res(int code, [Object? data]) =>
        Response(requestOptions: opts, statusCode: code, data: data);

    test('timeouts / connection → NetworkFailure', () {
      for (final t in [DioExceptionType.connectionTimeout, DioExceptionType.receiveTimeout, DioExceptionType.connectionError]) {
        expect(DioErrorMapper.map(DioException(requestOptions: opts, type: t)), isA<NetworkFailure>());
      }
    });

    test('status codes', () {
      Failure map(int c, [Object? d]) => DioErrorMapper.map(
            DioException.badResponse(statusCode: c, requestOptions: opts, response: res(c, d)),
          );
      expect(map(401), isA<InvalidCredentialsFailure>());
      expect(map(404), isA<UserNotFoundFailure>());
      expect(map(409, {'message': 'Mobile number already registered'}),
          const ConflictFailure('Mobile number already registered'));
      expect(map(500), isA<ServerFailure>());
    });
  });
}
