{ system, allPackages ? import ../../.., config }:

rec {

  shell =
    if system == "i686-freebsd" || system == "x86_64-freebsd" then "/usr/local/bin/bash"
    else "/bin/bash";

  path =
    (if system == "i686-solaris" then [ "/usr/gnu" ] else []) ++
    (if system == "i686-netbsd" then [ "/usr/pkg" ] else []) ++
    (if system == "x86_64-solaris" then [ "/opt/local/gnu" ] else []) ++
    ["/" "/usr" "/usr/local"];


  # XXX: correctly camelcase this


  preHookBase = ''
    # Disable purity tests; it's allowed (even needed) to link to
    # libraries outside the Nix store (like the C library).
    export NIX_ENFORCE_PURITY=
  '';

  preHookDarwin = ''
    ${preHookBase}
    export NIX_DONT_SET_RPATH=1
    export NIX_NO_SELF_RPATH=1
    dontFixLibtool=1
    stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
    xargsFlags=" "
  '';

  preHookFreeBSD = ''
    ${preHookBase}

    alias make=gmake
    alias tar=gtar
    alias sed=gsed
    export MAKE=gmake
    shopt -s expand_aliases

    # Filter out stupid GCC warnings (in gcc-wrapper).
    export NIX_GCC_NEEDS_GREP=1
  '';

  preHookOpenBSD = ''
    ${preHookBase}

    alias make=gmake
    alias grep=ggrep
    alias mv=gmv
    alias ln=gln
    alias sed=gsed
    alias tar=gtar

    export MAKE=gmake
    shopt -s expand_aliases

    # Filter out stupid GCC warnings (in gcc-wrapper).
    export NIX_GCC_NEEDS_GREP=1
  '';

  preHookNetBSD = ''
    ${preHookBase}

    alias make=gmake
    alias sed=gsed
    alias tar=gtar
    export MAKE=gmake
    shopt -s expand_aliases

    # Filter out stupid GCC warnings (in gcc-wrapper).
    export NIX_GCC_NEEDS_GREP=1
  '';

  # Only used to build stdenvCygwin, check cygwin/default.nix.
  preHookCygwin = ''
    ${preHookBase}

    # prevent libtool from failing to find dynamic libraries
    export lt_cv_deplibs_check_method=pass_all

    # if test -z "$cygwinConfigureNoDisableShared"; then
    #   export configureFlags="$configureFlags --disable-shared"
    # fi
  '';

  extraBuildInputsCygwin = [ ../cygwin/rebase-libraries.sh ];

  # A function that builds a "native" stdenv (one that uses tools in
  # /usr etc.).
  makeStdenv =
    { gcc, fetchurl, extraPath ? [], overrides ? (pkgs: { }) }:

    import ../generic {
      preHook =
        if system == "x86_64-darwin" then preHookDarwin else
        if system == "i686-freebsd" then preHookFreeBSD else
        if system == "x86_64-freebsd" then preHookFreeBSD else
        if system == "i686-openbsd" then preHookOpenBSD else
        if system == "i686-netbsd" then preHookNetBSD else
        if system == "i686-cygwin" then preHookCygwin else
        if system == "x86_64-cygwin" then preHookCygwin else
        preHookBase;

      extraBuildInputs =
        if system == "i686-cygwin" then extraBuildInputsCygwin else
        if system == "x86_64-cygwin" then extraBuildInputsCygwin else
        [];

      initialPath = extraPath ++ path;

      fetchurlBoot = fetchurl;

      inherit system shell gcc overrides config;
    };


  stdenvBoot0 = makeStdenv {
    gcc = "/no-such-path";
    fetchurl = null;
  };


  gcc = import ../../build-support/gcc-wrapper {
    name = "gcc-native";
    nativeTools = true;
    nativeLibc = true;
    nativePrefix = if system == "i686-solaris" then "/usr/gnu" else if system == "x86_64-solaris" then "/opt/local/gcc47" else "/usr";
    stdenv = stdenvBoot0;
  };


  fetchurl = import ../../build-support/fetchurl {
    stdenv = stdenvBoot0;
    # Curl should be in /usr/bin or so.
    curl = null;
  };


  # First build a stdenv based only on tools outside the store.
  stdenvBoot1 = makeStdenv {
    inherit gcc fetchurl;
  } // {inherit fetchurl;};

  stdenvBoot1Pkgs = allPackages {
    inherit system;
    bootStdenv = stdenvBoot1;
  };


  # Using that, build a stdenv that adds the ‘xz’ command (which most
  # systems don't have, so we mustn't rely on the native environment
  # providing it).
  stdenvBoot2 = makeStdenv {
    inherit gcc fetchurl;
    extraPath = [ stdenvBoot1Pkgs.xz ];
    overrides = pkgs: { inherit (stdenvBoot1Pkgs) xz; };
  };


  stdenv = stdenvBoot2;
}
