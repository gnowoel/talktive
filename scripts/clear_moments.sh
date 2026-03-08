#!/bin/bash

# A script to delete all moments, comments, and likes in your local 'talktive' database.
# This keeps your account, profiles, and chats intact.

echo "⚠️  WARNING: This will delete all moments, moment comments, and moment likes."
read -p "Are you absolutely sure you want to proceed? (y/N) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Operation cancelled."
    exit 1
fi

echo "🗑️  Deleting moment data..."
docker exec talktive_server-postgres-1 psql -U postgres -d talktive -c "
DELETE FROM moment_likes;
DELETE FROM moment_comments;
DELETE FROM moment;
"

echo "✅ Moment data has been successfully cleared!"
