import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:piggy_farmer/piggy_farmer.dart';

Future<void> main(List<String> args) async {
  final topic = Platform.environment['WORKER_TOPIC'] ?? 'default';
  print('Starting piggy_farmer worker for topic: $topic');

  final host = Platform.environment['DB_HOST'] ?? 'localhost';
  final user = Platform.environment['DB_USER'] ?? 'piggy';
  final password = Platform.environment['DB_PASS'] ?? 'piggy_password';
  final database = Platform.environment['DB_NAME'] ?? 'piggy_db';

  final endpoint = Endpoint(
    host: host,
    database: database,
    username: user,
    password: password,
  );
  
  final settings = ConnectionSettings(sslMode: SslMode.disable);

  final listenConnection = await Connection.open(endpoint, settings: settings);
  final pool = Pool.withEndpoints([endpoint], settings: PoolSettings(sslMode: SslMode.disable));

  print('Connected to database. Applying migrations if needed...');
  
  try {
    await PiggyMigrations.applyMigrations(pool);
    print('Migrations applied successfully.');
  } catch (e) {
    print('Error applying migrations: $e');
  }

  final worker = PiggyWorker(pool, listenConnection);

  worker.on(topic, (task) async {
    print('Processing task ${task.id} (try ${task.retryCount + 1}/${task.maxRetries})');
    
    // Simulate some work
    await Future.delayed(Duration(seconds: 2));

    if (task.payload?['action'] == 'fail_me') {
      throw Exception('Simulated failure');
    }

    print('Successfully processed task ${task.id}');
  });

  print('Worker listening for tasks on topic: $topic');
  await worker.start();
}
