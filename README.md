# Piggy Platform 🐷

Piggy is a high-performance, resilient, and distributed task queuing platform built entirely in Dart and backed by PostgreSQL. It abstracts complex queuing architectures into an easy-to-use SDK, providing reliable background job processing right out of the box.

## Architecture

The platform is split into several interconnected services:

1. **`piggy_farmer` SDK**: The core task queuing engine. It provides the `PiggyClient` for enqueuing jobs and `PiggyWorker` for processing them. It uses PostgreSQL `LISTEN/NOTIFY` channels for instant pub/sub event delivery, paired with `FOR UPDATE SKIP LOCKED` transaction pools to securely load-balance jobs across multiple concurrent workers without race conditions.
2. **API (Dart Frog)**: A RESTful API that handles incoming requests to enqueue tasks and fetch pool status statistics.
3. **Frontend (Jaspr)**: A fast, reactive client-side rendered dashboard to visually monitor the task queue and manually enqueue new jobs.
4. **Worker Node(s)**: Standalone microservices running the `PiggyWorker` to execute tasks off the queue.

## Key Features

- **Distributed Workers**: Easily scales to multiple concurrent worker instances using safe transaction locking.
- **Configurable Fault Tolerance**: Each task supports configurable `maxRetries` and `timeoutSeconds`. The system automatically retries failed jobs and re-enqueues jobs if a worker crashes mid-processing.
- **Built-in Migrations**: The SDK manages additive schema migrations natively. No external database tools are required!
- **Real-Time Execution**: Achieves milliseconds-latency task pickup via PostgreSQL `pg_notify`.

## Getting Started

To spin up the entire ecosystem, simply use Docker Compose:

```bash
# Build the images and start the services
docker compose up -d
```

This command automatically:
1. Starts the PostgreSQL database (`piggy_db`).
2. Boots up the Dart Frog REST API.
3. Deploys **3 Replicas** of the Worker node to immediately start polling the queue.
4. Boots the Jaspr Frontend.

### Accessing the Dashboard

Once the containers are healthy, open your browser and navigate to:
**[http://localhost](http://localhost)**

## PiggyFarmer SDK Example

To use `piggy_farmer` in your own Dart projects, instantiate the Client and Worker components:

```dart
import 'package:piggy_farmer/piggy_farmer.dart';
import 'package:postgres/postgres.dart';

// 1. Initialize DB Connection
final pool = Pool.withEndpoints([Endpoint(host: 'localhost', database: 'piggy_db', username: 'piggy', password: 'piggy_password')]);
await PiggyMigrations.applyMigrations(pool);

// 2. Enqueue a task
final client = PiggyClient(pool);
await client.enqueue('emails', {'to': 'user@example.com'});

// 3. Process the task
final connection = await Connection.open(Endpoint(host: 'localhost', database: 'piggy_db', username: 'piggy', password: 'piggy_password'));
final worker = PiggyWorker(pool, connection);

worker.on('emails', (Task task) async {
  print('Sending email to \${task.payload?['to']}');
});

await worker.start(); // Blocks and listens for tasks
```
