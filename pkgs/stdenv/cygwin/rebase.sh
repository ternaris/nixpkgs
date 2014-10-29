postFixupHooks+=(_cygwinFixAutoImageBase)

_cygwinFixAutoImageBase() {
    if [ $(uname -m) != "x86_64" ]; then
        find $out -name "*.dll" | while read DLL; do
            REBASE=(`/bin/rebase -i $DLL`)
            BASE=${REBASE[2]}

            if [ $(($BASE)) -gt $((0x70000000)) ]; then
                NEWBASE="0x`printf %x $(($BASE-0x20000000))`"
                echo "REBASE FIX: $DLL $BASE -> $NEWBASE"
                /bin/rebase -b $NEWBASE $DLL
            fi
        done
    fi
}
