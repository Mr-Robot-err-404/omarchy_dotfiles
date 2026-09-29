.PHONY: vet

vet:
	bash -n install-gaming.sh state.sh system/usr/local/bin/*
	@if command -v shellcheck >/dev/null; then shellcheck install-gaming.sh state.sh system/usr/local/bin/*; fi
