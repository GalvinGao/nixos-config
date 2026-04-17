{ ... }:

{
  home.file.".duckdbrc".text = ''
    -- Managed by nix-darwin (home/terminal/duckdb.nix).
    -- DuckDB startup configuration: auto-install/load extensions and
    -- preload httpfs, ui, aws so S3/UI/cloud work with no first-query delay.

    SET autoinstall_known_extensions=1;
    SET autoload_known_extensions=1;

    INSTALL httpfs;
    LOAD httpfs;

    INSTALL ui;
    LOAD ui;

    INSTALL aws;
    LOAD aws;
  '';
}
