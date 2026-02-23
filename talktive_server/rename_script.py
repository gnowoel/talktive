import os
import re

dir_path = "/Users/leo/Develop/builds/talktive/production/talktive3/talktive_server/lib/src"

def process_file(file_path):
    if not file_path.endswith('.dart'): return
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Do replacements
    new_content = re.sub(r'\breputation\b', 'trustScore', content)
    # Exceptions we want to fix: 
    #   if it was ApartmantService.effectiveFloor, it becomes ApartmentService.computeReputation
    #   if it was senderFloor, it becomes senderReputation
    new_content = new_content.replace('effectiveFloor', 'computeReputation')
    new_content = new_content.replace('senderFloor', 'senderReputation')
    new_content = new_content.replace('authorFloor', 'authorReputation')
    new_content = new_content.replace('AppTheme.errorColor', 'AppTheme.errorColor')
    new_content = new_content.replace('REPUTATION_START', 'TRUST_SCORE_START')
    new_content = new_content.replace('REPUTATION_MAX', 'TRUST_SCORE_MAX')
    
    if content != new_content:
        with open(file_path, 'w') as f:
            f.write(new_content)
        print(f"Updated {file_path}")

for root, dirs, files in os.walk(dir_path):
    for f in files:
        # Don't touch generated directory as it will be regenerated or might have issues
        if "generated" in root: continue
        process_file(os.path.join(root, f))
print("Done")
