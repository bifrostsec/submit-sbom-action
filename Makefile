# Maintenance tasks for the action. The action itself has no build step.

.PHONY: update-cli

# Pin the bifrost CLI release in scripts/select-cli-release.sh to the latest
# release and refresh the SHA-256 checksum of every asset. Pass VERSION to pin
# a specific release instead:
#
#   make update-cli
#   make update-cli VERSION=v0.4.0
update-cli:
	bash scripts/update-cli-release.sh $(VERSION)
