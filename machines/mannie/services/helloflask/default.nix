with import <nixpkgs> {};
{ pkgs ? import <nixpkgs> {} }:

let
    pythonPackages = python36Packages;
in
  pythonPackages.buildPythonPackage {
    name = "helloflask";

    propagatedBuildInputs = [
        pythonPackages.flask
    ];

    src = ./.;

}
