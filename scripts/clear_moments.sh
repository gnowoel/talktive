#!/bin/bash

# A script to delete all moment data in your local 'talktive' database.
# This keeps your account, profiles, and chats intact.

echo "⚠️  WARNING: This will delete all moments, moment comments, and moment likes."
echo "   It will NOT delete your resident account or chat history."
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
echo "🚀 Next steps: You may need to restart your Flutter app or refresh to see the changes."
