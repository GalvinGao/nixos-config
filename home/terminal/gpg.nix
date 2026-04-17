{ ... }:

# MacGPG2 (GPG Suite, installed via homebrew cask `gpg-suite`) reads these
# files from ~/.gnupg. We manage only the config — not the keyrings or
# gnupg binary itself — so this coexists with MacGPG2 cleanly.
{
  home.file.".gnupg/gpg.conf" = {
    force = true;
    text = ''
      auto-key-retrieve
      no-emit-version
      default-key 799D27DF06F274A76A74185AB072C8308CF8FDEC
    '';
  };

  home.file.".gnupg/gpg-agent.conf" = {
    force = true;
    text = ''
      default-cache-ttl 600
      max-cache-ttl 7200
    '';
  };
}
