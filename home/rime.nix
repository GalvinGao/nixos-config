{ pkgs, ... }:

let
  # Overlay rime-ice's data dir with our custom_phrase.txt. Needed because
  # `home.file` with `recursive = true` doesn't expose leaf files as
  # overridable attrset entries, so lib.mkForce can't replace existing files
  # inside the source tree — only add new ones.
  rimeData = pkgs.runCommand "rime-ice-customized" { } ''
    cp -r ${pkgs.rime-ice}/share/rime-data $out
    chmod -R +w $out
    cp ${./rime/custom_phrase.txt} $out/custom_phrase.txt
  '';
in
{
  # 雾凇拼音 (rime-ice) as the schema + dicts + lua + opencc for Squirrel.
  # Recursive symlinks so Squirrel-managed runtime files (build/, *.userdb/,
  # installation.yaml, user.yaml) coexist under the same directory.
  home.file."Library/Rime" = {
    source = rimeData;
    recursive = true;
  };

  home.file."Library/Rime/default.custom.yaml".source = ./rime/default.custom.yaml;
  home.file."Library/Rime/squirrel.custom.yaml".source = ./rime/squirrel.custom.yaml;
  home.file."Library/Rime/rime_ice.custom.yaml".source = ./rime/rime_ice.custom.yaml;
}
