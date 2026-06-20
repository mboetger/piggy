# Piggy Worker

The standalone consumer microservice for the Piggy Platform. It utilizes the `piggy_farmer` SDK to process background jobs.

## How it Works

The worker executes `PiggyWorker.start()` to connect to the PostgreSQL database (`piggy_db`) and listen for `new_task` events via `pg_notify`. When a task arrives, it securely locks the row using `FOR UPDATE SKIP LOCKED`.

If multiple workers are running, they balance the load automatically.

## Running

This service is launched automatically via the project's root `docker-compose.yml`.
