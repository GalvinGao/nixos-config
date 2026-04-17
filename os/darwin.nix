[
  {
    system = "aarch64-darwin";
    hosts = [
      "Galvin-MacBook-Pro"
      "Galvin-MacBook-Pro-2024"
    ];
    moduleResolver = host: [
      (
        if host == "Galvin-MacBook-Pro" then ./.. + "/hosts/darwin/mbp-primary"
        else if host == "Galvin-MacBook-Pro-2024" then ./.. + "/hosts/darwin/mbp-2024"
        else throw "os/darwin.nix: no mapping for host '${host}'"
      )
    ];
  }
]
