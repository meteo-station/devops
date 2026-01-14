export ANSIBLE_CONFIG = ../../config/ansible.cfg

init-users:
	ansible-playbook ../init-users.yml -e target=meteo-station

setup-server:
	ansible-playbook setup-server.yml

docker-prune:
	ansible-playbook docker-prune.yml

deploy-go-exporter:
	ansible-playbook deploy-go-exporter.yml

deploy-go-exporter-dev:
	ansible-playbook deploy-go-exporter-dev.yml

upsert-certs:
	ansible-playbook upsert-certs.yml
