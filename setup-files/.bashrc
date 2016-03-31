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
export EDITOR="/usr/bin/EDITOR_TEMP"

# Optimize compile time
NB_CORES=$(grep -c '^processor' /proc/cpuinfo)
export MAKEFLAGS="-j$((NB_CORES+1)) -l${NB_CORES}"

# Test whether we're in a screen session and runs screen -RR if you aren't. 
# '-RR' will reattach to the first available session or create one if necessary.

if [[ -z "$STY" ]]; then screen -RR; fi

##### END DEBIAN PACKAGING SETUP #####
