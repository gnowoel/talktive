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

This is intentional: Serverpod `3.4.6` can still emit a false-positive startup
schema integrity warning for `jsonb` list columns such as
`resident.languages` and `lounge.interests` even when the test database is
already fully migrated and correct.

For this workspace, the warning was eliminated once by patching the local
pub-cache copy of `serverpod` to map PostgreSQL `jsonb` to `ColumnType.json` in:

`~/.pub-cache/hosted/pub.dev/serverpod-3.4.6/lib/src/database/util/column_type_extension.dart`

This fix is local to the machine and is not required for normal development or
release builds. The shared test helper already suppresses this startup noise by
default. If the warning reappears on another machine, treat it as a known
Serverpod `3.4.6` false positive unless you are actively debugging schema
mapping internals, or upgrade to a Serverpod release that includes the fix.
