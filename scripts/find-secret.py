import json
import sys
jsonfile = sys.argv[1]

with open(jsonfile,'r') as f:
    s1 = json.load(f)
    s2 = s1["SecretString"]
    s3 = eval(s2)
    print(s3["password"])