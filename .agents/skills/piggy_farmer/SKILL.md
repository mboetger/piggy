---
name: piggy_farmer
description: Instructions and architectural overview for working with the PiggyFarmer SDK (task queues, database polling, and workers).
---

# PiggyFarmer Architecture

PiggyFarmer is a robust Dart SDK for task queuing, utilizing PostgreSQL for persistence and pub/sub capabilities.

## Key Components

1. **Database Tables**:
   - `tasks`: The central queue holding all jobs. It uses an enum `task_status` (`pending`, `processing`, `completed`, `failed`).
   - `piggy_farmer_migrations`: Tracks the schema evolution securely.
   - Tasks also track `max_retries`, `retry_count`, and `timeout_seconds`.

2. **PiggyClient (`lib/src/client.dart`)**:
   - Used by publishers (e.g., the API server) to enqueue tasks.
   - Uses `client.enqueue('topic_name', payload_map)` which inserts a row into the `tasks` table.
   - Triggers a PostgreSQL `pg_notify` event via a trigger on the table.

3. **PiggyWorker (`lib/src/worker.dart`)**:
   - Used by consumer microservices.
   - Listens to PostgreSQL `LISTEN` channels (`new_task_<topic>`).
   - Uses `FOR UPDATE SKIP LOCKED` inside a transaction to safely pick up the oldest pending task, preventing race conditions among multiple worker containers.
   - If a worker crashes or takes too long, tasks are automatically retried if they exceed `timeout_seconds`. If a task throws an exception, `retry_count` is incremented until it hits `max_retries`.

## Best Practices
- Never use raw SQL to insert or update tasks directly; always use `PiggyClient` or `PiggyWorker`.
- To add a new feature that runs in the background, simply create a new worker block: `worker.on('new_feature', (task) async { ... })`.
- Ensure migrations are handled via `PiggyMigrations.applyMigrations(pool)` when the application starts up.
