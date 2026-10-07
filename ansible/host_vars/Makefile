VAULT_PASSWORD_FILE := ../config/.vault_password
VAULT_EDITOR := goland --wait

# Меню выбора хоста из папок host_vars: make edit-secrets
edit-secrets:
	@hosts=$$(ls -d */ 2>/dev/null | tr -d /); \
	if [ -z "$$hosts" ]; then echo "Нет папок хостов в host_vars"; exit 1; fi; \
	PS3="Номер хоста: "; COLUMNS=1; \
	select host in $$hosts; do \
		[ -n "$$host" ] && $(MAKE) --no-print-directory edit-secrets-$$host; break; \
	done

# Редактирование vault-секретов конкретного хоста: make edit-secrets-<host> (создаёт файл, если его нет)
edit-secrets-%:
	@action=edit; [ -f $*/secrets.yml ] || action=create; \
	EDITOR="$(VAULT_EDITOR)" ansible-vault $$action $*/secrets.yml --vault-password-file $(VAULT_PASSWORD_FILE)

.PHONY: edit-secrets
