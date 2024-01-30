git clone https://github.com/kausar3033/k3s.git&&cd k3s&&chmod +x run.sh&&./run.sh
git clone https://github.com/kausar3033/oneclickmssql.git&&cd oneclickmssql&&chmod +x mssql.sh&&./mssql.sh


#!/bin/bash
curl -sfL https://get.k3s.io | sh -
sudo ufw allow 6443/tcp
sudo ufw reload
mkdir -p ~/.kube
touch ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
echo -e "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  namespace: metallb-system\n  name: config\ndata:\n  config: |\n    address-pools:\n    - name: default\n      protocol: layer2\n      addresses:\n      - 192.168.10.33-192.168.10.34" >> metallb-configmap.yaml
chmod +x metallb-configmap.yaml
kubectl apply -f metallb-configmap.yaml

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm -n production repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm -n production repo add  stable https://charts.helm.sh/stable
helm repo add nginx-stable https://helm.nginx.com/stable
helm -n production  repo update

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl create namespace production
kubectl run nginx --image=nginx --namespace=production
kubectl config set-context --current --namespace=production
helm -n production install ibosio-ingress nginx-stable/nginx-ingress --set controller.service.type=LoadBalancer,controller.ingressClass=ibosio-ingress
kubectl -n production get all 	
kubectl get svc

echo -e "-----BEGIN CERTIFICATE-----
MIIFCDCCA/CgAwIBAgISAwsOybvvLgLosUDOojrAcGumMA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yNDAxMzAwNTMxNDFaFw0yNDA0MjkwNTMxNDBaMB8xHTAbBgNVBAMT
FHd3dy5ocm0uZmluaXMuY29tLmJkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEA49BkK2+UVLalvjCdbbOiDtsEoc4lJfs3Nl+c9ZB5wd4NgJ0adP9O+nwE
ZDAi5Tn70UCktJnzVuvdmgs6XTmTuFtuHjvDYhupD4ynnnVq4F+OMoOi94a2Yfg9
OLBKpoT5MYTx9/dwXYQvrB7auMkmYZU+7SWZKsGVE75pSCDUZynFTMd5vBPPgwST
2j93JQh8Jv7ZPUUgjPjMlGOC/9g+59C1GmXNafh9TjEV3DjX+mtHyKdqnvJ3Wy1F
nSaKpNfXIKDrBBluNljMX3GQyJ1OKmIvEdOKr/SLND3ietp/eEuQIGwYYn6IHR5z
mzIm/3CB3m5UMLKv8KhN1rur5fc14wIDAQABo4ICKTCCAiUwDgYDVR0PAQH/BAQD
AgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAA
MB0GA1UdDgQWBBRvFhWlyLkTGvWcQxRVlq//Q1i2UDAfBgNVHSMEGDAWgBQULrMX
t1hWy65QCUDmH6+dixTCxjBVBggrBgEFBQcBAQRJMEcwIQYIKwYBBQUHMAGGFWh0
dHA6Ly9yMy5vLmxlbmNyLm9yZzAiBggrBgEFBQcwAoYWaHR0cDovL3IzLmkubGVu
Y3Iub3JnLzAxBgNVHREEKjAoghBocm0uZmluaXMuY29tLmJkghR3d3cuaHJtLmZp
bmlzLmNvbS5iZDATBgNVHSAEDDAKMAgGBmeBDAECATCCAQUGCisGAQQB1nkCBAIE
gfYEgfMA8QB3AEiw42vapkc0D+VqAvqdMOscUgHLVt0sgdm7v6s52IRzAAABjVkQ
+V8AAAQDAEgwRgIhAJ2DM7i72mPeNufY4MEcgTm9AgzBJLgG+G/F+j2shUcFAiEA
tKrkNlvEI7Y8NPj++qL1Gj/ecHd40p/UVEzldoZW0SIAdgCi4r/WHt4vLweg1k5t
N6fcZUOwxrUuotq3iviabfUX2AAAAY1ZEPmBAAAEAwBHMEUCICiJsrfXrueSJyCV
59MkYy4qzeg/RI96WSX/6qF3tNHzAiEA+e6MnTscLBm5YqDW15E5/IeolHtHUZyZ
XtagaBevdTowDQYJKoZIhvcNAQELBQADggEBAD2LkV2ENWAI2nlQFN1kzf3yza5x
zsIlgE5xF71R8EHu1GV3rPmmlwyD8kQ2A1dX3xxK3y9nvw90zknS1+BEoF4Xlr2L
rF6EySzk9e7WK4W1y2iV2QAChE/GIaar9UjM8y2/g3+XKck5EsDB5+EtFCMAJQfu
53BqJgD5r8M0whnf4Dv4158cg1whiX9F0MU5sU1SOcYlCRuw9wFjdw90OoOcIBbR
VynkpMiJpDdmfZs4LhonjSZ8BUi5LxlC9AQgu3+uu2mrV6OhQwREO3mWjoYGdTjd
ywdbNUXCx9kVwkcZ6Y/5C/+RE2vJ5Lm+HptOZ9kv761j/V9tfTr5cHBUB4I=
-----END CERTIFICATE-----" >> cert.pem


