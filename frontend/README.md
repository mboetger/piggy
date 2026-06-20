# Piggy Frontend Dashboard

A reactive client-side dashboard built with Jaspr that gives you a visual overview of the task queue.

## Features
- Real-time polling of the `api` endpoints.
- Displays aggregate counts of pending, processing, and failed tasks.
- A manual UI button to easily inject new jobs into the `default` topic.

## Running

This service is launched automatically via the project's root `docker-compose.yml` and is accessible on `http://localhost:80`.
