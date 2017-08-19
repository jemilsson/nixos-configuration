with import <nixpkgs> {};
{ pkgs ? import <nixpkgs> {} }:

pythonPackages.buildPythonPackage {
    name = "helloflask";

    propagatedBuildInputs = [
        pkgs.python35Packages.flask
        pkgs.python35Packages.gunicorn
    ];

    #preBuild = ''
    #    ${python}/bin/python voting/manage.py collectstatic --noinput;
    #'';

    src = ./.;
}
