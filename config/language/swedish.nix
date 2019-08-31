{ config, lib, pkgs, ... }:
let
  swedish = "sv_SE.UTF-8";
in
{
  i18n = {
    defaultLocale = swedish;
    extraLocaleSettings = {
      LC_CTYPE = swedish;
      LC_NUMERIC = swedish;
      LC_TIME = swedish;
      LC_COLLATE = swedish;
      LC_MONETARY = swedish;
      LC_MESSAGES = english;
      LC_PAPER = swedish;
      LC_NAME = swedish;
      LC_ADDRESS = swedish;
      LC_TELEPHONE = swedish;
      LC_MEASUREMENT = swedish;
      LC_IDENTIFICATION = swedish;
    };
  };
}
