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
echo -e "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  namespace: metallb-system\n  name: config\ndata:\n  config: |\n    address-pools:\n    - name: default\n      protocol: layer2\n      addresses:\n      - 103.228.200.17-103.228.200.18" >> metallb-configmap.yaml
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
MIIGLjCCBRagAwIBAgIRAItafYlZhzNeUKOrh2+EBAkwDQYJKoZIhvcNAQELBQAw
gY8xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
BgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDE3MDUGA1UE
AxMuU2VjdGlnbyBSU0EgRG9tYWluIFZhbGlkYXRpb24gU2VjdXJlIFNlcnZlciBD
QTAeFw0yMjA2MTIwMDAwMDBaFw0yMzA3MTMyMzU5NTlaMBcxFTATBgNVBAMMDCou
cnNjLWJkLm9yZzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANKxbm+e
XyTEELoRa2zKrGoa5eIfhbQU3fLVx99HNOxQ65O9WFfJYI4f++3URy/h/X3e7Xge
NfpX1reX8F4vTFwIEhVc38THCLuVLMwnRojsrpfgmi7XPStpCmtIo5v/pm3za7/m
dbd5kqUvKqVDXn6dgAw/PRR1vqF3ND6x/2rckrtfL7wvajWp9DL5IPaNxtRSzn2k
lCFKJSzkqws/VnWus19mpVdWJLQmQsdWv6zCSi/xAH7z4jGFiR1708owuVnSk7mp
4v57nHDANvgBICGWiGWEmA5U1zdXJmH4iIERbCT6W+gMgYLIXWuDn34BUyb7CyNA
WXIv6jKk7GHuDm8CAwEAAaOCAvowggL2MB8GA1UdIwQYMBaAFI2MXsRUrYrhd+mb
+ZsF4bgBjWHhMB0GA1UdDgQWBBS8h5W1elAEeHRlnkPhOZ+dbtJo+zAOBgNVHQ8B
Af8EBAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYB
BQUHAwIwSQYDVR0gBEIwQDA0BgsrBgEEAbIxAQICBzAlMCMGCCsGAQUFBwIBFhdo
dHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZngQwBAgEwgYQGCCsGAQUFBwEBBHgw
djBPBggrBgEFBQcwAoZDaHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNB
RG9tYWluVmFsaWRhdGlvblNlY3VyZVNlcnZlckNBLmNydDAjBggrBgEFBQcwAYYX
aHR0cDovL29jc3Auc2VjdGlnby5jb20wIwYDVR0RBBwwGoIMKi5yc2MtYmQub3Jn
ggpyc2MtYmQub3JnMIIBfgYKKwYBBAHWeQIEAgSCAW4EggFqAWgAdgCt9776fP8Q
yIudPZwePhhqtGcpXc+xDCTKhYY069yCigAAAYFYEb/QAAAEAwBHMEUCIQDnBw+O
GblYdAPaL/Hvls4fjScS60q4iFQ+znSM5k7GSQIgE724y8PpEjBCv+OA8/Jys8uj
kacF0BWPbmT7zbR0AroAdwB6MoxU2LcttiDqOOBSHumEFnAyE4VNO9IrwTpXo1Lr
UgAAAYFYEb+dAAAEAwBIMEYCIQCAXpqKZnp9o6i6jFEVbJfPBnTsNvD1/lrKcQkT
/J5hFQIhAPQu0cCqZCsT/vtKvxOqClnAdY1LCHHx0kNr73MdbcYUAHUA6D7Q2j71
BjUy51covIlryQPTy9ERa+zraeF3fW0GvW4AAAGBWBG/aQAABAMARjBEAiBxgkSB
+2INlLpmXg1EOmbwf6K8nwBy/9nSzaSiYeeXswIgP7lqTUYdhlDWxD++VIWFRpAv
OY1REeQUrXwqEPYLBP4wDQYJKoZIhvcNAQELBQADggEBAJduJbq/JvrKYLT6/YuP
SiSZTD8YIbE2luEeeb1dSxp26YBYMGr1SrVMxdSmC2viDyMnVhy4GwqaLba9Y3eo
mPLb/RYy1CSowVXqsp2RSPmEwEZ+3R/GAI+O8ZMcUtCXK1nw3kR0xOsnCy5N2YTi
TgGGSaO7h+orbX29Ja612xo9QDhzhs9YV0jQZJXU6Z3XjHDtwsMZA9HOThvUv8ZI
mMmtcfvpALjxSVdWQFTn8AxGl6QrNnMKFjTi9iKPwfLgbs4rnqHFmjmSloDF2l0F
c4AB2AYkY+AtILtfe5Bbt4T+pnP66HTFUycfZDEM2fv2rUNFthsj4uVPqjt6xBi8
2KM=
-----END CERTIFICATE-----" >> cert.pem


