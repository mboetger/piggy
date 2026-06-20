FROM dart:stable AS build

WORKDIR /app
COPY piggy_farmer/ piggy_farmer/
COPY worker/ worker/

WORKDIR /app/worker
RUN dart pub get
RUN dart compile exe bin/worker.dart -o bin/worker

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/worker/bin/worker /app/bin/worker
CMD ["/app/bin/worker"]
