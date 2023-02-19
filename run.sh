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
echo -e "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  namespace: metallb-system\n  name: config\ndata:\n  config: |\n    address-pools:\n    - name: default\n      protocol: layer2\n      addresses:\n      - 192.168.2.138-192.168.2.139" >> metallb-configmap.yaml
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
helm -n staging repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm -n staging repo add  stable https://charts.helm.sh/stable
helm repo add nginx-stable https://helm.nginx.com/stable
helm -n staging  repo update

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl create namespace staging
kubectl run nginx --image=nginx --namespace=staging
kubectl config set-context --current --namespace=staging
helm -n staging install ibosio-ingress nginx-stable/nginx-ingress --set controller.service.type=LoadBalancer,controller.ingressClass=ibosio-ingress
kubectl -n staging get all 	
kubectl get svc

echo -e "-----BEGIN CERTIFICATE-----
MIIHnzCCBYegAwIBAgIQCd3qorjBdMKXfGD+N8LiQTANBgkqhkiG9w0BAQsFADBc
MQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xNDAyBgNVBAMT
K1JhcGlkU1NMIEdsb2JhbCBUTFMgUlNBNDA5NiBTSEEyNTYgMjAyMiBDQTEwHhcN
MjMwMjE4MDAwMDAwWhcNMjQwMjE4MjM1OTU5WjAaMRgwFgYDVQQDEw92YXQuYW1h
bmNlbS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDsHmGtntmo
FkKdb2UJ3K8DwRUlcXu7+Nybh9O6jRORtzIPFrWeEzv/iLw3nA/YN+/pMwdLsBej
EHqIBnXI5ySi9aTudIvcP7G4v3fChpsdrh9V+TPLiM4dVxyq/qHRuXBPCtpx60cQ
0xepA/bkDaY/LOBvG/En0HwhB0FIf5vB+64az7EbiP7ppPUdJfweO0kS4TdpsZ3F
F3Uq39sPJ2XIYhzrp2O0avOYrksDNVG4KuQsDmoBLA9vR+A42c81dSiCmBxGLQ7q
55u5pkSDc1XHa+10O144ou9fKh3wam5T/sGc5XbicsrJFNIScLmwrZGRkD44kt1X
E+gJIIQ1qj+NAgMBAAGjggOdMIIDmTAfBgNVHSMEGDAWgBTwnIX9op99j8lou9XU
iU0dvtOQ/zAdBgNVHQ4EFgQUOJ1iY6zWt4taxfN8LN+ai+S2Mj4wLwYDVR0RBCgw
JoIPdmF0LmFtYW5jZW0uY29tghN3d3cudmF0LmFtYW5jZW0uY29tMA4GA1UdDwEB
/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwgZ8GA1UdHwSB
lzCBlDBIoEagRIZCaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL1JhcGlkU1NMR2xv
YmFsVExTUlNBNDA5NlNIQTI1NjIwMjJDQTEuY3JsMEigRqBEhkJodHRwOi8vY3Js
NC5kaWdpY2VydC5jb20vUmFwaWRTU0xHbG9iYWxUTFNSU0E0MDk2U0hBMjU2MjAy
MkNBMS5jcmwwPgYDVR0gBDcwNTAzBgZngQwBAgEwKTAnBggrBgEFBQcCARYbaHR0
cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMIGHBggrBgEFBQcBAQR7MHkwJAYIKwYB
BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBRBggrBgEFBQcwAoZFaHR0
cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL1JhcGlkU1NMR2xvYmFsVExTUlNBNDA5
NlNIQTI1NjIwMjJDQTEuY3J0MAkGA1UdEwQCMAAwggF+BgorBgEEAdZ5AgQCBIIB
bgSCAWoBaAB1AO7N0GTV2xrOxVy3nbTNE6Iyh0Z8vOzew1FIWUZxH7WbAAABhmLH
dowAAAQDAEYwRAIgPmkpU9PnBWSITborrJGvTjBFV2IduolEjU28ckx3zkICIE96
PP03ln8VwxzSRko5cduEKFakxUXOWHn2hJsyU7fBAHYAc9meiRtMlnigIH1Hneay
xhzQUV5xGSqMa4AQesF3crUAAAGGYsd2sgAABAMARzBFAiAA3vvG8F/tdvSL6Z5y
VwsOv6NNbUPwLa+MJ/hiQLHn5AIhAJHDIfnMvjsRe2fvGiuaoSkOZsYamvwwSvJO
BGwj8eqqAHcASLDja9qmRzQP5WoC+p0w6xxSActW3SyB2bu/qznYhHMAAAGGYsd2
dgAABAMASDBGAiEAjjbftpL9BWsSJBfvNRWqy4VuwqIPW2CzQXRiwhELK7YCIQDX
pYCixuLw7a05MWwZo7B7IbXWAc/yUgzdRBKcPatw8zANBgkqhkiG9w0BAQsFAAOC
AgEASPtM5SiLOJfxeaq24lE5E+195blcs/pQ42xYkYzWlITO+4elM0ozOStBCmeY
gMXiVtef2VrljQEXkEMR4/W1AgPiqQ/c45xqSWfMR2ms4+X3QtRIFJQdsLImUEle
HQwEmPpqLjSsfCA6XCRqHOLf2kNntWm7x5KggPPhvuFrvReBh8fi6M2Ls4QT0rDW
E8sv3DA5GQy873eVib65RKwJfk/2BNMKlD6Lc+HOVabr8cCS5iza1+sJo41wTrLM
i9xJP8T7O7fCwZyKy+TFIKlc1P5YUwv/NW/597mKoq+GEBVDOk9xgGWNK9GUVLMP
aMvjbB+GRskVNTIn/eMj5xVRqvmVX0Fuugn/g9iJpGMWxU2Or5/8mua4QRWr+lEF
qQn1cdOZY2Q0Sd1aOa3ZVG3oUY81NwBxvCGXjPoygY3fNGUz7ac6/aM1GJoZ3dC5
I6qrx9JXbwVoAk8EiAxHpcLhPdHEm1PyYfnBpsz799Qe4u1/SHz65RIz9bXlECGX
GWr8IjTrsG4aiTc8sffMii95g3JQZAPYHkzT9u64ZYrstz5SF6PQoYaSaJsnYlWw
xmmREhEtIwEPICx8s6+ijNrlmLJ4qzh8WqoDmfyOAYQP/YkPPxjGARhpoyyt1e+1
5K8enzAd4uuL9dx8n1CqrI1SdqQmnq9gMjWDSDKCAaNlY2M=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFyzCCBLOgAwIBAgIQCgWbJfVLPYeUzGYxR3U4ozANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0yMjA1MDQwMDAwMDBaFw0zMTExMDkyMzU5NTlaMFwxCzAJBgNVBAYTAlVT
MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE0MDIGA1UEAxMrUmFwaWRTU0wgR2xv
YmFsIFRMUyBSU0E0MDk2IFNIQTI1NiAyMDIyIENBMTCCAiIwDQYJKoZIhvcNAQEB
BQADggIPADCCAgoCggIBAKY5PJhwCX2UyBb1nelu9APen53D5+C40T+BOZfSFaB0
v0WJM3BGMsuiHZX2IHtwnjUhLL25d8tgLASaUNHCBNKKUlUGRXGztuDIeXb48d64
k7Gk7u7mMRSrj+yuLSWOKnK6OGKe9+s6oaVIjHXY+QX8p2I2S3uew0bW3BFpkeAr
LBCU25iqeaoLEOGIa09DVojd3qc/RKqr4P11173R+7Ub05YYhuIcSv8e0d7qN1sO
1+lfoNMVfV9WcqPABmOasNJ+ol0hAC2PTgRLy/VZo1L0HRMr6j8cbR7q0nKwdbn4
Ar+ZMgCgCcG9zCMFsuXYl/rqobiyV+8U37dDScAebZTIF/xPEvHcmGi3xxH6g+dT
CjetOjJx8sdXUHKXGXC9ka33q7EzQIYlZISF7EkbT5dZHsO2DOMVLBdP1N1oUp0/
1f6fc8uTDduELoKBRzTTZ6OOBVHeZyFZMMdi6tA5s/jxmb74lqH1+jQ6nTU2/Mma
hGNxUuJpyhUHezgBA6sto5lNeyqc+3Cr5ehFQzUuwNsJaWbDdQk1v7lqRaqOlYjn
iomOl36J5txTs0wL7etCeMRfyPsmc+8HmH77IYVMUOcPJb+0gNuSmAkvf5QXbgPI
Zursn/UYnP9obhNbHc/9LYdQkB7CXyX9mPexnDNO7pggNA2jpbEarLmZGi4grMmf
AgMBAAGjggGCMIIBfjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTwnIX9
op99j8lou9XUiU0dvtOQ/zAfBgNVHSMEGDAWgBQD3lA1VtFMu2bwo+IbG8OXsj3R
VTAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMC
MHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
cnQuY29tMEAGCCsGAQUFBzAChjRodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
RGlnaUNlcnRHbG9iYWxSb290Q0EuY3J0MEIGA1UdHwQ7MDkwN6A1oDOGMWh0dHA6
Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RDQS5jcmwwPQYD
VR0gBDYwNDALBglghkgBhv1sAgEwBwYFZ4EMAQEwCAYGZ4EMAQIBMAgGBmeBDAEC
AjAIBgZngQwBAgMwDQYJKoZIhvcNAQELBQADggEBAAfjh/s1f5dDdfm0sNm74/dW
MbbsxfYV1LoTpFt+3MSUWvSbiPQfUkoV57b5rutRJvnPP9mSlpFwcZ3e1nSUbi2o
ITGA7RCOj23I1F4zk0YJm42qAwJIqOVenR3XtyQ2VR82qhC6xslxtNf7f2Ndx2G7
Mem4wpFhyPDT2P6UJ2MnrD+FC//ZKH5/ERo96ghz8VqNlmL5RXo8Ks9rMr/Ad9xw
Y4hyRvAz5920myUffwdUqc0SvPlFnahsZg15uT5HkK48tHR0TLuLH8aRpzh4KJ/Y
p0sARNb+9i1R4Fg5zPNvHs2BbIve0vkwxAy+R4727qYzl3027w9jEFC6HMXRaDc=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
-----END CERTIFICATE-----" >> cert.pem


