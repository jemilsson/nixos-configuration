
{
imports = [
  ./base.nix
];
networking = {
  firewall = {
    enable = false;
  };

  defaultGateway6 = {
    address = "2001:470:dc6b::1";
    interface = "eth0";
  };
};

}
