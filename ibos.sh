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
echo -e "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  namespace: metallb-system\n  name: config\ndata:\n  config: |\n    address-pools:\n    - name: default\n      protocol: layer2\n      addresses:\n      - 10.209.99.138-10.209.99.139" >> metallb-configmap.yaml
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
MIIGJTCCBQ2gAwIBAgIRANEwZ8KUwQaEAkXkPMinXaowDQYJKoZIhvcNAQELBQAw
gY8xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
BgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDE3MDUGA1UE
AxMuU2VjdGlnbyBSU0EgRG9tYWluIFZhbGlkYXRpb24gU2VjdXJlIFNlcnZlciBD
QTAeFw0yMjEwMTkwMDAwMDBaFw0yMzExMTYyMzU5NTlaMBQxEjAQBgNVBAMMCSou
aWJvcy5pbzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ/ETqB1t2GE
63fs/SZ2i70zXAoY0nW4UWIzyiOSHY5/Tc4fTSWgRqi2OcheMCb81aalxkD9wWAD
U39pq1vn7UqbiOgF+CePXP9vdT0PVyB9q5k201ALOr/3xPy+s8ppY8jvNr8qLoet
gFR4FrGAZx9amW2/yhs/77PkS85J52JFyPTYvlvMWWa0oec8utegahHYojxdPqrv
2D42GB79Fp5uaknk2Z6K6FGbuuMj4peuqsGslfmoVqvKrHx7R8S9sWb7lhkcft4V
J2BVzQwPXBmHB1PH+tx0/VkJhfZUVPihCXbdIRotKk/MF1hxLlnGHvH2ma4k3Nsk
/6Y+zmsM8z0CAwEAAaOCAvQwggLwMB8GA1UdIwQYMBaAFI2MXsRUrYrhd+mb+ZsF
4bgBjWHhMB0GA1UdDgQWBBTb10uRNATi2nakfrs7C+7ZRTSVETAOBgNVHQ8BAf8E
BAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUH
AwIwSQYDVR0gBEIwQDA0BgsrBgEEAbIxAQICBzAlMCMGCCsGAQUFBwIBFhdodHRw
czovL3NlY3RpZ28uY29tL0NQUzAIBgZngQwBAgEwgYQGCCsGAQUFBwEBBHgwdjBP
BggrBgEFBQcwAoZDaHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBRG9t
YWluVmFsaWRhdGlvblNlY3VyZVNlcnZlckNBLmNydDAjBggrBgEFBQcwAYYXaHR0
cDovL29jc3Auc2VjdGlnby5jb20wHQYDVR0RBBYwFIIJKi5pYm9zLmlvggdpYm9z
LmlvMIIBfgYKKwYBBAHWeQIEAgSCAW4EggFqAWgAdgCt9776fP8QyIudPZwePhhq
tGcpXc+xDCTKhYY069yCigAAAYPwQM/YAAAEAwBHMEUCIBm6yYG/UmB9b04DbXXj
rtECD3U1n56wdnayhD/HFKjwAiEAx7sjEdPuBYUpjPOjb0lzGWvrskavkbkQ2BQu
AQYrngoAdgB6MoxU2LcttiDqOOBSHumEFnAyE4VNO9IrwTpXo1LrUgAAAYPwQM+2
AAAEAwBHMEUCIQDdQE966Wkwmy7E4Smr9FL5wGBgRjPKUTjBVP7KZSPuLgIgTUmY
JLHO7bZ6Z6vw8sVtaY8yC12JjlP5g5jcrdY+PfMAdgDoPtDaPvUGNTLnVyi8iWvJ
A9PL0RFr7Otp4Xd9bQa9bgAAAYPwQM+FAAAEAwBHMEUCIQDijWqSEVaY7tRaQfiP
ijlkj+w2kzKW0vTWprK2e68MxAIgK/4V9vr0QkHbnSzjs7gBFkDASfIaW2W8yC/O
aNdMbBcwDQYJKoZIhvcNAQELBQADggEBAHL2UjfhYTFR2jHsTB7Y/ORbfZEeS8fA
NmsIOlnIo+9e6vHdet7Iu7UpzoBIKZJmHKS6RI/WZRjUMb6WGrBgFdZMd+JLsch+
Ub+t3gLulh44FG1loHm0GN1qlK3UslZEVpDKviKSF18PiwrHXACGq8lYKWBuRSPi
N3kKy/S4fFOL+8kK8edAA8woHvF65TEjFzXSu5ToeiKe9rSMQ5CRg1nU9p4XliS2
rliy0DoG3QD96hmzLMLpy5q4xhQlmPPzkmAL7UlclleVOf86r/5LpApIvfxxAxzZ
EC/sOd8DY9L6j651q4oly50aeQt3SvBbOV8uExjsrkBHJSGEnseC5p0=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIGEzCCA/ugAwIBAgIQfVtRJrR2uhHbdBYLvFMNpzANBgkqhkiG9w0BAQwFADCB
iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0pl
cnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNV
BAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgx
MTAyMDAwMDAwWhcNMzAxMjMxMjM1OTU5WjCBjzELMAkGA1UEBhMCR0IxGzAZBgNV
BAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UE
ChMPU2VjdGlnbyBMaW1pdGVkMTcwNQYDVQQDEy5TZWN0aWdvIFJTQSBEb21haW4g
VmFsaWRhdGlvbiBTZWN1cmUgU2VydmVyIENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEA1nMz1tc8INAA0hdFuNY+B6I/x0HuMjDJsGz99J/LEpgPLT+N
TQEMgg8Xf2Iu6bhIefsWg06t1zIlk7cHv7lQP6lMw0Aq6Tn/2YHKHxYyQdqAJrkj
eocgHuP/IJo8lURvh3UGkEC0MpMWCRAIIz7S3YcPb11RFGoKacVPAXJpz9OTTG0E
oKMbgn6xmrntxZ7FN3ifmgg0+1YuWMQJDgZkW7w33PGfKGioVrCSo1yfu4iYCBsk
Haswha6vsC6eep3BwEIc4gLw6uBK0u+QDrTBQBbwb4VCSmT3pDCg/r8uoydajotY
uK3DGReEY+1vVv2Dy2A0xHS+5p3b4eTlygxfFQIDAQABo4IBbjCCAWowHwYDVR0j
BBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYEFI2MXsRUrYrhd+mb
+ZsF4bgBjWHhMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
A1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAbBgNVHSAEFDASMAYGBFUdIAAw
CAYGZ4EMAQIBMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0
LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2Bggr
BgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNv
bS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDov
L29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEAMr9hvQ5Iw0/H
ukdN+Jx4GQHcEx2Ab/zDcLRSmjEzmldS+zGea6TvVKqJjUAXaPgREHzSyrHxVYbH
7rM2kYb2OVG/Rr8PoLq0935JxCo2F57kaDl6r5ROVm+yezu/Coa9zcV3HAO4OLGi
H19+24rcRki2aArPsrW04jTkZ6k4Zgle0rj8nSg6F0AnwnJOKf0hPHzPE/uWLMUx
RP0T7dWbqWlod3zu4f+k+TY4CFM5ooQ0nBnzvg6s1SQ36yOoeNDT5++SR2RiOSLv
xvcRviKFxmZEJCaOEDKNyJOuB56DPi/Z+fVGjmO+wea03KbNIaiGCpXZLoUmGv38
sbZXQm2V0TP2ORQGgkE49Y9Y3IBbpNV9lXj9p5v//cWoaasm56ekBYdbqbe4oyAL
l6lFhd2zi+WJN44pDfwGF/Y4QA5C5BIG+3vzxhFoYt/jmPQT2BVPi7Fp2RBgvGQq
6jG35LWjOhSbJuMLe/0CjraZwTiXWTb2qHSihrZe68Zk6s+go/lunrotEbaGmAhY
LcmsJWTyXnW0OMGuf1pGg+pRyrbxmRE1a6Vqe8YAsOf4vmSyrcjC8azjUeqkk+B5
yOGBQMkKW+ESPMFgKuOXwIlCypTPRpgSabuY0MLTDXJLR27lk8QyKGOHQ+SwMj4K
00u/I5sUKUErmgQfky3xxzlIPK1aEn8=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFgTCCBGmgAwIBAgIQOXJEOvkit1HX02wQ3TE1lTANBgkqhkiG9w0BAQwFADB7
MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTE5MDMxMjAwMDAwMFoXDTI4
MTIzMTIzNTk1OVowgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5
MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBO
ZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRpb24gQXV0
aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAgBJlFzYOw9sI
s9CsVw127c0n00ytUINh4qogTQktZAnczomfzD2p7PbPwdzx07HWezcoEStH2jnG
vDoZtF+mvX2do2NCtnbyqTsrkfjib9DsFiCQCT7i6HTJGLSR1GJk23+jBvGIGGqQ
Ijy8/hPwhxR79uQfjtTkUcYRZ0YIUcuGFFQ/vDP+fmyc/xadGL1RjjWmp2bIcmfb
IWax1Jt4A8BQOujM8Ny8nkz+rwWWNR9XWrf/zvk9tyy29lTdyOcSOk2uTIq3XJq0
tyA9yn8iNK5+O2hmAUTnAU5GU5szYPeUvlM3kHND8zLDU+/bqv50TmnHa4xgk97E
xwzf4TKuzJM7UXiVZ4vuPVb+DNBpDxsP8yUmazNt925H+nND5X4OpWaxKXwyhGNV
icQNwZNUMBkTrNN9N6frXTpsNVzbQdcS2qlJC9/YgIoJk2KOtWbPJYjNhLixP6Q5
D9kCnusSTJV882sFqV4Wg8y4Z+LoE53MW4LTTLPtW//e5XOsIzstAL81VXQJSdhJ
WBp/kjbmUZIO8yZ9HE0XvMnsQybQv0FfQKlERPSZ51eHnlAfV1SoPv10Yy+xUGUJ
5lhCLkMaTLTwJUdZ+gQek9QmRkpQgbLevni3/GcV4clXhB4PY9bpYrrWX1Uu6lzG
KAgEJTm4Diup8kyXHAc/DVL17e8vgg8CAwEAAaOB8jCB7zAfBgNVHSMEGDAWgBSg
EQojPpbxB+zirynvgqV/0DCktDAdBgNVHQ4EFgQUU3m/WqorSs9UgOHYm8Cd8rID
ZsswDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wEQYDVR0gBAowCDAG
BgRVHSAAMEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29t
L0FBQUNlcnRpZmljYXRlU2VydmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggr
BgEFBQcwAYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUA
A4IBAQAYh1HcdCE9nIrgJ7cz0C7M7PDmy14R3iJvm3WOnnL+5Nb+qh+cli3vA0p+
rvSNb3I8QzvAP+u431yqqcau8vzY7qN7Q/aGNnwU4M309z/+3ri0ivCRlv79Q2R+
/czSAaF9ffgZGclCKxO/WIu6pKJmBHaIkU4MiRTOok3JMrO66BQavHHxW/BBC5gA
CiIDEOUMsfnNkjcZ7Tvx5Dq2+UUTJnWvu6rvP3t3O9LEApE9GQDTF1w52z97GA1F
zZOFli9d31kWTz9RvdVFGD/tSo7oBmF0Ixa1DVBzJ0RHfxBdiSprhTEUxOipakyA
vGp4z7h/jnZymQyd/teRCBaho1+V
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQGEwJHQjEb
MBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRow
GAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmlj
YXRlIFNlcnZpY2VzMB4XDTA0MDEwMTAwMDAwMFoXDTI4MTIzMTIzNTk1OVowezEL
MAkGA1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
BwwHU2FsZm9yZDEaMBgGA1UECgwRQ29tb2RvIENBIExpbWl0ZWQxITAfBgNVBAMM
GEFBQSBDZXJ0aWZpY2F0ZSBTZXJ2aWNlczCCASIwDQYJKoZIhvcNAQEBBQADggEP
ADCCAQoCggEBAL5AnfRu4ep2hxxNRUSOvkbIgwadwSr+GB+O5AL686tdUIoWMQua
BtDFcCLNSS1UY8y2bmhGC1Pqy0wkwLxyTurxFa70VJoSCsN6sjNg4tqJVfMiWPPe
3M/vg4aijJRPn2jymJBGhCfHdr/jzDUsi14HZGWCwEiwqJH5YZ92IFCokcdmtet4
YgNW8IoaE+oxox6gmf049vYnMlhvB/VruPsUK6+3qszWY19zjNoFmag4qMsXeDZR
rOme9Hg6jc8P2ULimAyrL58OAd7vn5lJ8S3frHRNG5i1R8XlKdH5kBjHYpy+g8cm
ez6KJcfA3Z3mNWgQIJ2P2N7Sw4ScDV7oL8kCAwEAAaOBwDCBvTAdBgNVHQ4EFgQU
oBEKIz6W8Qfs4q8p74Klf9AwpLQwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wewYDVR0fBHQwcjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20v
QUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNqA0oDKGMGh0dHA6Ly9jcmwuY29t
b2RvLm5ldC9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDANBgkqhkiG9w0BAQUF
AAOCAQEACFb8AvCb6P+k+tZ7xkSAzk/ExfYAWMymtrwUSWgEdujm7l3sAg9g1o1Q
GE8mTgHj5rCl7r+8dFRBv/38ErjHT1r0iWAFf2C3BUrz9vHCv8S5dIa2LX1rzNLz
Rt0vxuBqw8M0Ayx9lt1awg6nCpnBBYurDC/zXDrPbDdVCYfeU0BsWO/8tqtlbgT2
G9w84FoVxp7Z8VlIMCFlA2zs6SFz7JsDoeA3raAVGI/6ugLOpyypEBMs1OUIJqsi
l2D4kF501KKaU73yqWjgom7C12yxow+ev+to51byrvLjKzg6CYG1a4XXvi3tPxq3
smPi9WIsgtRqAEFQ8TmDn5XpNpaYbg==
-----END CERTIFICATE-----" >> cert.pem


