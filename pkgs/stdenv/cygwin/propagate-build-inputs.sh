# On cygwin, automatic runtime dependency detection does not work
# because the binaries do not contain absolute references to store
# locations (yet)
postFixupHooks+=(_cygwinPropagateBuildInputs)

_cygwinPropagateBuildInputs() {
    if [ -n "$buildInputs" ]; then
        mkdir -p "$out/nix-support"
        echo "$buildInputs" >> "$out/nix-support/propagated-build-inputs"
    fi

    if [ -n "$nativeBuildInputs" ]; then
        mkdir -p "$out/nix-support"
        echo "$nativeBuildInputs" >> "$out/nix-support/propagated-native-build-inputs"
    fi
}
