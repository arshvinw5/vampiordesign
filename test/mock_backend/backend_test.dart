import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vampiordesigns/core/network/api_endpoints.dart';
import 'package:vampiordesigns/mock_backend/database/app_database.dart';
import 'package:vampiordesigns/mock_backend/mock_auth_server.dart';
import 'package:vampiordesigns/mock_backend/security/mock_token_service.dart';
import 'package:vampiordesigns/mock_backend/security/password_hasher.dart';
import 'package:vampiordesigns/mock_backend/stores/session_store.dart';
import 'package:vampiordesigns/mock_backend/stores/user_store.dart';

import '../helpers/fakes.dart';

void main() {
  sqfliteFfiInit();

  group('SQLite stores', () {
    late AppDatabase db;
    late SqliteUserStore users;
    late SqliteSessionStore sessions;

    setUp(() async {
      db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      users = SqliteUserStore(db);
      sessions = SqliteSessionStore(db);
    });
    tearDown(() => db.close());

    test('seeds the demo user', () async {
      final demo = await users.findByIdentifier(AppDatabase.demoEmail);
      expect(demo?.fullName, 'Demo User');
      expect(PasswordHasher.verify(AppDatabase.demoPassword, demo!.passwordHash), isTrue);
      expect((await users.findById(demo.id))?.email, AppDatabase.demoEmail);
    });

    test('finds by email (case-insensitive) or any mobile format', () async {
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
        () => users.insertUser(
          fullName: 'A B',
          email: AppDatabase.demoEmail,
          mobile: '700000000',
          passwordHash: 'h',
        ),
        throwsA(isA<DuplicateUserException>().having((e) => e.field, 'field', 'email')),
      );
      expect(
        () => users.insertUser(
          fullName: 'A B',
          email: 'new@x.com',
          mobile: AppDatabase.demoMobile,
          passwordHash: 'h',
        ),
        throwsA(isA<DuplicateUserException>().having((e) => e.field, 'field', 'mobile')),
      );
    });

    test('sessions: create, find, revoke', () async {
      final exp = DateTime.utc(2030);
      await sessions.create(refreshToken: 'r1', userId: 1, expiresAt: exp);
      final s = await sessions.find('r1');
      expect(s?.userId, 1);
      expect(s?.revoked, isFalse);
      expect(s?.isUsable(DateTime.utc(2029)), isTrue);
      expect(s?.isUsable(DateTime.utc(2031)), isFalse);
      await sessions.revoke('r1');
      expect((await sessions.find('r1'))?.revoked, isTrue);
      expect(await sessions.find('nope'), isNull);
    });
  });

  test('migrates a v1 database (users only) to v2 (adds sessions)', () async {
    final dir = await Directory.systemTemp.createTemp('vampior_db');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'v1.db');

    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, full_name TEXT NOT NULL, '
          'email TEXT NOT NULL UNIQUE COLLATE NOCASE, mobile TEXT NOT NULL UNIQUE, '
          'password_hash TEXT NOT NULL, created_at TEXT NOT NULL)',
        ),
      ),
    );
    await v1.insert('users', {
      'full_name': 'Old User',
      'email': 'old@x.com',
      'mobile': '700000001',
      'password_hash': 'h',
      'created_at': '2026-01-01T00:00:00Z',
    });
    await v1.close();

    final db = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    addTearDown(db.close);
    expect(await db.db.getVersion(), AppDatabase.version);
    expect((await SqliteUserStore(db).findByIdentifier('old@x.com'))?.fullName, 'Old User');
    await SqliteSessionStore(db)
        .create(refreshToken: 'r', userId: 1, expiresAt: DateTime.utc(2030));
    expect(await SqliteSessionStore(db).find('r'), isNotNull);
  });

  group('MockTokenService', () {
    test('issues verifiable access tokens that expire', () {
      final clock = TestClock();
      final svc = MockTokenService(clock: clock.call);
      final token = svc.issueAccessToken(7);
      expect(token.split('.'), hasLength(3));
      expect(svc.verifyAccessToken(token), 7);
      clock.advance(const Duration(seconds: 60));
      expect(
        () => svc.verifyAccessToken(token),
        throwsA(isA<InvalidTokenException>().having((e) => e.message, 'm', 'Access token expired')),
      );
    });

    test('rejects tampered tokens', () {
      final svc = MockTokenService();
      final parts = svc.issueAccessToken(1).split('.');
      final forged = '${parts[0]}.${svc.issueAccessToken(2).split('.')[1]}.${parts[2]}';
      expect(() => svc.verifyAccessToken(forged), throwsA(isA<InvalidTokenException>()));
      expect(() => svc.verifyAccessToken('garbage'), throwsA(isA<InvalidTokenException>()));
    });

    test('refresh tokens are random', () {
      final svc = MockTokenService();
      expect(svc.issueRefreshToken(), isNot(svc.issueRefreshToken()));
    });
  });

  group('MockAuthServer', () {
    late TestClock clock;
    late FakeSessionStore sessions;
    late MockAuthServer server;

    setUp(() {
      clock = TestClock();
      sessions = FakeSessionStore();
      server = MockAuthServer(
        users: FakeUserStore(),
        sessions: sessions,
        tokens: MockTokenService(clock: clock.call),
      );
    });

    Future<MockResponse> login() => server.handle('POST', ApiEndpoints.login, {
      'identifier': AppDatabase.demoEmail,
      'password': AppDatabase.demoPassword,
    });
    Future<MockResponse> me(String access) =>
        server.handle('GET', ApiEndpoints.me, null, headers: {'Authorization': 'Bearer $access'});

    test('login returns a token pair and stores the refresh session', () async {
      final res = await login();
      expect(res.statusCode, 200);
      expect(res.body['tokenType'], 'Bearer');
      expect(res.body['expiresIn'], 60);
      expect(res.body['user']['email'], AppDatabase.demoEmail);
      expect(res.body['user'], isNot(contains('passwordHash')));
      expect(sessions.sessions.keys, [res.body['refreshToken']]);
    });

    test('wrong password → 401', () async {
      final res = await server.handle('POST', ApiEndpoints.login, {
        'identifier': AppDatabase.demoEmail,
        'password': 'nope',
      });
      expect(res.statusCode, 401);
    });

    test('/auth/me: 200 with token; 401 when missing or expired', () async {
      final access = (await login()).body['accessToken'] as String;
      expect((await me(access)).body['user']['id'], 1);
      expect((await server.handle('GET', ApiEndpoints.me, null)).statusCode, 401);
      clock.advance(const Duration(minutes: 2));
      final expired = await me(access);
      expect(expired.statusCode, 401);
      expect(expired.body['message'], 'Access token expired');
    });

    test('refresh rotates: new pair issued, old refresh token rejected on replay', () async {
      final first = (await login()).body;
      final refreshed = await server.handle('POST', ApiEndpoints.refresh, {
        'refreshToken': first['refreshToken'],
      });
      expect(refreshed.statusCode, 200);
      expect(refreshed.body['refreshToken'], isNot(first['refreshToken']));
      expect((await me(refreshed.body['accessToken'] as String)).statusCode, 200);

      final replay = await server.handle('POST', ApiEndpoints.refresh, {
        'refreshToken': first['refreshToken'],
      });
      expect(replay.statusCode, 401);
    });

    test('logout revokes the refresh token', () async {
      final refresh = (await login()).body['refreshToken'] as String;
      expect(
        (await server.handle('POST', ApiEndpoints.logout, {'refreshToken': refresh})).statusCode,
        204,
      );
      final res = await server.handle('POST', ApiEndpoints.refresh, {'refreshToken': refresh});
      expect(res.statusCode, 401);
    });

    test('expired refresh token → 401', () async {
      final refresh = (await login()).body['refreshToken'] as String;
      clock.advance(const Duration(days: 8));
      final res = await server.handle('POST', ApiEndpoints.refresh, {'refreshToken': refresh});
      expect(res.statusCode, 401);
    });

    test('register 201 then 409 on duplicate', () async {
      final body = {
        'fullName': 'Jane Doe',
        'email': 'jane@doe.com',
        'mobile': '712345678',
        'password': 'abcdefg1',
      };
      final created = await server.handle('POST', ApiEndpoints.register, body);
      expect(created.statusCode, 201);
      expect(created.body['accessToken'], isA<String>());
      final dup = await server.handle('POST', ApiEndpoints.register, body);
      expect(dup.statusCode, 409);
      expect(dup.body['message'], 'Email already registered');
    });

    test('fault hooks: network@ throws, server@ → 500', () async {
      expect(
        () => server.handle('POST', ApiEndpoints.login, {'identifier': 'network@x.com'}),
        throwsA(isA<MockConnectionError>()),
      );
      final res = await server.handle('POST', ApiEndpoints.login, {'identifier': 'server@x.com'});
      expect(res.statusCode, 500);
    });
  });
}