echo -e "-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA49BkK2+UVLalvjCdbbOiDtsEoc4lJfs3Nl+c9ZB5wd4NgJ0a
dP9O+nwEZDAi5Tn70UCktJnzVuvdmgs6XTmTuFtuHjvDYhupD4ynnnVq4F+OMoOi
94a2Yfg9OLBKpoT5MYTx9/dwXYQvrB7auMkmYZU+7SWZKsGVE75pSCDUZynFTMd5
vBPPgwST2j93JQh8Jv7ZPUUgjPjMlGOC/9g+59C1GmXNafh9TjEV3DjX+mtHyKdq
nvJ3Wy1FnSaKpNfXIKDrBBluNljMX3GQyJ1OKmIvEdOKr/SLND3ietp/eEuQIGwY
Yn6IHR5zmzIm/3CB3m5UMLKv8KhN1rur5fc14wIDAQABAoIBABh8WYfhokvIpd/f
UcxstkpqeAD8Kzn92l1ZwYETWkLgHwtn12Qj3NVHZyFtmxKQPOSs0gcnVOROza60
7jz+50W1bgyJ1+I/ntgxAgMiE66yFpKPW4DHVesJx2rEaAGl4TLVWzyPt+AVSRpy
5odd92YdqHnMxL23uNI6cQ5zmODNhKDyPyNvy3RFF7nYtiKdf+dYBlAyEYaiZ3SG
2P/rqw6stxLCrOg1cx8G52sNPDWvfaXcavTq79kzYlpOq3qVx80XVojF7+fSbPhQ
AgFf/+tu3XVTMzl/3QHcUtO2R1WsykbdrlhrG2vq5AHiOpD4hKlnGY2hflkOQMI2
c33/FSECgYEA86o1JNiRj+rRipcOTDtiNEAy53q79ryWRAdzSn2W893YMXmoUVTC
Ln/en/KbnNmqSCGncMJQ8GwV1aDRSG2SV+h5p8faru5u0zj7Lalag0jB52FSR7Ip
GHb80ygRvqJD5RK8FRBPb41ZboFf0XfcJ3/VcD6Ip57VEhb+UXiCMT8CgYEA71jD
dtg1YxAcgPEvtu4rWZs0soPd2kUfAT+ETJ1qUz1w0ZD5+LUJHxtLr0NuKETRKL5U
aEvFjS4QxD1sKZo5WCfB87Z8XDf700EHrMaC2r9cy4jwmLxD3tVWZ5AXSexppo83
KjRUdlyo90Mr3erm3WzaM0rgLy/JSDvqgH+uLl0CgYEA8x8+nYAVZWLoJv9nvbp2
1ynDYOI+kAdFa6V/bLD5IGSXJW58+oG2qszdZfydNhic5hHmTwUj23ANLTWj/D+Q
CHSmhjlMQsUXAVxWiw3yiRHcn7Ckd3MVvBplU48kfXDMi9Fwpxe6GtUPico+v/N3
UFYlsjRDB/TcJouYv9OdG+MCgYEAkHCi1Q+5eCT67p2ey+iDZLoTXT/THKvmABzS
vGGrDrzfXrj9AahO7uTMEeLBka+mAc6Kpb5EY+TO3X6rzZdyz85+b5NLDWQDpwNx
nETYJyag23uyppnG460fTbRZOZVgVNHM2r1l02Ar37w7ttrRpALS0212SUOvVtZB
uHZVKUkCgYEAzCcQjxWJC76OKoc6tbWRuT+6BzycUrd0Gte8YEV0oP02fccdBbMc
ijR8nbnbwLPhvTC2zH1dJtGLnk5qOD0b0tX0cV6J7jxW4xfRAZVe357nhEEatF3r
RmlzrC95IU9t7F/tXO/afd1NvD2o24y7kx0Esds7XsLsUHgl2MgYXyY=
-----END RSA PRIVATE KEY-----" >> key.pem
chmod 444 key.pem cert.pem
kubectl -n production create secret tls ibosio-ingress-tls --key key.pem --cert cert.pem


