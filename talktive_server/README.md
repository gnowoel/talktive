# talktive_server

This is the starting point for your Serverpod server.

To run your server, you first need to start Postgres and Redis. It's easiest to do with Docker.

    docker compose up --build --detach

Then you can start the Serverpod server.

    dart bin/main.dart

When you are finished, you can shut down Serverpod with `Ctrl-C`, then stop Postgres and Redis.

    docker compose stop

## Integration tests

The shared integration test helper in `test/integration/test_tools/serverpod_test_tools.dart`
defaults the test server output to silent mode.

This is intentional: with Serverpod `3.4.5`, the startup schema integrity check can emit a
false-positive warning for `jsonb` list columns such as `resident.languages` and
`lounge.interests` even when the test database is already fully migrated and correct.
