postFixupHooks+=(_cygwinWrapExesToFindDlls)

_cygwinWrapExesToFindDlls() {
    find $out -name "*.exe" | while read EXE; do
        mv "${EXE}" "${EXE}.tmp"

        DLLPATH=
        for x in $buildInputs $nativeBuildInputs; do
            if [ -d "${x}/bin" ]; then
                DLLPATH="${DLLPATH}:${DLLPATH:+:}${x}/bin"
            fi
        done

        WRAPPER="${EXE%.exe}"
        cat >"${WRAPPER}" <<EOF
#!/bin/sh
export PATH=$DLLPATH${DLLPATH:+:}\${PATH}
exec "\$0.exe" "\$@"
EOF
        chmod +x "${WRAPPER}"
        mv "${EXE}.tmp" "${EXE}"
    done
}
