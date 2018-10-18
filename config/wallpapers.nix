{ config, lib, pkgs, ... }:
let
  wildtextures = "https://www.wildtextures.com/wp-content/uploads/";

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
};
}
