{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, typing-extensions
}:

buildPythonPackage rec {
  pname = "mangum";
  version = "0.17.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-W04mN14S7tBRaHZwRm0Xlo+LdL7srKQy7dTrQSf3hQk=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    typing-extensions
  ];

  pythonImportsCheck = [ "mangum" ];

  meta = with lib; {
    description = "Serverless ASGI adapter for AWS Lambda & API Gateway";
    homepage = "https://mangum.io/";
    license = licenses.mit;
    maintainers = [ ];
  };
}