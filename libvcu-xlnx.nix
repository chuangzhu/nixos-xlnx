{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "libvcu-xlnx";
  version = "2022.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "vcu-ctrl-sw";
    rev = "xilinx_v${version}";
    hash = "sha256-TIN0zkXeUL9Bh12v4ZUwFfbitpH2bjUYXd82uhPnOds=";
  };

  installTargets = [ "install_headers" ];
  installFlags = [ "PREFIX=$(out)" ];

  postInstall = ''
    install -Dm755 bin/ctrlsw_{en,de}coder -t $out/bin/
    install -Dm755 bin/liballegro_{en,de}code.so -t $out/lib/
    for f in $out/lib/*.so; do ln -s "$f" "$f".0; done
  '';

  meta = with lib; {
    description = "Xilinx Zynq UltraScale+ VCU control software";
    homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842546/Xilinx+Zynq+UltraScale+MPSoC+Video+Codec+Unit";
    license = licenses.unfree; # Based on X11 license, but with two extra terms
    platforms = platforms.linux;
    maintainers = with maintainers; [ chuangzhu ];
  };
}
