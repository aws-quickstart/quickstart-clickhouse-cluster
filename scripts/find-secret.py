import json
import sys
jsonfile = sys.argv[1]
resultfile = sys.argv[2]

with open(jsonfile,'r') as f:
    s1 = json.load(f)
    with open(resultfile, 'w') as f:
       f.write(s1["SecretString"])
with open(resultfile,'r') as f:
    s1 = json.load(f)
    print(s1["password"])