##### DEBIAN PACKAGING SETUP #####

# Debian identification
DEBEMAIL="EMAIL_TEMP"
DEBFULLNAME="FULLNAME_TEMP"
export DEBEMAIL DEBFULLNAME

# Quilt
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
complete -F _quilt_completion $_quilt_complete_opt dquilt

REMOTE_USER="REMOTE_USER_TEMP"
REMOTE_HOST="REMOTE_HOST_TEMP"

##### END DEBIAN PACKAGING SETUP #####