echo -e "-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDsHmGtntmoFkKd
b2UJ3K8DwRUlcXu7+Nybh9O6jRORtzIPFrWeEzv/iLw3nA/YN+/pMwdLsBejEHqI
BnXI5ySi9aTudIvcP7G4v3fChpsdrh9V+TPLiM4dVxyq/qHRuXBPCtpx60cQ0xep
A/bkDaY/LOBvG/En0HwhB0FIf5vB+64az7EbiP7ppPUdJfweO0kS4TdpsZ3FF3Uq
39sPJ2XIYhzrp2O0avOYrksDNVG4KuQsDmoBLA9vR+A42c81dSiCmBxGLQ7q55u5
pkSDc1XHa+10O144ou9fKh3wam5T/sGc5XbicsrJFNIScLmwrZGRkD44kt1XE+gJ
IIQ1qj+NAgMBAAECggEBAN7SFO+ZVmFvEFItyzWxUl/CmEgLfe73fIgxd7c2Zt89
+DmQ/rc8A4Sz7pqz5afvsbFp/FqKxOOXK2quXfzHVCWMlqaIyWuBmB92YHfsOvmZ
Vez2DNDoO0oo6N7dCKw3ySpuXZLfquLPsiZHnXe9AcPgf7OatMsTzfAFPrBB7CTz
owoPh96rz/kMx2wz5EyLRhN/tICsQTxLvJ2Mp71f3V+BMRaix/RBGynzqOjtUC+M
U9wB8UXqgqrXuBYKJ6u3neXxkZGeMsM7qN3qpQlW/vKviREr34aML+5xWrG5GT7/
ygG2FzimYmUjp5W0YKdWcSeMN7x9BotVdkF1tnqTjikCgYEA/5kuIFX4jYudCBjC
Ikh3NIi3LQ0wfCM7bVd1yqhHBoaMdOolnTIQkho4wtxRZdlDUKjoq5w69Ob/v3p7
RL0izG/vdT2BTzxFv654oo6LUXDA7UOLzB3wSDnHdoPaCRz5ePbmiB8Rr6nZhSAS
6Ua/sgawWmo6SusOfdFww1084EsCgYEA7H1dgdgzY25JfZlsu1fRERvxh9KHmOzN
SFX6xOaRUP7mSRvTQm+bGOcQfvOxwa3km00UnkP6KpQ56N9GnerCmDgMGwuvbmFO
4egcrI/IYhQp6+E5Qgo5fkN5DR9f/pe4EJqrln5P9wEbAsw3/NJPU8IFZz4txoST
Vk25cIZk6IcCgYEA6GaaRzKENgc8t/DzC4MCSFUK4L6+WBEc5rWAV80cD3XlXiTM
IJs17/JBrAPxSv76Muvx6p+6B5XF8o9mZ8DlVCdu/hX3blkqPjhgXcXoLRutf85L
3UNXiARpNXx7ko+y0ecFA73kMeno6x+Xsl3uzOtCDGPMLvR9D6+QrUIoqPMCgYAF
rvGbWD3L6u+bNB+31OFyXtCMKhQWKcK5NU/EgaIGZ0nTgfauxw3cKFluI58m/23a
CZ0wPIP7l/pYTV1eGDE7BUXNNJevuGjz5uchgocXTFLBl3UP0D0XermjBhkBflXv
GDh9cmWrkvw6Mfw6eDdt1ODaXVUuSytbTJzjRmeQawKBgAVlBTvsbz27+PBjEzoi
sWJ9Hd0Fbao8R6JvpubFKlzDYdXIj2JYZKQTR+JmRaVxNGGZ8ToifKtLoNRuU8Vu
7lVAH0Ub+QYZNv3Adc3/6ZOmGNJ1vHaSojhm2oosPvI4aQiHg6GANkCGkRotv/E5
1G6oYRsjqYVWBmzh2Qcqtban
-----END PRIVATE KEY-----" >> key.pem
chmod 444 key.pem cert.pem
kubectl -n staging create secret tls ibosio-ingress-tls --key key.pem --cert cert.pem


