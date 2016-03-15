##### DEBIAN PACKAGING SETUP #####

# Debian identification
DEBEMAIL="EMAIL_TEMP"
DEBFULLNAME="FULLNAME_TEMP"
export DEBEMAIL DEBFULLNAME

# Quilt
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
complete -F _quilt_completion $_quilt_complete_opt dquilt

export REMOTE_USER="REMOTE_USER_TEMP"
export REMOTE_HOST="REMOTE_HOST_TEMP"
export REMOTE_PORT="REMOTE_PORT_TEMP"

# For use cases outside of using the env var $EDITOR
EDITOR="/usr/bin/EDITOR_TEMP"

##### END DEBIAN PACKAGING SETUP #####
