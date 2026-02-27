#!/usr/bin/env python3
import subprocess
import sys
import os

os.chdir('c:\\git\\jobs_modernization')

# Reset the repo state first
subprocess.run(['git', 'reset', '--hard', 'HEAD'], check=True)

# Use BFG Repo-Cleaner approach with git-filter-repo
# Create a replacement file for secrets
with open('.bfg-secrets-replace.txt', 'w') as f:
    f.write('6-CtFhZr1y6nm8Q&C#to==>***REDACTED-PASSWORD***\n')
    f.write('4lbeGK1H?&Xia12H%WGI==>***REDACTED-PASSWORD***\n')

# Run git-filter-repo with the replacement file  
result = subprocess.run([
    'python', '-m', 'git_filter_repo',
    '--replace-text', '.bfg-secrets-replace.txt',
    '--force'
], capture_output=True, text=True)

print(result.stdout)
print(result.stderr)

# Clean up
if os.path.exists('.bfg-secrets-replace.txt'):
    os.remove('.bfg-secrets-replace.txt')

sys.exit(result.returncode)