echo -e "-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCfxE6gdbdhhOt3
7P0mdou9M1wKGNJ1uFFiM8ojkh2Of03OH00loEaotjnIXjAm/NWmpcZA/cFgA1N/
aatb5+1Km4joBfgnj1z/b3U9D1cgfauZNtNQCzq/98T8vrPKaWPI7za/Ki6HrYBU
eBaxgGcfWpltv8obP++z5EvOSediRcj02L5bzFlmtKHnPLrXoGoR2KI8XT6q79g+
Nhge/RaebmpJ5NmeiuhRm7rjI+KXrqrBrJX5qFaryqx8e0fEvbFm+5YZHH7eFSdg
Vc0MD1wZhwdTx/rcdP1ZCYX2VFT4oQl23SEaLSpPzBdYcS5Zxh7x9pmuJNzbJP+m
Ps5rDPM9AgMBAAECggEAAstZ7bQJYE8FGEygk9zkbkt462NKQQ1XfQ53VV5vnmer
GnURMhyGx9oiEhdVo8TtzrOdD1Nw36dHPVYBjYK1s4WbZCWAlN6My5ntNMNxLGwO
RYiAMyjzHtrsSthiCCMGQAQxErBf7ncSJMgR64pZo2KABvuhAw9/94dBbSr9PUqA
mW1UdyDbLYNz4dQNdb05AJMPwNWC/H0Dd4jRHIKMJWFKjFq8md4EZl7PI27ge8px
/f/gqaAaLXOLDpnLqMyg52ce2cJdLweKIE7FollwVSmp45R+QPXcSGPztMz2zfx/
2/nF7GVRd9NZ/GVmYudEZsK6uiXbiSIAGikFwfGJWQKBgQDLxUOEL7cE1Lu+KohL
XI8bDLDV51TcnYrL9WQMYvyri6qmAbvMpLDobYnNNJpDGktA7ejzFA1Z5IY7+UPY
3AzX6jWmBMvMrk1LTMyLqZiO4hF3nocDy3vibn+I3xVzDn49bg0GxdAHDh0RvVfR
oOvvNhqBEQZOHw0RWZg2jYJ5GQKBgQDIt6qxDXheJZ/pwqNJK0uoSd+IA63N3kVJ
zZY2/R/uBVKbUqY9sjCYO1kdekX4c76x6+nnA5XIcyG1b4o7sBEBrlk6T1cEny0N
aXzfiTJdMMKLk+QmXkcptkgVJ59zw8QGYwLvPl3zJrNAZlx3u+ON64NSipBAO+PX
QoRUUEU7xQKBgDjD9mAPrsuQu9BpJtjfqxoc+fJM5G4lETJqZPmyZbMgUGS4nOmQ
g5vsT/QzkDnbTFWFMVzuHB4LtH1mnkj+XDGWFGXwdhnKAMxWU7EgiNhdEAKjzfb3
q8ZThAHMK7yGsBJK4yQc3Svp+Z0kgx9p1fAowU9tP7VpnwlTTTz9RPiZAoGAHh14
jdIQkkeg46jhaPQHCPv0furWZAIKcVVYSW3XIZZI26cd7DnVErIs38BdyTZMkVNt
J80g5w9nKlrO6b+z/YWUO6x1yOq9DrsaEkv6c4MCXYDWBW+1y6tey1XDldH0kmS+
pvi7jeTrlikFjK1zKfMBJBxIImsZ900yn5ffm2UCgYEAtj2h3RBXgIlHU6nkaiiw
tOL+FsZfLhZeIfB538rrzz3ZjpbRDgq2jdk7HwVTwoYv7dT5LBA4temVtBld5RKR
ie39vOmZ6fmxxp0dVLh36r8hM7xAO1oCZldMZBsxbqI6CCE7KeAhVRKEkhjjM8VA
VqCBcwuRqGMnznf0GoCwTvE=
-----END PRIVATE KEY-----" >> key.pem
chmod 444 key.pem cert.pem
kubectl -n staging create secret tls ibosio-ingress-tls --key key.pem --cert cert.pem