echo -e "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0rFub55fJMQQuhFrbMqsahrl4h+FtBTd8tXH30c07FDrk71Y
V8lgjh/77dRHL+H9fd7teB41+lfWt5fwXi9MXAgSFVzfxMcIu5UszCdGiOyul+Ca
Ltc9K2kKa0ijm/+mbfNrv+Z1t3mSpS8qpUNefp2ADD89FHW+oXc0PrH/atySu18v
vC9qNan0Mvkg9o3G1FLOfaSUIUolLOSrCz9Wda6zX2alV1YktCZCx1a/rMJKL/EA
fvPiMYWJHXvTyjC5WdKTuani/nuccMA2+AEgIZaIZYSYDlTXN1cmYfiIgRFsJPpb
6AyBgshda4OffgFTJvsLI0BZci/qMqTsYe4ObwIDAQABAoIBAFUMqK7H+FIoDzR9
Cac93QFr4DY6UUeTUNDQuUEJRnTKaX4W5c1yDdbxVEn58c6DZEdmMOfXEiT/Rj6Q
R8hNQX65B0u2VOHjEkRegFnc1N065XOLh9G2swuN+FW8WccEGNOzemBZkFVC7w5d
DtLtcfycaW8ILAjRSuV08BMK2TbyHSiRqvQewh06pkceWzFuVR6VgydWXQulk34a
943sOG9hv6lE0O2o6zJY5nha2ibpajNeFgV/lVIJb1UB8vTpXixnTgH6atHRfnZC
SVs0zvoyUB1eMYMnNDS1o5eL4DQCtcF1snGb+0e9D9x8sFrpHPNZWG2SvsL5qqmb
nlC4A0kCgYEA98IIAlB+V/UF0nT5q+aPqDQt7tJHQUgzAKUzOIo+CmZhn0pbBBqN
o7KYdCRJCrYavPIdMv1LpMEBzM8sNtO6cWkV6moe1zJ1kXYbV+W1W5Mwvmjx8zYY
ieaqEsJdW3RnFVU/IY1w5Dxb50u0GvUXFPdIhKjoHMjqhfhfY2LI2Y0CgYEA2bO/
IV2MBrVMIEES5RzAU++YHgwtD8mhacy7lQqhfkRUBqaPiFMg4jUBLQWlvnfpbivf
xOrggLJvdYaC3KMzGpFqbvxgZIV3ihsQU45e1E9ep3j3GZyDVgPzPYM4NDiZVFyQ
MjP+R7mh6Qpt4VbcrWg3fKCxM8pQL0YBwm9YQusCgYAE7+7s7OG3qwBUs1QOYufV
+EQ6ECKvYFrz1lbw94BJAMVNQVQS/tx3uKVlGxwBhKN/xGtkirupKtd4V2CQLyP2
ApwXMcovi6fgIDRnSgKVMpe0E69Oo3NVvC0DdrAZlHZBbJN3fbQUOEe0kkOijePJ
3SuqyRrnB/H0fYCZIGzUOQKBgF7IED3BkbZV9ofQbR6NDvs8RDlIydGm0nzSoxS3
pSnpK8Adgj4zGw0BULq+S7QKVvodZfZA4G+HwFklsBHJh/VYPEOH45vANBRPxiLq
yESdLbOySbq/1rp7S8qLN8wcnD0Lc8g3tMybeG+Sl9ZU0A07Y3UCLUREH/cE/r0d
ZwrzAoGBAJyyXuNp91WIwxO6J2u8bysU3M7IBTNNuioZ4EAFEiN/hD3petdMvtw0
2aq6m1U9Rj0gwOAnmuEZpdBW/1EtPv+6KG/1iHyBgMihdyT0Mhc5Svb/qjpoZDnt
yZnv2nxIjsc+h6jRaLI3atWj0qqh94+vyY5GWhpQRgKYRd/k8pz+
-----END RSA PRIVATE KEY-----" >> key.pem
chmod 444 key.pem cert.pem
kubectl -n production create secret tls ibosio-ingress-tls --key key.pem --cert cert.pem

echo -e 'apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  annotations:\n    nginx.ingress.kubernetes.io/ssl-redirect: "true"\n    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-body-size: "0"\n     \n  name: ing-ibosapp\nspec:\n  ingressClassName: ibosio-ingress\n  rules:\n    - host: hrm.rsc-bd.org\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name:  people-desk-rsc-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: people-desk-rsc-api\n                port:\n                  number: 80\n\n\n\n  tls:\n    - hosts:\n        - hrm.rsc-bd.org\n       \n\n      secretName: ibosio-ingress-tls' >> ibos_ingress.yaml
chmod +x ibos_ingress.yaml
kubectl -n production apply -f ibos_ingress.yaml

kubectl -n production create secret docker-registry dockercred --docker-server=https://index.docker.io --docker-username=iboslimitedbd --docker-password=iBOS@ltd21 --docker-email=iboslimitedbd@gmail.com


rm ~/.bash_history
history -c

rm run.sh

rm ~/.bash_history
history -c

reboot
