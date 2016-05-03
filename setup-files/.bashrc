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

##################################################################
# Outside connection behvaior (e.g. SSH from an Android device)
##################################################################

# Only do this when connecting via SSH outside our network
# SSH_CONNECTION shows the address of the client, the outgoing port on the client, the 
# address of the server and the incoming port on the server.

# We want to check $SSH_CLIENT instead, since that only *client/origin*  ip info
# Don't launch this behavior if using SSH internally.
# This -assumes- your internal network starts with a traditional 192 address!

# Is our SSH connection on the local network or external?
if [[ "$(echo "${SSH_CLIENT}" | grep 192)" == "" ]]; then

  # If screen is not running, create it and notify the user.
  if [[ -z "$STY" ]]; then 
    screen -D -R; 
  fi
  
fi

##### END DEBIAN PACKAGING SETUP #####
