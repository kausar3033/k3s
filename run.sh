curl -sfL https://get.k3s.io | sh -
sudo ufw allow 6443/tcp
sudo ufw reload
mkdir -p ~/.kube
touch ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
echo -e "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  namespace: metallb-system\n  name: config\ndata:\n  config: |\n    address-pools:\n    - name: default\n      protocol: layer2\n      addresses:\n      - <ip-address-range-start>-<ip-address-range-stop>
" >> metallb-configmap.yaml
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


echo -e "apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  annotations:\n    nginx.ingress.kubernetes.io/ssl-redirect: "true"\n    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"\n    nginx.ingress.kubernetes.io/proxy-body-size: "0"\n     \n  name: ing-ibosapp\nspec:\n  ingressClassName: ibosio-ingress\n  rules:\n    #madina.ibos.local\n    - host: amanvat.ibos.io\n      http:\n        paths:\n          - pathType: Prefix\n            path: /\n            backend:\n              service:\n                name: front\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /identity\n            backend:\n              service:\n                name: identity\n                port:\n                  number: 80\n          - pathType: Prefix\n            path: /vat\n            backend:\n              service:\n                name: vatapi\n                port:\n                  number: 80\n\n\n\n  tls:\n    - hosts:\n        - amanvat.ibos.io\n       \n\n      secretName: ibosio-ingress-tls" >> ibos_ingress.yaml
chmod +x ibos_ingress.yaml
kubectl -n staging apply -f ibos_ingress.yaml

kubectl -n staging create secret docker-registry dockercred --docker-server=https://index.docker.io --docker-username=iboslimitedbd --docker-password=iBOS@ltd21 --docker-email=iboslimitedbd@gmail.com

echo -e "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: front\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: front\n  template:\n    metadata:\n      labels:\n        app: front\n        type: front\n    spec:\n      containers:\n        - name: front\n          image: iboslimitedbd/tax-front:33941\n          # Environment variable section\n \n\n          ports:\n            - containerPort: 80\n      imagePullSecrets:\n        - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: front\nspec:\n  selector:\n    app: front\n  ports:\n    - port: 80\n      targetPort: 80\n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.209" >> vat.yaml
chmod +x vat.yaml
kubectl -n staging apply -f vat.yaml

echo -e "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: vatapi\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app:  vatapi\n  template:\n    metadata:\n      labels:\n        app:  vatapi\n        type: vatapi\n    spec:\n      containers:\n      - name:  vatapi\n        image: iboslimitedbd/tax-api:33959\n        # Environment variable section\n        env:\n        - name: ASPNETCORE_ENVIRONMENT\n          value: Production\n        - name:  "ConnectionString"\n          value: "Data Source=10.209.99.244;Initial Catalog=TAX;User ID=isukisespts3vapp8dt;Password=wsa0str1vpo@8d5ws;Connect Timeout=30;Encrypt=False;TrustServerCertificate=False;ApplicationIntent=ReadWrite;"\n\n      imagePullSecrets:\n      - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: vatapi\nspec:\n  selector:\n    app: vatapi\n  ports:\n  - port: 80\n    # targetPort: 80 \n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.194\n\n  #Ingress SSL with custom path Configurations" >> tax-api.yaml
chmod +x tax-api.yaml
kubectl -n staging apply -f tax-api.yaml

echo -e "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: identity\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app:   identity\n  template:\n    metadata:\n      labels:\n        app:  identity\n        type: identity\n    spec:\n      containers:\n      - name:  identity\n        image: iboslimitedbd/tax-identity-api:34013\n        # Environment variable section\n        env:\n        - name: ASPNETCORE_ENVIRONMENT\n          value: Production\n        - name:  "ConnectionString"\n          value: "Data Source=10.209.99.244;Initial Catalog=TAX;User ID=isukisespts3vapp8dt;Password=wsa0str1vpo@8d5ws;Connect Timeout=30;Encrypt=False;TrustServerCertificate=False;ApplicationIntent=ReadWrite;"\n\n      imagePullSecrets:\n      - name: dockercred\n\n---\napiVersion: v1\nkind: Service\nmetadata:\n  name: identity\nspec:\n  selector:\n    app: identity\n  ports:\n  - port: 80\n    # targetPort: 80 \n  # type: LoadBalancer\n  # loadBalancerIP: 10.17.217.194\n\n  #Ingress SSL with custom path Configurations" >> identity.yaml
chmod +x identity.yaml
kubectl -n staging apply -f identity.yaml

rm run.sh
