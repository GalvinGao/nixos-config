# Switch to new configuration and create symlinks
switch:
    sudo morlana switch --flake .

# Build and activate the configuration without switching
test:
    sudo morlana build --flake .

# Update all flake inputs
update:
    nix flake update

# Clean up old generations and optimize store
clean:
    nix-collect-garbage -d
    nix store optimise

# Show current system version and last modified date
version:
    darwin-rebuild --version
    stat -f "%Sm" /run/current-system

# Print missing Homebrew packages for manual addition
print-brew:
    ./print-missing-brew.sh