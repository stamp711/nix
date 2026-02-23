{
  description = "Solaar - Logitech device manager";

  module =
    { inputs, ... }:
    {
      imports = [ inputs.solaar.nixosModules.default ];
      services.solaar.enable = true;
    };
}