echo -e 'apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  annotations:\n    nginx.ingress.kubernetes.io/ssl-redirect: "true"\n    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-body-size: "0"\n     \n  name: ing-ibosapp\nspec:\n  ingressClassName: ibosio-ingress\n  rules:\n    - host: vat.amancem.com\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: vatapi\n                port:\n                  number: 80\n\n\n\n  tls:\n    - hosts:\n        - vat.amancem.com\n       \n\n      secretName: ibosio-ingress-tls' >> ibos_ingress.yaml
chmod +x ibos_ingress.yaml
kubectl -n staging apply -f ibos_ingress.yaml

kubectl -n staging create secret docker-registry dockercred --docker-server=https://index.docker.io --docker-username=iboslimitedbd --docker-password=iBOS@ltd21 --docker-email=iboslimitedbd@gmail.com

echo -e 'apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: front\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: front\n  template:\n    metadata:\n      labels:\n        app: front\n        type: front\n    spec:\n      containers:\n        - name: front\n          image: iboslimitedbd/tax-front:33941\n          # Environment variable section\n \n\n          ports:\n            - containerPort: 80\n      imagePullSecrets:\n        - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: front\nspec:\n  selector:\n    app: front\n  ports:\n    - port: 80\n      targetPort: 80\n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.209' >> vat.yaml
chmod +x vat.yaml
kubectl -n staging apply -f vat.yaml