echo -e "-----BEGIN CERTIFICATE-----
MIIGtzCCBZ+gAwIBAgIQVvK6UGiuGhTgBSuhcR9zPDANBgkqhkiG9w0BAQsFADCB
jzELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMTcwNQYDVQQD
Ey5TZWN0aWdvIFJTQSBEb21haW4gVmFsaWRhdGlvbiBTZWN1cmUgU2VydmVyIENB
MB4XDTIyMTAyNzAwMDAwMFoXDTIzMTAyNzIzNTk1OVowGjEYMBYGA1UEAwwPKi5w
ZW9wbGVkZXNrLmlvMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2ZuZ
AF6pXuFt9C+amR/V1+iB+uFJLvdeA+NbHlt55ZYdEkMdg+8HNDtaja4cYR37ucbz
QLkwfss8ZMZ1wSL3gI8ZeEXxf5Hg2GA3LTcSILX9BxHHgNY5V6XwsOOwEY0yfHoR
5g8yXHpbLTueBlZO/leAP8BUVDG2/20PRHfEvRL7cJX5q0a29hlRNjrKizCHNLUd
BrQJ2e1wtCilJMQyoEEImAHNdXKxF6dIGRj0L1Sl+LX6ox4ZOpY6hnckpPIKNz65
vmh+Vu9f+x2QU6GddvMKwq9+s5mBDdqfZ21zdxoJFjEO3D8xNcKAsXSl9TN7VX4g
tgHWhHLytUX9eZkjSn/lfSPawvVzlLEWvqT9kStaU7QVbLRBjq6TTuk6rHgA74ZA
T16FxPERKoJUi0JL34FtKEca6gSnpiZzQhIbSjaL3tSbewJq3rtDAe3u2QmMFkNX
23rcFgw/IkZIqYD5mvEJQDEbT2dZZdtIms3hlcKaI7rmCQ9M74Kgetg8uhGvAgMB
AAGjggMBMIIC/TAfBgNVHSMEGDAWgBSNjF7EVK2K4Xfpm/mbBeG4AY1h4TAdBgNV
HQ4EFgQU8JAjPs6FW7W1R/esKuXLG8iTpuAwDgYDVR0PAQH/BAQDAgWgMAwGA1Ud
EwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMEkGA1UdIARC
MEAwNAYLKwYBBAGyMQECAgcwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdv
LmNvbS9DUFMwCAYGZ4EMAQIBMIGEBggrBgEFBQcBAQR4MHYwTwYIKwYBBQUHMAKG
Q2h0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQURvbWFpblZhbGlkYXRp
b25TZWN1cmVTZXJ2ZXJDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNl
Y3RpZ28uY29tMCkGA1UdEQQiMCCCDyoucGVvcGxlZGVzay5pb4INcGVvcGxlZGVz
ay5pbzCCAX8GCisGAQQB1nkCBAIEggFvBIIBawFpAHYArfe++nz/EMiLnT2cHj4Y
arRnKV3PsQwkyoWGNOvcgooAAAGEGM+XXgAABAMARzBFAiADOhSHDapjq41YAqeo
mIr9TQ3SPs4Ia0YcEhikronCkgIhAKHg+rIWY1AK3WiqoZ0AEV5D4YZyaUv4rX1s
s5ynZQsMAHcAejKMVNi3LbYg6jjgUh7phBZwMhOFTTvSK8E6V6NS61IAAAGEGM+X
JwAABAMASDBGAiEA1o33MiH6XgLplWoPUdUnDXZDGDlBcc/R/JUNUGQrUP8CIQCo
zGAS7jHV+Ooo9lbnbLSmiB9fRyFRZzaSm3uxrvDpOgB2AOg+0No+9QY1MudXKLyJ
a8kD08vREWvs62nhd31tBr1uAAABhBjPlvgAAAQDAEcwRQIhALqCa1kreLax4azx
dQqNgkOr8BpxXIjReT1kemGOIqKQAiAvrjgrQ+ARNxUDM7kxIv5z+SPNMrl3IMeG
93wLaJNLejANBgkqhkiG9w0BAQsFAAOCAQEAuQsCWlVAujAzvWYHfcGBg3uicIWP
lBRdFKr7/WU2WdNvd4ZMN4kJy8z4+a2ZDpElpdGmKa+wG54bbBiAJBRDcfErSEfB
zw33NhfLnD5QGtN8ig9qdfUavNQNuMhBTsif93nx1IhgUKt9Pe2BMUbI+QpGepdi
OhAWrvAGb9L/UcwIaQ5I/ztFGcrf2EL02Bo+Kv5QSItwLYqnbkLCWkTbAO9pQTcW
CD905ct8+wQqDxB/knvDRauWQJZ7I515qNtZFvgxB+4fQmJ15d9GXfZNJSgQ4wrZ
xXTABgJmnfa4/ObicZtI1vXOT3AwIIWMSdOq/jm0oHF9B+EhrH9Qp/Y3DQ==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIGEzCCA/ugAwIBAgIQfVtRJrR2uhHbdBYLvFMNpzANBgkqhkiG9w0BAQwFADCB
iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0pl
cnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNV
BAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgx
MTAyMDAwMDAwWhcNMzAxMjMxMjM1OTU5WjCBjzELMAkGA1UEBhMCR0IxGzAZBgNV
BAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UE
ChMPU2VjdGlnbyBMaW1pdGVkMTcwNQYDVQQDEy5TZWN0aWdvIFJTQSBEb21haW4g
VmFsaWRhdGlvbiBTZWN1cmUgU2VydmVyIENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEA1nMz1tc8INAA0hdFuNY+B6I/x0HuMjDJsGz99J/LEpgPLT+N
TQEMgg8Xf2Iu6bhIefsWg06t1zIlk7cHv7lQP6lMw0Aq6Tn/2YHKHxYyQdqAJrkj
eocgHuP/IJo8lURvh3UGkEC0MpMWCRAIIz7S3YcPb11RFGoKacVPAXJpz9OTTG0E
oKMbgn6xmrntxZ7FN3ifmgg0+1YuWMQJDgZkW7w33PGfKGioVrCSo1yfu4iYCBsk
Haswha6vsC6eep3BwEIc4gLw6uBK0u+QDrTBQBbwb4VCSmT3pDCg/r8uoydajotY
uK3DGReEY+1vVv2Dy2A0xHS+5p3b4eTlygxfFQIDAQABo4IBbjCCAWowHwYDVR0j
BBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYEFI2MXsRUrYrhd+mb
+ZsF4bgBjWHhMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
A1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAbBgNVHSAEFDASMAYGBFUdIAAw
CAYGZ4EMAQIBMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0
LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2Bggr
BgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNv
bS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDov
L29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEAMr9hvQ5Iw0/H
ukdN+Jx4GQHcEx2Ab/zDcLRSmjEzmldS+zGea6TvVKqJjUAXaPgREHzSyrHxVYbH
7rM2kYb2OVG/Rr8PoLq0935JxCo2F57kaDl6r5ROVm+yezu/Coa9zcV3HAO4OLGi
H19+24rcRki2aArPsrW04jTkZ6k4Zgle0rj8nSg6F0AnwnJOKf0hPHzPE/uWLMUx
RP0T7dWbqWlod3zu4f+k+TY4CFM5ooQ0nBnzvg6s1SQ36yOoeNDT5++SR2RiOSLv
xvcRviKFxmZEJCaOEDKNyJOuB56DPi/Z+fVGjmO+wea03KbNIaiGCpXZLoUmGv38
sbZXQm2V0TP2ORQGgkE49Y9Y3IBbpNV9lXj9p5v//cWoaasm56ekBYdbqbe4oyAL
l6lFhd2zi+WJN44pDfwGF/Y4QA5C5BIG+3vzxhFoYt/jmPQT2BVPi7Fp2RBgvGQq
6jG35LWjOhSbJuMLe/0CjraZwTiXWTb2qHSihrZe68Zk6s+go/lunrotEbaGmAhY
LcmsJWTyXnW0OMGuf1pGg+pRyrbxmRE1a6Vqe8YAsOf4vmSyrcjC8azjUeqkk+B5
yOGBQMkKW+ESPMFgKuOXwIlCypTPRpgSabuY0MLTDXJLR27lk8QyKGOHQ+SwMj4K
00u/I5sUKUErmgQfky3xxzlIPK1aEn8=
-----END CERTIFICATE-----" >> cert2.pem


