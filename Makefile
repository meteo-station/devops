create-ansible-password-file:
	echo "Please enter the Ansible Vault password for the playbooks:"
	@read -s ansible_password; \
	echo $$ansible_password > .vault_password; \
	echo "Ansible Vault password file created."

deploy-go-exporter:
	$(MAKE) -C ansible/servers/meteo-station deploy-go-exporter

deploy-go-exporter-dev:
	$(MAKE) -C ansible/servers/meteo-station deploy-go-exporter-dev

add-ansible-vault-password:
	echo $(VAULT_PASSWORD) > ansible/config/.vault_password

edit-secrets:
	ansible-vault edit ansible/secrets.yml