echo -e 'apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  annotations:\n    nginx.ingress.kubernetes.io/ssl-redirect: "true"\n    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-body-size: "0"\n     \n  name: ing-ibosapp\nspec:\n  ingressClassName: ibosio-ingress\n  rules:\n    - host: vat.amancem.com\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: vatapi\n                port:\n                  number: 80\n\n\n\n  tls:\n    - hosts:\n        - vat.amancem.com\n       \n\n      secretName: ibosio-ingress-tls' >> ibos_ingress.yaml
chmod +x ibos_ingress.yaml
kubectl -n production apply -f ibos_ingress.yaml

kubectl -n production create secret docker-registry dockercred --docker-server=https://index.docker.io --docker-username=iboslimitedbd --docker-password=iBOS@ltd21 --docker-email=iboslimitedbd@gmail.com

echo -e 'apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: front\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: front\n  template:\n    metadata:\n      labels:\n        app: front\n        type: front\n    spec:\n      containers:\n        - name: front\n          image: iboslimitedbd/tax-front:33941\n          # Environment variable section\n \n\n          ports:\n            - containerPort: 80\n      imagePullSecrets:\n        - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: front\nspec:\n  selector:\n    app: front\n  ports:\n    - port: 80\n      targetPort: 80\n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.209' >> front.yaml
chmod +x front.yaml
kubectl -n production apply -f front.yaml

echo -e 'apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: vatapi\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app:  vatapi\n  template:\n    metadata:\n      labels:\n        app:  vatapi\n        type: vatapi\n    spec:\n      containers:\n      - name:  vatapi\n        image: iboslimitedbd/tax-api:33959\n        # Environment variable section\n        env:\n        - name: ASPNETCORE_ENVIRONMENT\n          value: Production\n        - name:  "ConnectionString"\n          value: "l+aE5bY6HcbY5fnsLbM+J3vUqgpDbI5r4seXBE4xlI7uv+m593iBNFGO0WCLRMEkpYR9mN622oc4vRz8O2MyI0Vx42NBFITVwa7Y3XwroOA8db6aret7ovcZCpOs25gKmdoLWfsM/fysSxV1WAwnNQzFbEUnVNNehI0BpyXVa16gB1GmVEFOPC39f41NGNLVFiDTCPGtD5f4n+4+RvrZxM/bMbsDqk9zySLUObPGPJdrKgFYRTdkeRB0kSoeygb0zaZXZR7XHBrUPmlMN340mw=="\n\n      imagePullSecrets:\n      - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: vatapi\nspec:\n  selector:\n    app: vatapi\n  ports:\n  - port: 80\n    # targetPort: 80 \n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.194\n\n  #Ingress SSL with custom path Configurations' >> api.yaml
chmod +x api.yaml
kubectl -n production apply -f api.yaml

rm ~/.bash_history
history -c

rm run.sh

rm ~/.bash_history
history -c
