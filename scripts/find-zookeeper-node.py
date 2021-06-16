import json
import sys
jsonfile = sys.argv[1]
instancefile = sys.argv[2]

with open(jsonfile,'r') as f:
    s1 = json.load(f)
    with open(instancefile, 'w') as f:
        for item in s1["Tags"][0:]:
            f.write(item["Value"]+"\n")