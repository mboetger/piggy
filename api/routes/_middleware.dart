import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Pool? _pool;

Handler middleware(Handler handler) {
  return (context) async {
    if (_pool == null) {
      final host = Platform.environment['DB_HOST'] ?? 'localhost';
      final user = Platform.environment['DB_USER'] ?? 'piggy';
      final password = Platform.environment['DB_PASS'] ?? 'piggy_password';
      final database = Platform.environment['DB_NAME'] ?? 'piggy_db';

      _pool = Pool.withEndpoints(
        [Endpoint(
          host: host,
          database: database,
          username: user,
          password: password,
        )],
        settings: PoolSettings(
          maxConnectionCount: 10,
          sslMode: SslMode.disable,
        ),
      );
    }

    final response = await handler.use(provider<Pool>((_) => _pool!))(context);
    
    // Add CORS headers so Jaspr can call it
    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      },
    );
  };
}
