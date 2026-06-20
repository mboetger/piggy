# piggy_farmer SDK

A robust, reusable Dart SDK for building high-performance PostgreSQL-backed task queues.

## Core Components

- **`PiggyClient`**: A lightweight publisher for enqueuing jobs into topics.
- **`PiggyWorker`**: A resilient consumer loop that connects to PostgreSQL `LISTEN/NOTIFY` channels and utilizes `SKIP LOCKED` to safely pull jobs down. Supports automatic fault tolerance, `maxRetries`, and `timeoutSeconds`.
- **`PiggyMigrations`**: A built-in programmatic database schema upgrader that keeps the `tasks` tables secure across versions.

## Example

Check out `example/piggy_farmer_example.dart` for a comprehensive boilerplate on how to instantiate the Client and Worker!
