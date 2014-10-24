# On cygwin, there is no rpath, we wrap executables to find libararies
# in their build-time path
postFixupHooks+=(_cygwinWrapToFindDlls)

cygwinWrapExe() {
    local exe="$1"
    local hidden="$(dirname "$exe")/.$(basename "$exe" .exe)"-wrapped.exe
    local wrapper="$(dirname "$exe")/$(basename $exe .exe)"
    mv $exe $hidden
    makeWrapper $hidden $wrapper --prefix PATH : ${PATH}
}

_cygwinWrapToFindDlls() {
    if test -d $out/bin; then
        for x in $(find $out/bin -regextype posix-extended -regex '.*\.exe$'); do
            cygwinWrapExe $x
        done
    fi
}
