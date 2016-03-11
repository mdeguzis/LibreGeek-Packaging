# replacing block of text for user host params, since digital ocean droplet is up and running
# delete this file when confirmed working

# Remove old vars to make this easy
find . -name "build*.sh" -print0 | xargs -0 sed -i '/USER\=\"mikeyd\"/d'
find . -name "build*.sh" -print0 | xargs -0 sed -i '/HOST\=\"archboxmtd\"/d'

# Keep << vs <<- (latter ignores tabs), since we want to keep the code indented
# The caveat then, is the here-doc needs to not be indented.
# If you use 'cat <<- EOF > test.txt' with indents, your code will not contain tabs
cat << EOF > newtext.txt

# Check if USER/HOST is setup under ~/.bashrc, set to default if blank
# This keeps the IP of the remote VPS out of the build script

if [[ "\${REMOTE_USER}" == "" || "\${REMOTE_HOST}" == "" ]]; then

	# fallback to local repo pool target(s)
	USER="mikeyd"
	HOST="archboxmtd"

fi

EOF

# Add new block of cheese, errrrr....text...
find . -name "build*.sh" -print0 | xargs -0 perl -pe 's/.*repo destination.*/`cat newtext.txt`/e' -i

# Replace final text in build script
find . -name "build*.sh" -print0 | xargs -0 sed -i 's/${USER}@${HOST}/${REMOTE_USER}@${REMOTE_HOST}/g'
