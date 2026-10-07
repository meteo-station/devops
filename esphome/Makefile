export SOPS_AGE_KEY_FILE = key.txt

# Правка секретов "в git" — открывает расшифрованным в редакторе,
# при сохранении сам шифрует обратно. Ничего расшифрованного на диске
# после выхода не остаётся.
edit-secrets:
	EDITOR="goland --wait" sops --config secrets/.sops.yaml secrets/secrets.enc.yaml

# Расшифровать в рабочий config/secrets.yaml, который реально читает
# ESPHome-контейнер (смонтированная директория). Файл в .gitignore —
# в репозиторий никогда не попадает открытым текстом.
decrypt-secrets:
	sops -d secrets/secrets.enc.yaml > config/secrets.yaml
	@echo "config/secrets.yaml обновлён (не в git, см. .gitignore)"
