#!/bin/bash

# A handy script to reset your local database during development.

echo "⚠️  WARNING: This will completely wipe all data in your local 'talktive' database."
echo "   It will drop the public schema and recreate it from scratch."
read -p "Are you absolutely sure you want to proceed? (y/N) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Operation cancelled."
    exit 1
fi

echo "🗑️  Dropping and recreating the public schema..."
docker exec talktive_server-postgres-1 psql -U postgres -d talktive -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO postgres; GRANT ALL ON SCHEMA public TO public;"

echo "✅ Database has been successfully reset!"
echo "🚀 Next steps:"
echo "   1. Restart your Serverpod server."
echo "   2. The server will automatically re-apply all migrations and recreate the tables on startup."