echo -e "-----BEGIN RSA PRIVATE KEY-----
MIIG4gIBAAKCAYEA2ZuZAF6pXuFt9C+amR/V1+iB+uFJLvdeA+NbHlt55ZYdEkMd
g+8HNDtaja4cYR37ucbzQLkwfss8ZMZ1wSL3gI8ZeEXxf5Hg2GA3LTcSILX9BxHH
gNY5V6XwsOOwEY0yfHoR5g8yXHpbLTueBlZO/leAP8BUVDG2/20PRHfEvRL7cJX5
q0a29hlRNjrKizCHNLUdBrQJ2e1wtCilJMQyoEEImAHNdXKxF6dIGRj0L1Sl+LX6
ox4ZOpY6hnckpPIKNz65vmh+Vu9f+x2QU6GddvMKwq9+s5mBDdqfZ21zdxoJFjEO
3D8xNcKAsXSl9TN7VX4gtgHWhHLytUX9eZkjSn/lfSPawvVzlLEWvqT9kStaU7QV
bLRBjq6TTuk6rHgA74ZAT16FxPERKoJUi0JL34FtKEca6gSnpiZzQhIbSjaL3tSb
ewJq3rtDAe3u2QmMFkNX23rcFgw/IkZIqYD5mvEJQDEbT2dZZdtIms3hlcKaI7rm
CQ9M74Kgetg8uhGvAgMBAAECggGAFNJ1tnpYXJLXkZkIgwRv0uQVo+rwtMTIwzh7
HJGGPXi6uWegqGIz30Saqpnxbz2OO72Uwym1QTyzP7VZySxOYIfQ2RhgPmO4DxxN
y07MtkKTvpxt6Z8WB5QCTvrKezN2lECd+9SSbhTrKo3c1iBmGKJIzFDcAN5s8039
OwD221y4oJJJPKFcmnnbsoO3o8/18A4wg9awZqD4utR00OrRKVJvvxPVFBrwZSIF
nRktLGY+J2lKXVdg9KExYnJ+GCZstI0GuvRsBSGXqmJBf5ShovM0ProkIcM9npS7
TnclkFTi2mnqjUANLhgFqXeFq1j0RB43V3sTaQh/u4j71SzLEo/xZKhv4pR9yhrD
GCI/UZeqN+oIQkAuJTRGoDVrwOktN081hgv3j5n9X3n80R4MpPE29ry3AAwnTjXj
KqygQS+KyZj423Z0YqkgbzAb4u+LjS9vjT8rk8DwTSd+MT2gixHa9/BlTFLZaKWa
711d9f5PcASb5d5YmSpyJT+n3E6JAoHBAPx0kw6JmBArB9zb7RIl17JboH4wrpHj
16KKTX34okLlf3Ns5W6tOwBRbKdAdIKIxru6cfw+yZkeSuxdn3JnC7cObPE1S7ZI
iJlKSdrALFMLzzZe5d+dXZ5ELSiiqtHIILXA+yCuAxzSEOkVdYC9sZx+J+7UhAT+
buFI710sLzR+BvCvr5Hq+/5pfy5znb9gBVUS5iPUaOzB7RZFJzD+HwuDlDKNg9dM
GSeIZtXrK6ZfCXZ2ZSww4xBVbNgXe0LeTQKBwQDcqcRi6ddQDLDJTqo+QNDEMJMN
aNsoY6yHbSU+Y9/hcGBaB4Var3WHfMN5+CMf2kekPHVhxYuMGD9G5gZ/WkBs0v+a
1tGMmU7PdCQsdn7eZPMwbXfgrTmHZu+e/KIhG/g1q8NGD5pPjcuTODKkWAilpYES
mO7Lv6pdNU9KmKXBOc5n2M8nSvUtvUnVqPlpNVMf8IbBDQEGFHkR2bj5pCIYIIEv
oSxm/uPXU8GaF0b2xEw0GoAG3ZP65Lp8ba1ChesCgcBqqTIMfVOy2QtcY8rY1QY5
w/6d8iF/X/0WHkq5Q1gC3YWolcSlqyj3bG90hoXzNKiKXi6UfU6dk6/iB3g7VJAd
ikm662KOpDyaT0m+01ymxaGJfjSu8oTAPlu6BGgZc+1l/R/c4chM3+/nGnrnpr2o
uaBThpQ0q+7a3f7LpcRX8Dssa33JL7fB+H6UeKKYXZBDLlXvo2mlRhXOR+9UArnJ
GpF9fk7Kossp6bZRASgTBaow07rRHeKBXyY6cklQqi0CgcArqcwaZnscc+ZnbxFw
0BJ/P71ZYe47x71T7tz3w3uBeGMYbXSNxTpUXPOxJtCMdPzIGs5/Uj+SsRmURd/z
Q0CMSBQb53X/hDZ8BldCFRB1oTQd2Qtngd9oU44Gv6a1Nnue4yX4rw2xwDUQJIag
zmqnnGA19d0KpBpp5yqRcDMcUPvuwI/9DnAFZPc/N/hiQRL5tvZzLMePFG4Agjx/
6WJ1s7jcW+AVYUpkSUZ93y1DlwQdK0E6Go41jxz3khw+lZECgcBQMQEni2Rd2Ccr
MCOZOV1591wIg4or0XGws1+Joj68ITmTUJGMgenK8wxhprV3m4ATnuQkDC8d26o7
WlddiPBfLC2gidwzn4ZqTOYm9jvYCSFSWgD+gQOiEbh9NdDBNYOdAuAuN44L2Nz6
LSqRzVzpD2q1Z3SlWNFf0p22brt31ybY23bxLXONSWangQnKdMZ0yO0WYQQ0Y1G+
4KzJKVSMeOzgCvzWrEvAoPAxH4GBvrvqYyTBaBnrNhvgB9PEZ5k=
-----END RSA PRIVATE KEY-----" >> key2.pem


