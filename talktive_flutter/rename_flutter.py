import os
import re

dir_path = "/Users/leo/Develop/builds/talktive/production/talktive3/talktive_flutter/lib"

def process_file(file_path):
    if not file_path.endswith('.dart'): return
    with open(file_path, 'r') as f:
        content = f.read()
    
    new_content = content
    # Imports
    new_content = new_content.replace('floor_utils.dart', 'reputation_utils.dart')
    # Class names and methods
    new_content = new_content.replace('FloorUtils.effectiveFloor', 'ReputationUtils.computeReputation')
    new_content = new_content.replace('FloorUtils.', 'ReputationUtils.')
    
    # Model fields
    new_content = new_content.replace('creditScore', 'trustScore')
    new_content = new_content.replace('senderFloor', 'senderReputation')
    new_content = new_content.replace('authorFloor', 'authorReputation')
    new_content = new_content.replace('userFloor', 'userReputation')
    
    # JSON keys (like user['floor'] -> user['reputation'])
    new_content = new_content.replace("['floor']", "['reputation']")
    new_content = new_content.replace("['creditScore']", "['trustScore']")
    
    # Floor badge (Avatar parameter) -> We'll rename it later if needed, but let's just leave floorLevel as in DuoAvatar, or rename it to reputationLevel.
    new_content = new_content.replace('floorLevel', 'reputationLevel')
    
    if content != new_content:
        with open(file_path, 'w') as f:
            f.write(new_content)
        print(f"Updated {file_path}")

for root, dirs, files in os.walk(dir_path):
    for f in files:
        process_file(os.path.join(root, f))
print("Done")
