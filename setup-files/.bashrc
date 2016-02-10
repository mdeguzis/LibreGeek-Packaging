##### DEBIAN PACKAGING SETUP #####

# Debian identification
DEBEMAIL="${email}"
DEBFULLNAME="$first_name $last_name"
export DEBEMAIL DEBFULLNAME

# Quilt
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
complete -F _quilt_completion $_quilt_complete_opt dquilt
