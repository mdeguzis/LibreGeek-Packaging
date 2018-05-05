#!/usr/bin/python2
import argparse
import sys
import yaml
import json

json_file = 'test.json'
with open(json_file, 'r') as f:
	json_data = json.load(f)

yaml_content = yaml.safe_dump(json_data, default_flow_style=False)
print yaml_content
