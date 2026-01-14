export ANSIBLE_CONFIG = ../../config/ansible.cfg

init-users:
	ansible-playbook ../init-users.yml -e target=monitoring

setup-server:
	ansible-playbook setup-server.yml
