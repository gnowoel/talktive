import os

def replace_in_files(directory, old, new):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart") or file.endswith(".yaml"):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if old in content:
                    content = content.replace(old, new)
                    print(f"Replaced {old} -> {new} in {filepath}")
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)

replace_in_files('/Users/leo/Develop/builds/talktive/production/talktive3/talktive_server/lib', 'computeReputation', 'computeEffectiveFloor')
replace_in_files('/Users/leo/Develop/builds/talktive/production/talktive3/talktive_server/lib', 'restoreReputation', 'restoreTrustScore')
replace_in_files('/Users/leo/Develop/builds/talktive/production/talktive3/talktive_server/test', 'computeReputation', 'computeEffectiveFloor')
replace_in_files('/Users/leo/Develop/builds/talktive/production/talktive3/talktive_server/test', 'restoreReputation', 'restoreTrustScore')
