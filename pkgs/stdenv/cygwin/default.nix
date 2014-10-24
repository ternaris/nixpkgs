# stdenv is stdenvNative
# pkgs are pkgs build by using stdenvNative
{ stdenv, pkgs, config, lib }:

import ../generic rec {
  inherit config;

  extraBuildInputs = [
    ./rebase-libraries.sh
    ./wrap-to-find-dlls.sh
    pkgs.makeWrapper
  ];

  preHook =
    ''
      # Disable purity tests; it's allowed (even needed) to link to
      # libraries outside the Nix store (like the C library).
      export NIX_ENFORCE_PURITY=

      # only relevant in case we set NIX_ENFORCE_PURITY=1
      export NIX_IGNORE_LD_THROUGH_GCC=

      # These are concerned with finding .so files and generating
      # -rpath flags. If we need/want something similar for cygwin, we
      # need to adapt/write our own.
      #
      # However, libtool seems to use them to look for files: unset
      # for now.  XXX: Should be investigated
      export NIX_DONT_SET_RPATH=
      export NIX_NO_SELF_RPATH=

      # prevent libtool from failing to find dynamic libraries
      export lt_cv_deplibs_check_method=pass_all
    '';
    #   if test -z "$cygwinConfigureNoDisableShared"; then
    #     export configureFlags="$configureFlags --disable-shared"
    #   fi
    # '';
 # XXX: things set for darwin in stdenvNix
 #
 # + lib.optionalString stdenv.isDarwin ''
 #      dontFixLibtool=1
 #      stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
 #      xargsFlags=" "
 #      export MACOSX_DEPLOYMENT_TARGET=10.6
 #      export SDKROOT=$(/usr/bin/xcrun --show-sdk-path 2> /dev/null || true)
 #      export NIX_CFLAGS_COMPILE+=" --sysroot=/var/empty -idirafter $SDKROOT/usr/include -F$SDKROOT/System/Library/Frameworks -Wno-multichar -Wno-deprecated-declarations"
 #      export NIX_LDFLAGS_AFTER+=" -L$SDKROOT/usr/lib"
 #    '';

  initialPath = ((import ../common-path.nix) { inherit pkgs; }) ++ [ pkgs.sysBinutils (stdenv.mkDerivation {
    name = "cygwin-and-windows-dlls";
    unpackPhase = "true";

    # XXX: dll lists are currently arbitrary
    # remove dlls from the store path and readd until it fits
    # then update lists accordingly.
    # XXX: windows DLLS may not be copied! instead add them to the PATH
    installPhase = ''
      mkdir -p $out/bin

      for x in $(cat ${if system == "i686-cygwin" then ./dll-list-i686-cygwin else ./dll-list-x86_64-cygwin}); do
        cp -v $x $out/bin
      done
    '';
  }) "/cygdrive/c/Windows/SYSTEM32/" ];

  system = stdenv.system;

  gcc = stdenv.gcc;

  shell = pkgs.bash + "/bin/sh";

  fetchurlBoot = stdenv.fetchurlBoot;

  # XXX: figure out how this is used
  overrides = pkgs_: {
    inherit gcc;
    inherit (gcc) binutils;
    inherit (pkgs)
      gzip bzip2 xz bash coreutils diffutils findutils gawk
      gnumake gnused gnutar gnugrep gnupatch perl;
  };
}
