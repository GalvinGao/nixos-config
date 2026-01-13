{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    daemon = {
      enable = false;
    };
  };
}
