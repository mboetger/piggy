import 'package:postgres/postgres.dart';
import 'package:piggy_farmer/piggy_farmer.dart';

void main() async {
  // Setup your database connection
  final endpoint = Endpoint(
    host: 'localhost',
    database: 'piggy_db',
    username: 'piggy',
    password: 'piggy_password',
  );
  
  final pool = Pool.withEndpoints([endpoint], settings: PoolSettings(sslMode: SslMode.disable));
  
  // 1. Ensure migrations are applied
  await PiggyMigrations.applyMigrations(pool);
  
  // 2. Initialize the Client to dispatch tasks
  final client = PiggyClient(pool);
  final taskId = await client.enqueue('emails', {'to': 'user@example.com', 'subject': 'Hello'});
  print('Enqueued task $taskId');
  
  // 3. Initialize the Worker to process tasks
  final listenConnection = await Connection.open(endpoint, settings: ConnectionSettings(sslMode: SslMode.disable));
  final worker = PiggyWorker(pool, listenConnection);
  
  worker.on('emails', (Task task) async {
    print('Sending email to ${task.payload?['to']}');
    // Task is automatically marked completed if this completes without throwing!
  });
  
  print('Starting worker...');
  // worker.start() will block indefinitely while listening
  // await worker.start(); 
}
