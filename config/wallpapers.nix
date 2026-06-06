{ config, lib, pkgs, ... }:
let
  wildtextures = "https://www.wildtextures.com/wp-content/uploads/";
  mb3d = "http://www.mb3d.co.uk/mb3d/";

  # wildtextures.com now 404s on these assets, so fetch from the Wayback Machine
  # (originals kept as fallbacks in case upstream revives). Each `id_` snapshot is
  # byte-identical to the pinned sha256, which still gates correctness.
  wayback = ts: name: "https://web.archive.org/web/${ts}id_/${wildtextures}${name}";
in
{


  environment.etc = {
    "wallpapers/1.jpg" = {
      source = pkgs.fetchurl {
        urls = [
          (wayback "20161030175742" "wildtextures-Seamless-Dark-Marble-Tiles-Texture1.jpg")
          "${wildtextures}wildtextures-Seamless-Dark-Marble-Tiles-Texture1.jpg"
        ];
        sha256 = "d7f0c75305ed32212a375c0e3899610ae73a8a08577558a128a167e44bdcc04a";
      };
    };
    "wallpapers/2.jpg" = {
      source = pkgs.fetchurl {
        urls = [
          (wayback "20230806152110" "wildtextures-seamless-street-marble-stones.jpg")
          "${wildtextures}wildtextures-seamless-street-marble-stones.jpg"
        ];
        sha256 = "a4d3445b9634835c672080b6caabb2c358aefc1b4634f765236921a331b45154";
      };
    };
    "wallpapers/3.jpg" = {
      source = pkgs.fetchurl {
        urls = [
          (wayback "20240522184537" "wildtextures_hardwood-horizontal-floor-tileable-pattern.jpg")
          "${wildtextures}wildtextures_hardwood-horizontal-floor-tileable-pattern.jpg"
        ];
        sha256 = "2f92bb71e07e826018dd02cfcc219aa9cf1edcae571fc6779f3606c56492c770";
      };
    };
    "wallpapers/7.jpg" = {
      source = pkgs.fetchurl {
        urls = [
          (wayback "20240522180731" "wildtextures_medival-metal-doors.jpg")
          "${wildtextures}wildtextures_medival-metal-doors.jpg"
        ];
        sha256 = "d0d15ac7e540c5722559fb1c0ca7475ceb1cfb027c3608099aafaa60d4d303f3";
      };
    };
    "wallpapers/8.jpg" = {
      source = pkgs.fetchurl {
        urls = [
          (wayback "20230328044409" "wildtextures-leather-Campo-petroleum.jpg")
          "${wildtextures}wildtextures-leather-Campo-petroleum.jpg"
        ];
        sha256 = "36ab79bdd0b3dac7b9266ae92dd17cd9a6e8daae8031969870f9d283893c37c6";
      };
    };
  };
}
