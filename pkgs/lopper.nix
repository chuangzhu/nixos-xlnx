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

buildPythonPackage {
  pname = "lopper";
  version = "0-unstable-2025-08-22";

  src = fetchFromGitHub {
    owner = "devicetree-org";
    repo = "lopper";
    rev = "f93c309fd206525216d7a57eee010d698391efcf";
    hash = "sha256-lbO2db35vjlLKnhmiDO1ydK0+eBu9gbmiR9Be5EC3Eo=";
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
