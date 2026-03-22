switch:
	nh darwin switch .

update:
	nix flake update

drift:
	./detect-drift.sh