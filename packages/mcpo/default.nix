{ lib
, buildPythonPackage
, fetchPypi
, hatchling
, fastapi
, uvicorn
, pydantic
, httpx
, click
, mcp
, passlib
, pyjwt
, python-dotenv
, typer
}:

buildPythonPackage rec {
  pname = "mcpo";
  version = "0.0.12"; # TODO: Upgrade back to latest when https://github.com/open-webui/mcpo/issues/117 is fixed
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-qGUZK5bKG0SaaUS6hbpHxknxd/cT8CZuMofIDj6FM+U=";
  };

  build-system = [
    hatchling
  ];

  dependencies = [
    fastapi
    uvicorn
    pydantic
    httpx
    click
    mcp
    passlib
    pyjwt
    python-dotenv
    typer
  ];

  # Re-enable checks and import validation
  doCheck = true;
  pythonImportsCheck = [ "mcpo" ];

  nativeBuildInputs = [ hatchling ];
  dontUsePythonRuntimeDepsCheck = true;

  meta = with lib; {
    description = "MCP to OpenAPI Proxy - Transform MCP server commands into OpenAPI-compatible HTTP servers";
    homepage = "https://github.com/open-webui/mcpo";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}