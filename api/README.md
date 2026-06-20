# Piggy API

A fast, lightweight Dart Frog REST API that serves as the entrypoint for enqueuing tasks onto the Piggy Platform.

## Endpoints

- `GET /status`: Returns an aggregation of the current task queue (e.g., number of pending, processing, completed, and failed tasks).
- `GET /tasks`: Returns the most recent tasks from the database.
- `POST /tasks`: Enqueues a new background task via the `PiggyClient` SDK component.

## Running

This service is launched automatically via the project's root `docker-compose.yml`.