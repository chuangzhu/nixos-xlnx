{ lib
, buildPythonPackage
, fetchFromGitHub
, humanfriendly
, configparser
, libfdt
, ruamel-yaml
, pyyaml
, anytree
, packaging
}:

buildPythonPackage rec {
  pname = "lopper";
  version = "0-unstable-2024-07-19";

  src = fetchFromGitHub {
    owner = "devicetree-org";
    repo = "lopper";
    rev = "b4dd529fa00a85a432bdb2e2e5eb56d38b04477e";
    hash = "sha256-KYrp7YOTVP0zM97cvs0LxRs6QF/FHfAlqlKIkzi7mpI=";
  };

  postPatch = ''
    substituteInPlace lopper/assists/zuplus_xppu_default.py --replace-fail elif: else:
    substituteInPlace lopper/fdt.py --replace-fail '"-I", "dts"' '"-@", "-I", "dts"'
  '';

  propagatedBuildInputs = [
    humanfriendly
    configparser
    libfdt
    ruamel-yaml
    pyyaml
    anytree
    packaging
  ];

  pythonImportsCheck = [ "lopper" ];

  doCheck = false;

  meta = with lib; {
    description = "System device tree (S-DT) processor";
    homepage = "https://static.linaro.org/connect/lvc20/presentations/LVC20-314-0.pdf";
    license = licenses.bsd3;
    maintainer = with maintainers; [ chuangzhu ];
  };
}
