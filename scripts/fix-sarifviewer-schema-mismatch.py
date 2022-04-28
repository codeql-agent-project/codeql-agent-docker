# This script is a temporary workaround for the issue CodeQL CLI and Sarif Viewer mismatch. The script will be removed after the issue is resolved.
# Addresses Sarif Viewer issue #427 (https://github.com/microsoft/sarif-vscode-extension/issues/427)

import sys
import json

sarif_file_path = sys.argv[1]

with open(sarif_file_path, 'r') as openfile:
    data = json.load(openfile)

del data["$schema"]

with open(sarif_file_path, "w") as outfile:
    json.dump(data, outfile)