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
  };
}
