# On cygwin, libraries need to have unique predefined addresses for
# fork to work reliably.
postFixupHooks+=(_cygwinRebaseLibraries)

_cygwinRebaseLibraries() {
    if [ $(uname -m) = "x86_64" ]; then
        find $out -regextype posix-egrep -regex '*.\.(so|dll)' -print0 | xargs -0 /bin/rebase -s --64
    else
        find $out -regextype posix-egrep -regex '*.\.(so|dll)' -print0 | xargs -0 /bin/rebase -s --32
    fi
}
