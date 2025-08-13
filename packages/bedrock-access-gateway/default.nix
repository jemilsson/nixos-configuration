{ lib
, python3
, fetchFromGitHub
, makeWrapper
}:

python3.pkgs.buildPythonApplication rec {
  pname = "bedrock-access-gateway";
  version = "1.0.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "aws-samples";
    repo = "bedrock-access-gateway";
    rev = "76a3614f1768e6f0ce161bdd7940dfcb6b16e9b0";
    hash = "sha256-L30l2pvNPDfuFLG/6rpJv7J0hi+yNuN+yUAwHJ+3zxg=";
  };

  nativeBuildInputs = [ makeWrapper ];
  
  propagatedBuildInputs = with python3.pkgs; [
    fastapi
    pydantic
    uvicorn
    boto3
    botocore
    tiktoken
    requests
    numpy
  ];

  # Note: mangum is included in service PYTHONPATH for Lambda compatibility

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib/bedrock-access-gateway
    cp -r src/* $out/lib/bedrock-access-gateway/
    
    mkdir -p $out/bin
    makeWrapper ${python3}/bin/python $out/bin/bedrock-access-gateway \
      --add-flags "-m uvicorn api.app:app --workers \''${UVICORN_WORKERS:-1}" \
      --chdir $out/lib/bedrock-access-gateway \
      --prefix PYTHONPATH : $out/lib/bedrock-access-gateway:${python3.pkgs.makePythonPath propagatedBuildInputs}
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Bedrock Access Gateway - provides OpenAI-compatible RESTful APIs for Amazon Bedrock";
    homepage = "https://github.com/aws-samples/bedrock-access-gateway";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}