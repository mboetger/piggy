FROM dart:stable AS build

WORKDIR /app
COPY piggy_farmer/ piggy_farmer/
COPY frontend/ frontend/

WORKDIR /app/frontend
RUN dart pub global activate jaspr_cli
ENV PATH="/root/.pub-cache/bin:${PATH}"

# Run jaspr build
RUN dart pub get
RUN jaspr build -v

FROM nginx:alpine
COPY --from=build /app/frontend/build/jaspr /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
