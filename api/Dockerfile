FROM dart:stable AS build

WORKDIR /app
COPY piggy_farmer/ piggy_farmer/
COPY api/ api/

RUN cp -r piggy_farmer/ api/piggy_farmer/

WORKDIR /app/api
RUN dart pub global activate dart_frog_cli
ENV PATH="/root/.pub-cache/bin:${PATH}"
RUN dart_frog build

WORKDIR /app/api/build
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/api/build/bin/server /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]
