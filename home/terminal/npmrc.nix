{ ... }:

{
  # Scoped registry for @troph-team → GitHub Packages.
  # Token comes from $NPM_GITHUB_TOKEN (set in zsh.nix via macOS keychain);
  # ''${...} escapes Nix interpolation so the literal ${NPM_GITHUB_TOKEN}
  # reaches .npmrc for npm/pnpm to expand at install time.
  home.file.".npmrc".text = ''
    @troph-team:registry=https://npm.pkg.github.com
    //npm.pkg.github.com/:_authToken=''${NPM_GITHUB_TOKEN}
  '';
}
