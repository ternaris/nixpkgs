{stdenv, fetchurl, xmlto, docbook_xml_dtd_412, libxslt, docbook_xsl, automake, gettext, libiconvOrNull, libtool}:

stdenv.mkDerivation {
  name = "opensp-1.5.2";

  src = fetchurl {
    url = mirror://sourceforge/openjade/OpenSP-1.5.2.tar.gz;
    sha256 = "1khpasr6l0a8nfz6kcf3s81vgdab8fm2dj291n5r2s53k228kx2p";
  };

  patchPhase = ''
    sed -i s,/usr/share/sgml/docbook/xml-dtd-4.1.2/,${docbook_xml_dtd_412}/xml/dtd/docbook/, \
      docsrc/*.xml
  '';

  setupHook = ./setup-hook.sh;

  postFixup = ''
    # Remove random ids in the release notes
    sed -i -e 's/href="#idm.*"//g' $out/share/doc/OpenSP/releasenotes.html
    sed -i -e 's/name="idm.*"//g' $out/share/doc/OpenSP/releasenotes.html
    '';

  preConfigure = "autoreconf -fi";

  # need automake, gettext, and libtool for reconfigure
  buildInputs = [ automake gettext libiconvOrNull libtool xmlto docbook_xml_dtd_412 libxslt docbook_xsl ];

  meta = {
    description = "A suite of SGML/XML processing tools";
    license = stdenv.lib.licenses.mit;
    homepage = http://openjade.sourceforge.net/;
  };
}
