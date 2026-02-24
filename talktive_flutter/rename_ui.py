import os
import re

dir_path = "/Users/leo/Develop/builds/talktive/production/talktive3/talktive_flutter/lib"

def process_file(file_path):
    if not file_path.endswith('.dart'): return
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    
    # Imports
    new_content = new_content.replace('reputation_utils.dart', 'floor_utils.dart')
    
    # Class names and methods
    new_content = new_content.replace('ReputationUtils.', 'FloorUtils.')
    new_content = new_content.replace('computeReputation', 'computeFloor')
    
    # Model fields that were formerly userReputation
    new_content = new_content.replace('senderReputation', 'senderFloor')
    new_content = new_content.replace('authorReputation', 'authorFloor')
    new_content = new_content.replace('userReputation', 'userFloor')
    
    # JSON keys 
    new_content = new_content.replace("['reputation']", "['floor']")

    # UI variables
    new_content = new_content.replace('reputationLevel', 'floorLevel')
    
    # Profile Screen Specific
    new_content = new_content.replace('_getReputationColor', '_getTrustColor')
    
    if content != new_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {file_path}")

for root, dirs, files in os.walk(dir_path):
    for f in files:
        process_file(os.path.join(root, f))
print("Done")
