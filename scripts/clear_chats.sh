#!/bin/bash

# A script to delete all chat data in your local 'talktive' database.
# This keeps your account, profiles, and moments intact.

echo "⚠️  WARNING: This will delete all messages, private chats, and groups."
echo "   It will NOT delete your resident account or the main Plaza channel."
read -p "Are you absolutely sure you want to proceed? (y/N) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Operation cancelled."
    exit 1
fi

echo "🗑️  Deleting chat data..."
docker exec talktive_server-postgres-1 psql -U postgres -d talktive -c "
DELETE FROM message;
DELETE FROM private_chat;
DELETE FROM groups;
DELETE FROM channel_member;
DELETE FROM channel WHERE id != 1;
"

echo "✅ Chat data has been successfully cleared!"
echo "🚀 Next steps: You may need to restart your Flutter app or refresh to see the changes."
