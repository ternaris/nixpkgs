postFixupHooks+=(_cygwinFixAutoImageBase)

_cygwinFixAutoImageBase() {
    find $out -name "*.dll" | while read DLL; do
        if [ -f /etc/rebasenix.nextbase ]; then
            NEXTBASE="$(</etc/rebasenix.nextbase)"
        fi
        NEXTBASE=${NEXTBASE:-0x62000000}

        REBASE=(`/bin/rebase -i $DLL`)
        BASE=${REBASE[2]}
        SIZE=${REBASE[4]}

        echo "REBASE FIX: $DLL $BASE -> $NEXTBASE"
        /bin/rebase -b $NEXTBASE $DLL
        NEXTBASE="0x`printf %x $(($NEXTBASE+$SIZE))`"

        echo $NEXTBASE > /etc/rebasenix.nextbase
    done
}
