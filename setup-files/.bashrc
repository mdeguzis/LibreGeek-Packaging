##### DEBIAN PACKAGING SETUP #####

# Debian identification
DEBEMAIL="mdeguzis@gmail.com"
DEBFULLNAME="ProfessorKaos64"
export DEBEMAIL DEBFULLNAME

# Quilt
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
complete -F _quilt_completion $_quilt_complete_opt dquilt
