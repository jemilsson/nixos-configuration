with import <nixpkgs> {};
{ pkgs ? import <nixpkgs> {} }:

let
    pythonPackages = python35Packages;
in
  pythonPackages.buildPythonPackage {
    name = "helloflask";

    propagatedBuildInputs = [
        pythonPackages.flask
        pythonPackages.gunicorn
    ];

    src = ./.;

}
