{ config, lib, pkgs, ... }:
let
  wildtextures = "https://www.wildtextures.com/wp-content/uploads/";
  thepatternlibrary = "http://thepatternlibrary.com/img/";
  mb3d = "http://www.mb3d.co.uk/mb3d/";
in
{


environment.etc = {
  "wallpapers/1.jpg" = {
    source = pkgs.fetchurl {
      url = "${wildtextures}wildtextures-Seamless-Dark-Marble-Tiles-Texture1.jpg";
      sha256 = "d7f0c75305ed32212a375c0e3899610ae73a8a08577558a128a167e44bdcc04a";
    };
  };
  "wallpapers/2.jpg" = {
    source = pkgs.fetchurl {
      url = "${wildtextures}wildtextures-seamless-street-marble-stones.jpg";
      sha256 = "a4d3445b9634835c672080b6caabb2c358aefc1b4634f765236921a331b45154";
    };
  };
  "wallpapers/3.jpg" = {
    source = pkgs.fetchurl {
      url = "${wildtextures}wildtextures_hardwood-horizontal-floor-tileable-pattern.jpg";
      sha256 = "2f92bb71e07e826018dd02cfcc219aa9cf1edcae571fc6779f3606c56492c770";
    };
  };
  "wallpapers/4.jpg" = {
    source = pkgs.fetchurl {
      url = "${thepatternlibrary}ae.jpg";
      sha256 = "ca5a7d12d3fe52d82745aea931eb68592698f31eb33bd186a65c4013ca3727da";
    };
  };
  "wallpapers/5.jpg" = {
    source = pkgs.fetchurl {
      url = "${thepatternlibrary}ao.gif";
      sha256 = "2886d91c0f0bbac19eadc7eca6c111711ad9a72da7b6a82fb53f82e5e5938e9e";
    };
  };
  "wallpapers/6.jpg" = {
    source = pkgs.fetchurl {
      url = "${thepatternlibrary}f.jpg";
      sha256 = "bf89478af07cc393ada044dc2784d681efea78927758b43eae30d6ba5f8c57a9";
    };
  };
  "wallpapers/7.jpg" = {
    source = pkgs.fetchurl {
      url = "${wildtextures}wildtextures_medival-metal-doors.jpg";
      sha256 = "d0d15ac7e540c5722559fb1c0ca7475ceb1cfb027c3608099aafaa60d4d303f3";
    };
  };
  "wallpapers/8.jpg" = {
    source = pkgs.fetchurl {
      url = "${wildtextures}wildtextures-leather-Campo-petroleum.jpg";
      sha256 = "36ab79bdd0b3dac7b9266ae92dd17cd9a6e8daae8031969870f9d283893c37c6";
    };
  };
  "wallpapers/9.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Brick_Seamless_and_Tileable_High_Res_Textures_files/Brick_Design_UV_H_CM_1.jpg";
      sha256 = "78ac92f3bd6c627211d083bff7636d3e161d3e1bb202e4405f8eb69c105673ab";
    };
  };
  "wallpapers/10.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Pavement_and_Roads_Seamless_and_Tileable_High_Res_Textures_files/Cobbles_01_UV_H_CM_1.jpg";
      sha256 = "57a6115f9e4a3fa8d1b5b2804aa0a5e64032425e1fcde9bf881c204f1abf6edf";
    };
  };
  "wallpapers/11.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Stone_and_Rock_Seamless_and_Tileable_High_Res_Textures_files/Stone_06_UV_H_CM_1.jpg";
      sha256 = "47977a6ab4108e58eb2598f16e7a69970496db62ded4ba0b12ad488f06adb8ed";
    };
  };
  "wallpapers/12.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Plant_and_Leaf_Seamless_and_Tileable_High_Res_Textures_files/plantbed_1.jpg";
      sha256 = "d89637d0efb40479025d98be6456e6093afc870893813d52024cda7db269085d";
    };
  };
  "wallpapers/13.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Plant_and_Leaf_Seamless_and_Tileable_High_Res_Textures_files/Plant_03_UV_H_CM_1.jpg";
      sha256 = "efa5fa1f6ed2ee0cec3b640658e2976da3f488db1b2a24daaa0d234b6f66ce78";
    };
  };
  "wallpapers/14.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Plant_and_Leaf_Seamless_and_Tileable_High_Res_Textures_files/Wall_02_UV_H_CM_1.jpg";
      sha256 = "3f8c6b7d1727b2571bbd5f560c7acd6ddecb8a0396b54024ec5931ab48aef929";
    };
  };
  "wallpapers/15.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Metal_Corrugated_and_Painted_Ground_Seamless_and_Tileable_High_Res_Textures_files/Steel_Grating_02_UV_H_CM_1.jpg";
      sha256 = "66e3c088613e0964891f0e0747bcaf275f69589fb9683a7363ef170f109444a7";
    };
  };

  "wallpapers/16.jpg" = {
    source = pkgs.fetchurl {
      url = "${mb3d}Metal_Corrugated_and_Painted_Ground_Seamless_and_Tileable_High_Res_Textures_files/Steel_07_UV_H_CM_1.jpg";
      sha256 = "ccc28a8c4d051c07a7e54ee6a8b5f4eeb36c0c8ee24d09283e6e8cbe9c4d4b25";
    };
  };



};
}
