#!/usr/bin/python
########
# Description:	Check repositories under a given path for uncommited/local files
########

import argparse
import glob
import os
import subprocess
import sys
import time

#
# Arguments
#

aparser = argparse.ArgumentParser(description="Scan absolute path for uncommitted/local git work")
aparser.add_argument('-p', '--path', action='store', required=True, help="Absolute path to scan")
aparser.add_argument('-s', '--skip', action='store', nargs='*', help="Skip keywords (such as buildoug)")
args = aparser.parse_args()

#
# Vars
#

action_count = 0
action_list = []
status_actions = {}
sub_divider = str('\n' + '-' * 55 + "\n")
keywords = args.skip

#
# Main
#

if not args.path:
	sys.exit("You must provide an absolute path to scan.")
else:
	target_path = args.path

print "Scanning: " + target_path

for dname, subdir_list, file_list in os.walk(os.path.abspath(target_path)):
	if args.skip:
		for keyword in keywords:
			if keyword not in dname and dname.endswith(".git"):
				# Format all the things
				actions = []
				output = []
				parentdir = dname.replace('.git','')
				gitdir = os.path.splitext(parentdir)[0]
				gitdir_basename = os.path.basename(os.path.abspath(parentdir))
				print sub_divider + "Checking repository: '" + gitdir_basename + "'" + sub_divider
				os.chdir(parentdir)
				print "Absolute path: " + parentdir
				print "Git status: \n"
				gitstatus = subprocess.Popen(['git', 'status'], stdout=subprocess.PIPE)

				# Loop the subprocess output
				for line in gitstatus.stdout.readlines():
					formatted_line = line.replace('\r', '').replace('\n', '')
					print formatted_line
					output.append(formatted_line)

				# Check for anything that does not denote a clean working tree
				if "working directory clean" not in str(output):
					actions.append("\n\tWorking directory unclean")
					status_actions[parentdir]= parentdir + ": " + ' '.join(actions)

				# Check for staging branch use
				if "master" not in str(output):
					actions.append("\n\tNon-master branch in use, or detached state")
					status_actions[parentdir]= parentdir + ' '.join(actions)
					
print sub_divider + "Repositories that require attention" + sub_divider
print "Total: " + str(action_count) + "\n"

for key, value in status_actions.iteritems():
	print value
