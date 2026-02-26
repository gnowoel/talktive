#!/bin/bash
cd lib

# Find all files with "modern" references
find . -type f -name "*.dart" | while read -r file; do
  sed -i '' 's/_modern\.dart/\.dart/g' "$file"
  sed -i '' 's/ScreenModern/Screen/g' "$file"
  sed -i '' 's/_ScreenModern/_Screen/g' "$file"
  sed -i '' 's/MessageBubbleModern/MessageBubble/g' "$file"
  sed -i '' 's/plazaChatScreenModern/plazaChatScreen/g' "$file"
done

