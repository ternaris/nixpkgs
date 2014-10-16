{ stdenv, fetchurl, zlib ? null, zlibSupport ? true, bzip2
, sqlite, tcl, tk, x11, openssl, readline, db, ncurses, gdbm, libX11 }:

assert zlibSupport -> zlib != null;

with stdenv.lib;

let

  majorVersion = "2.7";
  version = "${majorVersion}.8";

  src = fetchurl {
    url = "http://www.python.org/ftp/python/${version}/Python-${version}.tar.xz";
    sha256 = "0nh7d3dp75f1aj0pamn4hla8s0l7nbaq4a38brry453xrfh11ppd";
  };

  patches =
    [ # Look in C_INCLUDE_PATH and LIBRARY_PATH for stuff.
      ./search-path.patch

      # Python recompiles a Python if the mtime stored *in* the
      # pyc/pyo file differs from the mtime of the source file.  This
      # doesn't work in Nix because Nix changes the mtime of files in
      # the Nix store to 1.  So treat that as a special case.
      ./nix-store-mtime.patch

      # patch python to put zero timestamp into pyc
      # if DETERMINISTIC_BUILD env var is set
      ./deterministic-build.patch

        ./0010-ctypes-util-find_library.patch
        ./0020-tkinter-x11.patch
        ./0030-ssl-threads.patch
        ./0040-FD_SETSIZE.patch
        ./0050-export-PySignal_SetWakeupFd.patch
        ./0060-ncurses-abi6.patch
        ./0070-dbm.patch
        ./0080-dylib.patch
        ./0090-getpath-exe-extension.patch
        ./0100-no-libm.patch
        ./0110-export-PyNode_SizeOf.patch
        ./0120-fix-sqlite-module.patch
        ./0210-reorder-bininstall-ln-symlink-creation.patch
        ./0250-allow-win-drives-in-os-path-isabs.patch
        ./2.7.5-allow-windows-paths-for-executable.patch
    ];

  postPatch = stdenv.lib.optionalString (stdenv.gcc.libc != null) ''
    substituteInPlace ./Lib/plat-generic/regen \
                      --replace /usr/include/netinet/in.h \
                                ${stdenv.gcc.libc}/include/netinet/in.h
  '';

  buildInputs =
    optional (stdenv ? gcc && stdenv.gcc.libc != null) stdenv.gcc.libc ++
    [ bzip2 openssl ]
    ++ [ db ncurses gdbm sqlite readline ]
    ++ optional zlibSupport zlib;

  ensurePurity =
    ''
      sed -i ./setup.py -e 's,/(usr|sw|opt|pkg),/no-such-path,'
    '';

  # Build the basic Python interpreter without modules that have
  # external dependencies.
  python = stdenv.mkDerivation {
    name = "python-${version}";

    inherit majorVersion version src patches postPatch buildInputs;

    LDFLAGS = stdenv.lib.optionalString (!stdenv.isDarwin) "-lgcc_s";
    C_INCLUDE_PATH = concatStringsSep ":" (map (p: "${p}/include") buildInputs);
    LIBRARY_PATH = concatStringsSep ":" (map (p: "${p}/lib") buildInputs);

    configureFlags = "--enable-shared --with-threads --enable-unicode";

    preConfigure = "${ensurePurity}";
 # + optionalString stdenv.isCygwin
 #      ''
 #        # On Cygwin, `make install' tries to read this Makefile.
 #        mkdir -p $out/lib/python${majorVersion}/config
 #        touch $out/lib/python${majorVersion}/config/Makefile
 #        mkdir -p $out/include/python${majorVersion}
 #        touch $out/include/python${majorVersion}/pyconfig.h
 #      '';

    postConfigure = ''
      sed -i Makefile -e 's,PYTHONPATH="$(srcdir),PYTHONPATH="$(abs_srcdir),'
    '';

    NIX_CFLAGS_COMPILE = optionalString stdenv.isDarwin "-msse2";

    setupHook = ./setup-hook.sh;

    postInstall =
      ''
        rm -rf "$out/lib/python${majorVersion}/test"
        ln -s ../lib/python${majorVersion}/pdb.py $out/bin/pdb
        ln -s ../lib/python${majorVersion}/pdb.py $out/bin/pdb${majorVersion}
        ln -s python2.7.1.gz $out/share/man/man1/python.1.gz
      '';

    passthru = rec {
      inherit zlibSupport;
      isPy2 = true;
      isPy27 = true;
      libPrefix = "python${majorVersion}";
      executable = libPrefix;
      sitePackages = "lib/${libPrefix}/site-packages";
    };

    enableParallelBuilding = true;

    meta = {
      homepage = "http://python.org";
      description = "a high-level dynamically-typed programming language";
      longDescription = ''
        Python is a remarkably powerful dynamic programming language that
        is used in a wide variety of application domains. Some of its key
        distinguishing features include: clear, readable syntax; strong
        introspection capabilities; intuitive object orientation; natural
        expression of procedural code; full modularity, supporting
        hierarchical packages; exception-based error handling; and very
        high level dynamic data types.
      '';
      license = stdenv.lib.licenses.psfl;
      platforms = stdenv.lib.platforms.all;
      maintainers = with stdenv.lib.maintainers; [ simons chaoflow ];
    };
  };


  # The Python modules included in the main Python distribution, built
  # as separate derivations.
  modules = {

    bsddb = null;
    curses = null;
    curses_panel = null;
    crypt = null;
    gdbm = null;
    sqlite3 = null;

    # tkinter = null;
    #   moduleName = "tkinter";
    #   deps = [ tcl tk x11 libX11 ];
    # };

    readline = null;

  };

in python // { inherit modules; }
