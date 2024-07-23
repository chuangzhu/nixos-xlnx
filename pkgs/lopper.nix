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
  version = "0-unstable-2024-07-19";

  src = fetchFromGitHub {
    owner = "devicetree-org";
    repo = "lopper";
    rev = "fcfad5150f98691e2a867c76d3f60f3631a3fd59";
    hash = "sha256-3Jt47POX5avx1OzUhkniov3BLcrmQ+ivK/fORzcOT04=";
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
