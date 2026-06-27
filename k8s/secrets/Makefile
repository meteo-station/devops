export SOPS_AGE_KEY_FILE=key.txt

# Секреты
edit-secrets-prod:
	EDITOR="goland --wait" sops --config .sops.yaml -i secrets-prod.yaml

edit-secrets-dev:
	EDITOR="goland --wait" sops --config .sops.yaml -i secrets-dev.yaml
