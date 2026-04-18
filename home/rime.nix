{ lib, pkgs, ... }:

{
  # 雾凇拼音 (rime-ice) as the schema + dicts + lua + opencc for Squirrel.
  # Recursive symlinks so Squirrel-managed runtime files (build/, *.userdb/,
  # installation.yaml, user.yaml) coexist under the same directory.
  home.file."Library/Rime" = {
    source = "${pkgs.rime-ice}/share/rime-data";
    recursive = true;
  };

  home.file."Library/Rime/default.custom.yaml".source = ./rime/default.custom.yaml;
  home.file."Library/Rime/squirrel.custom.yaml".source = ./rime/squirrel.custom.yaml;

  # Override rime-ice's sample custom_phrase.txt with our personal shortcuts.
  home.file."Library/Rime/custom_phrase.txt" = lib.mkForce {
    source = ./rime/custom_phrase.txt;
  };
}
