{ stdenv, fetchurl, python, wrapPython, distutils-cfg }:

stdenv.mkDerivation rec {
  shortName = "setuptools-${version}";
  name = "${python.executable}-${shortName}";

  version = "5.8";

  src = fetchurl {
    url = "http://pypi.python.org/packages/source/s/setuptools/${shortName}.tar.gz";
    sha256 = "15h643gf821b72d0s59cjj60c6dm5l57rggv5za9d05mccp3psff";
  };

  buildInputs = [ python wrapPython distutils-cfg ];

  buildPhase = "${python}/bin/${python.executable} setup.py build";

  installPhase =
    ''
      dst=$out/lib/${python.libPrefix}/site-packages
      mkdir -p $dst
      windst=$(cygpath -a -w $dst)
      export PYTHONPATH="$windst;$PYTHONPATH"
      ${python}/bin/${python.executable} setup.py install --prefix=$(cygpath -a -w $out) --install-lib=$windst
      wrapPythonPrograms
    '';

  doCheck = false;  # requires pytest

  checkPhase = ''
    ${python}/bin/${python.executable} setup.py test
  '';

  meta = with stdenv.lib; {
    description = "Utilities to facilitate the installation of Python packages";
    homepage = http://pypi.python.org/pypi/setuptools;
    license = [ "PSF" "ZPL" ];
    platforms = platforms.all;
  };    
}
