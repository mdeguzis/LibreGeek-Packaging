#!/usr/bin/python
# convert json to yaml
# http://pyyaml.org/wiki/PyYAMLDocumentation

import argparse
import collections
from collections import OrderedDict
import json
import yaml
import sys

json_file = 'test.json'
with open(json_file, 'r') as f:
	json_data = json.load(f)

#json_data = collections.OrderedDict(sorted(json_data.items()))
yaml_content = yaml.dump(json_data, default_flow_style=False)
print(yaml_content)
