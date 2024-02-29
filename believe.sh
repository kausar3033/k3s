#!/bin/bash
set -x
curl -sfL https://get.k3s.io | sh -
sudo ufw allow 6443/tcp
sudo ufw reload
mkdir -p ~/.kube
touch ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
echo -e "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  namespace: metallb-system\n  name: config\ndata:\n  config: |\n    address-pools:\n    - name: default\n      protocol: layer2\n      addresses:\n      - 192.168.10.49-192.168.10.50" >> metallb-configmap.yaml
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
MIIE9jCCA96gAwIBAgISA6YMFwR4R8qdbf0Z9yCZTWg3MA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yNDAyMjkwOTA2NTVaFw0yNDA1MjkwOTA2NTRaMCAxHjAcBgNVBAMT
FWVycC5nbG9iYWxiZWxpZXZlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
AQoCggEBALP8jW1AsffzkxqbXV7UrJxvNI53tsDcobPT8LTwQJaxtNTe2hj1Vz3e
uLBfjiYdGH2U3bwl3ccQUSu7UApXtp0Om+yumGFbbyETXY+VxU7QJczouKhQNB0j
ilAVwDl5LbFipuwk62ln/OTCrvtUX5Wggzx7Zb4Gi5ieRRUMN0dIlku/HC9ONRS/
EAHYChD4SFjnGOSx3gsv4lPm2QiIUTn8mgUT3Dz4EJsQPvBftmy6OPyrkl26RSvr
JT2BWk2PZh2f/TU2KMHIhH57i6TKX42SAJQTO17M0BHCHo1L+mW4Rfi0hfdk8SRS
hjAlZUljHopuBQkakpjj8Buk9v48xAkCAwEAAaOCAhYwggISMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIw
ADAdBgNVHQ4EFgQUEw6lretgtJv28JBeU6mFFit54dMwHwYDVR0jBBgwFoAUFC6z
F7dYVsuuUAlA5h+vnYsUwsYwVQYIKwYBBQUHAQEESTBHMCEGCCsGAQUFBzABhhVo
dHRwOi8vcjMuby5sZW5jci5vcmcwIgYIKwYBBQUHMAKGFmh0dHA6Ly9yMy5pLmxl
bmNyLm9yZy8wIAYDVR0RBBkwF4IVZXJwLmdsb2JhbGJlbGlldmUuY29tMBMGA1Ud
IAQMMAowCAYGZ4EMAQIBMIIBAwYKKwYBBAHWeQIEAgSB9ASB8QDvAHYAO1N3dT4t
uYBOizBbBv5AO2fYT8P0x70ADS1yb+H61BcAAAGN9FTO4wAABAMARzBFAiEAthtX
ovqkib7OZv8A0hdu8Xi3m5VTl4mP4CDZHeaTSUwCIF9QuxiEiLnACXgYVch9Th/3
Yq+KuJHT6hBnKEyDOHDbAHUAouK/1h7eLy8HoNZObTen3GVDsMa1LqLat4r4mm31
F9gAAAGN9FTPjQAABAMARjBEAiBqSVW6tzTiPPlNe261YT54+/78dA7LAGQSYTxR
Z9qNrQIgM4axDjH7d03YseRcuqsH1L8zGO4p3UA/gxKN5jPTHRswDQYJKoZIhvcN
AQELBQADggEBALfz2tmWj60tQ3EvyVoY7CYNWeImJ6V3ygi2pd68d8TKubBJZKUe
nrReBpuxoVRqFlo/rA3QZrOLdLHL0VvZCRbDpwFLdZehGJV5K6NqMHJkmW+lWHVp
HoloiVr4+f8id28RpgrRg8GvoOuEnKZXS2rHgNadEuKdeWCbIRCcCT6j5DIhQZUB
94o8YrsS8i7+hxlUVvqnnLQgDJ/K8VLG6OGcOfy5JhRcc7AtBbOErS9ANDz2I+yI
0+bilLY6/Bqt6KP78cU6IuQbNU8DKhxHNUH38414PRM2xMojJKEcw6dwV6sxQF3p
uMmGnDnkseMwHh7BGHGers/0Msor+ebg/OA=
-----END CERTIFICATE-----" >> cert.pem


