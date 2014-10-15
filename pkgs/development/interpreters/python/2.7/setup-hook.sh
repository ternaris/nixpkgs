addPythonPath() {
    export PYTHONPATH="$PYTHONPATH${PYTHONPATH:+;}$(cygpath -a -w $1/lib/python2.7/site-packages)"
    #addToSearchPathWithCustomDelimiter ';' PYTHONPATH "$(cygpath -a -w $1/lib/python2.7/site-packages)"
}

toPythonPath() {
    local paths="$1"
    local result=
    for i in $paths; do
        p="$i/lib/python2.7/site-packages"
        result="${result}${result:+:}$p"
    done
    echo $result
}

envHooks=(${envHooks[@]} addPythonPath)
