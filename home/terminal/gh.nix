{ ... }:

{
  programs.gh = {
    enable = true;
    settings = {
      version = "1";
      git_protocol = "https";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
