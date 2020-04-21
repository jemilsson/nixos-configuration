
{
imports = [
  ./base.nix
];
networking = {
  firewall = {
    enable = false;
  };

  defaultGateway6 = {
    address = "2a0e:b107:330::1";
    interface = "eth0";
  };
};

}