echo -e "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAs/yNbUCx9/OTGptdXtSsnG80jne2wNyhs9PwtPBAlrG01N7a
GPVXPd64sF+OJh0YfZTdvCXdxxBRK7tQCle2nQ6b7K6YYVtvIRNdj5XFTtAlzOi4
qFA0HSOKUBXAOXktsWKm7CTraWf85MKu+1RflaCDPHtlvgaLmJ5FFQw3R0iWS78c
L041FL8QAdgKEPhIWOcY5LHeCy/iU+bZCIhROfyaBRPcPPgQmxA+8F+2bLo4/KuS
XbpFK+slPYFaTY9mHZ/9NTYowciEfnuLpMpfjZIAlBM7XszQEcIejUv6ZbhF+LSF
92TxJFKGMCVlSWMeim4FCRqSmOPwG6T2/jzECQIDAQABAoIBAQCjklpVd/5FgS+n
dpscm9tjMA1rjJCiJeEvNOYFCnMogMf+zakYFZ/7snXWlIDzUm33c1swqpkrWEDs
pYbQX3autaAvMV163UXZoWfeHhb60WAJIVbwYDN8Z9hDgAD6Oo60LxvUcJkhakgC
/otYDg3wRbf/N4X3dKtZQD04K6nxNRh3ZU2Y1qDUeHarD+NME30gi2Y+3SExnztz
ZOKobIprof64wIVIdLPjpyjM9jU+AqIpYkji29DFbKz4LpUQwmI2awcjiWJ+buAi
gYowrl7KxbIvWe0DKzTO5Iy2luw91Nym4h3xKEKgPTVvWO/jUKnfvdHbGZQ5RX3N
75kXmfShAoGBANfHqykr6ylVLBaa+K31XgxXCfaXiQIzP+iy9gdxcN1LCmxGr+Dg
QEIKnzo3Jea8OjN93JgJnGaDOVEl/Yzfq0NITN1eElgw1p2jm9vMUzWEn3HnYRcJ
znQYMB5MXNvs7Yalze0G632VOJV0JZsYWeZqrvDDsnJfUGcTPQdVjPXbAoGBANWI
75UUfiJt7/k2+s50+cCLyCEw+76n1IxOT5fv8nnqbCsVj6AiHdgn/+fJociWgVPO
6Fg2l/3OkGU/HJbLJaCuRk8gacNlt2sPrsVCGGZpNSQGAv9y6HSwZGPsd7ht/X1b
OjPDXk4Tn6zw5Bze0WOngGwE2bQ+ATHRBaqmk3zrAoGAF60h+7+E6yEcWFKizLuq
mSIHxtXzw5kJ/yd71W8+Ghn8x8qty7fvdQ+jTwj0ELBAlpvN06TiU2E8rcnEW2vD
Z/uL65JB4wlg0yU7mc9+pdWqhR4FSjjaPWTWCs0IN1105pxUzxg+SKZR8hwvcCgo
3R6BmYtvjhslQFodDSv27pcCgYEAksEO72VrHtxxrdSEYLnyH8uxmmYgzjJoGJmF
iEWHXxSmjKG/2O05l6I99R4VS1dswJ2V/3Jd2ThK8tqCGny5eonrllwPdBQHD9Ry
Z+15+YBa3kwnaUqeyfuksywER8OIEMxO3t5phL1l4ySXkePtAlFPKG3Y9VAb4BHo
lBTxjksCgYBxozE7+ZEDajOUQKDU/mxR80EaEX2ROdMbjGHPYnZR+WwPFAVylju6
tDm7U4bcqPiF+M5ALvw/xcz3g8NUo5kn8bE45KNju9EsjP9vgPxdZuiDmBkybld4
ddPUUOMTnDOjLnmLoLv6eOcyankvxeULQcZBgJFCrsIPb4i7nvS58g==
-----END RSA PRIVATE KEY-----" >> key.pem
chmod 444 key.pem cert.pem
kubectl -n production create secret tls ibosio-ingress-tls --key key.pem --cert cert.pem


echo -e 'apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  annotations:\n    nginx.ingress.kubernetes.io/ssl-redirect: "true"\n    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-body-size: "0"\n     \n  name: ing-ibosapp\nspec:\n  ingressClassName: ibosio-ingress\n  rules:\n    - host: vat.amancem.com\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: vatapi\n                port:\n                  number: 80\n\n\n\n  tls:\n    - hosts:\n        - globalbelieve.com\n       \n\n      secretName: ibosio-ingress-tls' >> ibos_ingress.yaml
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