chmod 444 key2.pem cert2.pem
kubectl -n staging create secret tls peopledesk-ingress-tls --key key2.pem --cert cert2.pem



echo -e 'apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  annotations:\n    nginx.ingress.kubernetes.io/ssl-redirect: "true"\n    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-body-size: "0"\n    nginx.org/websocket-services: "madina-socket-api,madina-front,mgm-socket-api,sme-front"\n    \n  name: ing-ibosapp\nspec:\n  ingressClassName: ibosio-ingress\n  rules:\n    #madina.ibos.io\n    - host: dev-madina.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: madina-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /domain\n            backend:\n              service:\n                name: madina-domain-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: madina-identity-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /partner\n            backend:\n              service:\n                name: madina-partner-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /procurement\n            backend:\n              service:\n                name: madina-procurement-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /wms\n            backend:\n              service:\n                name: madina-wms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hcm\n            backend:\n              service:\n                name: madina-hcm-api\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /costmgmt\n            backend:\n              service:\n                name: madina-cost-api\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /item\n            backend:\n              service:\n                name: madina-item-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /fino\n            backend:\n              service:\n                name: madina-finance-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /oms\n            backend:\n              service:\n                name: madina-oms-api\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /imp\n            backend:\n              service:\n                name: madina-import-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /mes\n            backend:\n              service:\n                name: madina-mes-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /asset\n            backend:\n              service:\n                name: madina-asset-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /tms\n            backend:\n              service:\n                name: madina-tms-api\n                port:\n                  number: 80\n    #madina.ibos.io\n\n    #madina-socket.ibos.io\n    - host: dev-madina-socket.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: madina-socket-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /socket\n            backend:\n              service:\n                name: madina-socket-api\n                port:\n                  number: 80\n    #madina-socket.ibos.io\n\n    #uat-madina.ibos.io\n    - host: dev-uat-madina.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: madina-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /domain\n            backend:\n              service:\n                name: madina-domain-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: madina-identity-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /partner\n            backend:\n              service:\n                name: madina-partner-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /procurement\n            backend:\n              service:\n                name: madina-procurement-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /wms\n            backend:\n              service:\n                name: madina-wms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hcm\n            backend:\n              service:\n                name: madina-hcm-api\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /costmgmt\n            backend:\n              service:\n                name: madina-cost-api\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /item\n            backend:\n              service:\n                name: madina-item-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /fino\n            backend:\n              service:\n                name: madina-finance-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /oms\n            backend:\n              service:\n                name: madina-oms-api\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /imp\n            backend:\n              service:\n                name: madina-import-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /mes\n            backend:\n              service:\n                name: madina-mes-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /asset\n            backend:\n              service:\n                name: madina-asset-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /tms\n            backend:\n              service:\n                name: madina-tms-api\n                port:\n                  number: 80\n    #uat-madina.ibos.io\n\n    #uat-madina-socket.ibos.io\n    - host: dev-uat-madina-socket.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: madina-socket-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /socket\n            backend:\n              service:\n                name: madina-socket-api\n                port:\n                  number: 80\n    #madina-socket.ibos.io\n    #devshipping.ibos.io\n    - host: dev-shipping.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: employee-mgmt-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /emp\n            backend:\n              service:\n                name: employee-mgmt-api\n                port:\n                  number: 80\n    #devshipping.ibos.io\n    #devhr.peopledesk.io\n    - host: dev-hr.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: peopledesk-saas-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: peopledesk-saas-api\n                port:\n                  number: 80\n    #devhr.peopledesk.io\n    #devuttara.peopledesk.io\n    - host: dev-uttara.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: people-desk-uttara-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: people-desk-uttara-api\n                port:\n                  number: 80\n    #devuttara.peopledesk.io\n    #devibos.peopledesk.io\n    - host: dev-ibos.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: employee-mgmt-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /emp\n            backend:\n              service:\n                name: employee-mgmt-api\n                port:\n                  number: 80\n    #devibos.peopledesk.io\n    #devhire.peopledesk.io\n    - host: dev-hire.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: hire-desk-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: hire-desk-api\n                port:\n                  number: 80\n    #devhire.peopledesk.io\n    \n    \n    #devrsc.peopledesk.io\n    - host: dev-rsc.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: people-desk-rsc-front\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: people-desk-rsc-api\n                port:\n                  number: 80\n\n    #devarl.peopledesk.io\n    - host: dev-arl.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: people-desk-arl-front\n                port:\n                  number: 80\n\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: people-desk-arl-api\n                port:\n                  number: 80\n\n    #devifarmer.peopledesk.io\n    - host: dev-ifarmer.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: people-desk-ifarmer-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: people-desk-ifarmer-api\n                port:\n                  number: 80\n\n    #devifarmer.peopledesk.io\n    - host: dev-justiceandcarebd.peopledesk.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: people-desk-jncare-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /api\n            backend:\n              service:\n                name: people-desk-jncare-api\n                port:\n                  number: 80\n    #dev-apon.ibos.io\n    - host: dev-apon.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: apon-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /apon\n            backend:\n              service:\n                name: apon-api\n                port:\n                  number: 80\n    #dev-apon.ibos.io\n    - host: dev-promotion.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /promotion\n            backend:\n              service:\n                name: promotion-api\n                port:\n                  number: 80\n    #vat.ibos.io\n    - host: dev-primevat.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: tax-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /domain\n            backend:\n              service:\n                name: tax-domain-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: tax-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: tax-identity-api\n                port:\n                  number: 80\n    #arlvat.ibos.io\n    - host: dev-arlvat.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: arlvat-front\n                port:\n                  number: 80\n    #devmgm.ibos.io\n    - host: dev-mgm.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: sme-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /sme\n            backend:\n              service:\n                name: sme-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: sme-identity-api\n                port:\n                  number: 80\n\n    #mgm-socket.ibos.io\n    - host: dev-mgm-socket.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: mgm-socket-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /socket\n            backend:\n              service:\n                name: mgm-socket-api\n                port:\n                  number: 80\n          \n    #cpanel.ibos.io\n    - host: dev-panel.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: cpanel-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /cpanel\n            backend:\n              service:\n                name: cpanel-api\n                port:\n                  number: 80\n    #dev-dealer.ibos.io\n    - host: dev-dealer.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: dealer-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /dealer\n            backend:\n              service:\n                name: dealer-api\n                port:\n                  number: 80\n                  \n    #dev-dealer.ibos.io\n    - host: dev-sscorporation.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: sscorporation-front\n                port:\n                  number: 80\n\n    #devErp.ibos.io\n    - host: dev-erp.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: ibos-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /costmgmt\n            backend:\n              service:\n                name: cost-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /domain\n            backend:\n              service:\n                name: domain-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /procurement\n            backend:\n              service:\n                name: procurement-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /item\n            backend:\n              service:\n                name: item-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /partner\n            backend:\n              service:\n                name: partner-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /wms\n            backend:\n              service:\n                name: wms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /mes\n            backend:\n              service:\n                name: mes-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /tms\n            backend:\n              service:\n                name: tms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /oms\n            backend:\n              service:\n                name: oms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /pms\n            backend:\n              service:\n                name: pms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /fino\n            backend:\n              service:\n                name: finance-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: vat-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hcm\n            backend:\n              service:\n                name: hcm-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /asset\n            backend:\n              service:\n                name: asset-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /rtm\n            backend:\n              service:\n                name: rtm-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: ibos-identity-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /imp\n            backend:\n              service:\n                name: import-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /arlerp\n            backend:\n              service:\n                name: arlerp-api\n                port:\n                  number: 80\n\n    #devrtm.ibos.io\n    - host: dev-rtm.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: rtm-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /domain\n            backend:\n              service:\n                name: domain-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /item\n            backend:\n              service:\n                name: item-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /partner\n            backend:\n              service:\n                name: partner-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /tms\n            backend:\n              service:\n                name: tms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /oms\n            backend:\n              service:\n                name: oms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hcm\n            backend:\n              service:\n                name: hcm-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /rtm\n            backend:\n              service:\n                name: rtm-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: ibos-identity-api\n                port:\n                  number: 80\n    #signal.ibos.io\n    - host: dev-signal.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: signalr-api\n                port:\n                  number: 80\n\n    #auth.ibos.io\n    - host: dev-auth.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: identityserver-api\n                port:\n                  number: 80\n\n    #rmg.ibos.io\n    - host: dev-rmg.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: rmg-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /rmg\n            backend:\n              service:\n                name: rmg-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: rmg-identity-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hr\n            backend:\n              service:\n                name: rmg-hr-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hrm\n            backend:\n              service:\n                name: rmg-hrm-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /finance\n            backend:\n              service:\n                name: rmg-finance-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /production\n            backend:\n              service:\n                name: rmg-production-api\n                port:\n                  number: 80\n    #RMG\n    #rmghr.ibos.io\n    - host: dev-rmghr.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: rmghr-front\n                port:\n                  number: 80\n\n    #erp.akijresources.com\n    - host: dev-erp.akijresources.com\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: ibos-front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /costmgmt\n            backend:\n              service:\n                name: cost-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /domain\n            backend:\n              service:\n                name: domain-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /procurement\n            backend:\n              service:\n                name: procurement-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /item\n            backend:\n              service:\n                name: item-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /partner\n            backend:\n              service:\n                name: partner-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /wms\n            backend:\n              service:\n                name: wms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /mes\n            backend:\n              service:\n                name: mes-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /tms\n            backend:\n              service:\n                name: tms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /oms\n            backend:\n              service:\n                name: oms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /pms\n            backend:\n              service:\n                name: pms-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /fino\n            backend:\n              service:\n                name: finance-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: vat-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /hcm\n            backend:\n              service:\n                name: hcm-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /asset\n            backend:\n              service:\n                name: asset-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /rtm\n            backend:\n              service:\n                name: rtm-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: ibos-identity-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /imp\n            backend:\n              service:\n                name: import-api\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /arlerp\n            backend:\n              service:\n                name: arlerp-api\n                port:\n                  number: 80\n\n  tls:\n    - hosts:\n        - dev-madina.ibos.io\n        - dev-madina-socket.ibos.io\n        - dev-shipping.ibos.io\n        - dev-uat-madina.ibos.io\n        - dev-uat-madina-socket.ibos.io\n        - dev-apon.ibos.io\n        - dev-vat.ibos.io\n        - dev-arlvat.ibos.io\n        - dev-mgm.ibos.io\n        - dev-mgm-socket.ibos.io\n        - dev-panel.ibos.io\n        - dev-dealer.ibos.io\n        - dev-erp.ibos.io\n        - dev-rtm.ibos.io\n        - dev-auth.ibos.io\n        - dev-signal.ibos.io\n        - dev-rmg.ibos.io\n        - dev-rmghr.ibos.io\n        - dev-primevat.ibos.io\n        - dev-sscorporation.ibos.io\n        - dev-mgm-socket.ibos.io\n        - dev-promotion.ibos.io\n\n      secretName: ibosio-ingress-tls\n\n      #peopledesk\n    - hosts:\n        - dev-uttara.peopledesk.io\n        - dev-hr.peopledesk.io\n        - dev-ibos.peopledesk.io\n        - dev-hire.peopledesk.io\n        - dev-rsc.peopledesk.io\n        - dev-arl.peopledesk.io\n        - dev-ifarmer.peopledesk.io\n        - dev-justiceandcarebd.peopledesk.io\n\n      secretName: peopledesk-ingress-tls\n\n      #akijresources\n    - hosts:\n        - dev-erp.akijresources.com\n\n      secretName: akijresources-ingress-tls' >> ibos_ingress.yaml
chmod +x ibos_ingress.yaml
#kubectl -n staging apply -f ibos_ingress.yaml

kubectl -n staging create secret docker-registry dockercred --docker-server=https://index.docker.io --docker-username=iboslimitedbd --docker-password=iBOS@ltd21 --docker-email=iboslimitedbd@gmail.com


rm ~/.bash_history
history -c

rm run.sh

rm ~/.bash_history
history -c

reboot
