# Starling infrastructure recruitment challenge

Ricardo Vaz

ricardodaniel.vaz@gmail.com


## Solution Explanation:

### Running the solution:

make solution-run-local-kube-with-ping-pong-app


## Solution Explanation:

### 0) Initial File:
Found BZh at start – after searching, file looks like it was compressed with Bzip2 algotrithm

file starling-infrastructure-assignment.out 

a.	starling-infrastructure-assignment.out: POSIX tar archive

b.	Found that file it’s a TAR, extracted it


### 1) Created simple DockerFile for pinger and ponger apps

a. Used lightweight golang:alpine image

b. Used provided command to Build Go application

	FROM golang:alpine
	
	WORKDIR /app
	
	COPY . .
	
	RUN CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -a --installsuffix cgo --ldflags="-s -w" -o /pinger
	
	ENTRYPOINT [ "/pinger" ]

### 2) Running intermediate Makefile steps

a. Updated image tag names in Makefile to the name expected (in manifest and other Makefile steps):

      docker build -t pinger:latest .
      
      docker build -t ponger:latest .


### 3) Created certficate and updated Makefile steps so that Pinger and Ponger apps can make secure use of it

a. Created self-signed certificate 

  	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -subj "/CN=pong" -addext "subjectAltName=DNS:pong"\

  It's important to add the correct hostname ("pong") so that the certificate can be verified


b. Provided certificate to Pinger application code base

  	cp cert.pem app/pinger

c. Created Kubernetes Secret to be used by Ponger application securely, and protect the key

  	${KUBECTL} create secret tls ponger-tls --cert=cert.pem --key=key.pem

d. Updated Ponger manifest to make use of the secret as a volume

          volumeMounts:
        - name: tls-volume
          mountPath: "/etc/tls"
          readOnly: true
      volumes:
      - name: tls-volume
        secret:
          secretName: ponger-tls

e. Updated Ponger Config

	service:
	  port: 8080
	  tlsCertificate: /etc/tls/tls.crt
	  tlsPrivateKey: /etc/tls/tls.key


f. Removed generated key from workspace

	  rm key.pem
	  
	  rm cert.pem


### 4) Updated Makefile script, created local kubernetes cluster 

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

 
### 5) Fixed issues to make services up and running

a. Check Pong service and Endpoints.

	  kubectl get svc,po,ep -o wide
	  
	  kubectl describe svc pong
	  
	  kubectl describe ep


b. Verified that necessary endpoints were not created correctly, and "pong" service was not communicating with pods in "ponger" deployment


c. Updated "pong" service selector to correct label "ponger", as defined in "ponger" deployment
  
	  apiVersion: v1
	  kind: Service
	  metadata:
	    name: pong
	  spec:
	    selector:
	      app.kubernetes.io/name: ponger


d. Verified that without using the Network Policies, "pinger" is able to communicate with "ponger" via HTTPS using the created Certificate


e. Checked "pinger" pod logs. Verified that connection was failing due to UDP connection refused on port 53, during the dns lookup. Updated "allow-allpods-to-dns" Network Policy to allow required traffic

     ports:
    - port: 53
      protocol: TCP
    - port: 53
      protocol: UDP


f. Checked "pinger" pod logs. Verified Connection Refused when calling "ponger". Added new policy to allow outbound and inboud TCP traffic: Egress to pods with label “ponger” from "pinger" (outbound) and Ingress from pods with label "ponger" from "pinger"  (being denied by default with the policy "default-deny-all")

	apiVersion: networking.k8s.io/v1
	kind: NetworkPolicy
	metadata:
	  name: allow-ingress-ponger
	  namespace: default
	spec:
	  podSelector:
	    matchLabels:
	      app.kubernetes.io/name: ponger
	  policyTypes:
	  - Ingress
	  ingress:
	  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: pinger  
    ports:
    - protocol: TCP
      port: 8080

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-pinger
  namespace: default
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: pinger
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: ponger
	      ports:
	        - protocol: TCP
	          port: 8080




### 6) What would you do differently or add to run these micro services in a production environment ?

  In a production enviroment, credentials like a certificate key would have to be received differently, and centrally managed. Still, we could use Kubernetes secrets to securely use the credentials. This was done in this example implementation.

  In terms of sharing certificates, that could be done via several ways, like a config server which the application would connect to and get relevant config from.

  For network policies, instead of managing them directly, we could implement a service mesh, which would take care of securing the communication between the microservices, and controlling ingress/egress.

  In production, we would also use versioning on the microservices, and deploy a specific tag with a CICD pipeline, where an improved script would be called, deploying the desired version of the app. 

  To mantain a better consistency on the production kubernetes clusters, we would also use umbrella Helm charts for deployment, instead of pure Kubernetes manifests which are much more prone to errors.
