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
  version = "unstable-2024-02-27";

  src = fetchFromGitHub {
    owner = "devicetree-org";
    repo = "lopper";
    rev = "bcd57e90e39d6df468cd7b0b756ca28cd24be4c1";
    hash = "sha256-zBUyLcwYWJTWwmUIYjppSz47CMY4uSaKjUnA7gwJbK8=";
  };

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
