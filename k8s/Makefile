export SOPS_AGE_KEY_FILE=secrets/key.txt

# Тестирование
show-spec:
	helm show values bitnami/postgresql

template-prod:
	helmfile -e prod template # -l name=go-server

template-dev:
	helmfile -e dev template # -l name=go-server

write-values-prod:
	helmfile -e prod write-values

write-values-dev:
	helmfile -e dev write-values

# Деплой
deploy-prod:
	helmfile -e prod apply -l name=homeassistant

deploy-dev:
	helmfile -e dev apply -l env!=prod

sync-prod:
	helmfile -e prod sync

sync-dev:
	helmfile -e dev sync -l env!=prod

uninstall-prod:
	helm uninstall ingress-nginx -n ingress-nginx-prod

uninstall-dev:
	helm uninstall dev -n dev

# Генерация kubeconfig для пользователя (make kubeconfig KUBE_USER=maxpayne)
KUBE_USER ?= devops
kubeconfig:
	kubectl get secret $(KUBE_USER)-token -n default -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/$(KUBE_USER)-ca.crt
	kubectl --kubeconfig=/tmp/$(KUBE_USER).yaml config set-cluster digital-security \
		--server=$(shell kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') \
		--certificate-authority=/tmp/$(KUBE_USER)-ca.crt \
		--embed-certs=true
	kubectl --kubeconfig=/tmp/$(KUBE_USER).yaml config set-credentials $(KUBE_USER) \
		--token=$(shell kubectl get secret $(KUBE_USER)-token -n default -o jsonpath='{.data.token}' | base64 -d)
	kubectl --kubeconfig=/tmp/$(KUBE_USER).yaml config set-context default \
		--cluster=digital-security \
		--user=$(KUBE_USER)
	kubectl --kubeconfig=/tmp/$(KUBE_USER).yaml config use-context default
	rm /tmp/$(KUBE_USER)-ca.crt
	cp /tmp/$(KUBE_USER).yaml ~/Desktop/$(KUBE_USER).yaml
	@echo "Kubeconfig saved to ~/Desktop/$(KUBE_USER).yaml"

# Корневой self-signed CA для *.home — добавь его в системное доверенное хранилище,
# чтобы браузеры/клиенты перестали ругаться на сертификаты grafana.home, exporter.home и т.п.
home-ca:
	kubectl get secret home-ca-tls -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d > ~/Desktop/home-ca.crt
	@echo "Root CA saved to ~/Desktop/home-ca.crt"
	@echo "macOS: открой Keychain Access → drag-n-drop файл → Always Trust"
