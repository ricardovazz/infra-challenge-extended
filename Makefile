SHELL := /bin/bash -o pipefail
KUBECTL := kubectl --context k3d-cluster

.PHONY: create-k3d-cluster
.PHONY: delete-local-kube-cluster
.PHONY: build-pinger
.PHONY: run-local-kube-with-ping-pong-app

create-k3d-cluster: delete-local-kube-cluster
	@which k3d >> /dev/null || echo "K3d must be installed to create local kube cluster\n==> wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash" \
	&& k3d cluster create cluster --k3s-arg '--disable=servicelb@server:0' --k3s-arg '--disable=traefik@server:0' --agents 2

delete-local-kube-cluster:
	@echo "Deleting existing cluster..." && k3d cluster delete cluster

build-pinger:
	docker build -t pinger:latest app/pinger

build-ponger:
	docker build -t ponger:latest app/ponger

solution-run-local-kube-with-ping-pong-app: 
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -subj "/CN=pong" -addext "subjectAltName=DNS:pong"\
	&& cp cert.pem app/pinger \
	&& $(MAKE) build-pinger \
	&& $(MAKE) build-ponger \
	&& $(MAKE) create-k3d-cluster \
	&& k3d image import pinger:latest --cluster cluster \
	&& k3d image import ponger:latest --cluster cluster \
	&& ${KUBECTL} create secret tls ponger-tls --cert=cert.pem --key=key.pem \
	&& ${KUBECTL} apply \
	  -f app/ponger/manifests/manifest.yaml \
	  -f app/pinger/manifests/manifest.yaml \
	&& rm key.pem \
	&& rm cert.pem \
	&& echo "cluster available on kubernetes context k3d-cluster"

