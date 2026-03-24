#!/bin/bash

# A unified script to clear all testing data (chats, lounges, moments) in your local 'talktive' database.
# This keeps your main resident account and profiles intact while resetting all social activity.

echo "⚠️  WARNING: This will delete ALL social data:"
echo "   - All messages and private chats"
echo "   - All clubhouses (lounges) and memberships"
echo "   - All moments, comments, and likes"
echo "   - All user notifications"
echo ""
echo "   It will NOT delete resident accounts, profile metadata, or the Plaza channel."

read -p "Are you absolutely sure you want to proceed? (y/N) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Operation cancelled."
    exit 1
fi

echo "🗑️  Clearing all testing data..."

docker exec talktive_server-postgres-1 psql -U postgres -d talktive -c "
-- Clear Chat & Social Data
DELETE FROM message;
DELETE FROM private_chat;
DELETE FROM lounge;
DELETE FROM channel_member;
DELETE FROM user_notifications;
DELETE FROM channel WHERE id != 1;

-- Clear Moment Data
DELETE FROM moment_likes;
DELETE FROM moment_comments;
DELETE FROM moment;
"

echo "✅ All testing data has been successfully cleared!"
echo "🚀 Next steps: Refresh your Flutter app or restart it to see the clean state."