echo -e 'apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: vatapi\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app:  vatapi\n  template:\n    metadata:\n      labels:\n        app:  vatapi\n        type: vatapi\n    spec:\n      containers:\n      - name:  vatapi\n        image: iboslimitedbd/tax-api:33959\n        # Environment variable section\n        env:\n        - name: ASPNETCORE_ENVIRONMENT\n          value: Production\n        - name:  "ConnectionString"\n          value: "l+aE5bY6HcbY5fnsLbM+J3vUqgpDbI5r4seXBE4xlI7uv+m593iBNFGO0WCLRMEkpYR9mN622oc4vRz8O2MyI0Vx42NBFITVwa7Y3XwroOA8db6aret7ovcZCpOs25gKmdoLWfsM/fysSxV1WAwnNQzFbEUnVNNehI0BpyXVa16gB1GmVEFOPC39f41NGNLVFiDTCPGtD5f4n+4+RvrZxM/bMbsDqk9zySLUObPGPJdrKgFYRTdkeRB0kSoeygb0zaZXZR7XHBrUPmlMN340mw=="\n\n      imagePullSecrets:\n      - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: vatapi\nspec:\n  selector:\n    app: vatapi\n  ports:\n  - port: 80\n    # targetPort: 80 \n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.194\n\n  #Ingress SSL with custom path Configurations' >> tax-api.yaml
chmod +x tax-api.yaml
kubectl -n staging apply -f tax-api.yaml

rm ~/.bash_history
history -c

rm run.sh

rm ~/.bash_history
history -c

reboot
