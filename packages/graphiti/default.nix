{ pkgs, lib, fetchFromGitHub, python3 }:

python3.pkgs.buildPythonApplication rec {
  pname = "graphiti-mcp";
  version = "0.17.11";
  format = "other";

  src = fetchFromGitHub {
    owner = "getzep";
    repo = "graphiti";
    rev = "v${version}";
    hash = "sha256-qI5HVPJ8ZpU++b0/qkaOwB8ifECQwpKcgOsFvirkyTU=";
  };

  nativeBuildInputs = with pkgs; [
    uv
  ];

  propagatedBuildInputs = with python3.pkgs; [
    neo4j
    openai
    pydantic
    fastapi
    uvicorn
    httpx
    click
    rich
    python-dotenv
    typing-extensions
    diskcache
    tenacity
    azure-identity
    mcp
    numpy
    posthog
  ];

  # Don't run tests or checks
  doCheck = false;
  dontUsePipInstall = true;
  
  # Override build phase to skip the Makefile
  buildPhase = ''
    echo "Skipping build phase"
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/python${python3.pythonVersion}/site-packages
    
    # Copy the core graphiti module (required by mcp_server)
    cp -r graphiti_core $out/lib/python${python3.pythonVersion}/site-packages/
    
    # Copy the MCP server files
    cp -r mcp_server $out/lib/python${python3.pythonVersion}/site-packages/
    
    # Create the executable script
    cat > $out/bin/graphiti-mcp-server << EOF
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '$out/lib/python${python3.pythonVersion}/site-packages')
os.chdir('$out/lib/python${python3.pythonVersion}/site-packages/mcp_server')
exec(open('graphiti_mcp_server.py').read())
EOF
    chmod +x $out/bin/graphiti-mcp-server
  '';

  meta = with lib; {
    description = "Graphiti MCP Server";
    homepage = "https://github.com/getzep/graphiti";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}