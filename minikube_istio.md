## docker install :
```bash
# https://docs.docker.com/install/linux/docker-ce/ubuntu/

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

```

## Download Install: Kubectl(1.13.0)
```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```
## Install Minikube(0.33.1)
```bash
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube
sudo cp minikube /usr/local/bin && rm minikube  

minikube start --memory=8192 --cpus=4 --cache-images=false

eval $(minikube docker-env)

# delete option
sudo minikube delete
rm -rf ~/.kube ~/.minikube

```


## Install Helm(2.12.1)
```bash
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz
tar -xzvf helm-v2.12.1-linux-amd64.tar.gz
chmod +x linux-amd64/helm
sudo mv linux-amd64/helm /usr/local/bin/helm



```
## Download Istio(1.0.5)
```bash
./downloadIstio.sh
cd istio-1.0.5/
sudo cp bin/istioctl /usr/local/bin
```
## Install config Istio(1.0.5)
```bash

helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
kubectl create namespace istio-system
kubectl apply -f $HOME/istio.yaml
kubectl get pods -n istio-system -w

# STATUS Running or Completed 2

```
# label the namespace for injection
```bash
kubectl label namespace default istio-injection=enabled

kubectl get pods --namespace=istio-system

kubectl get service -n istio-system istio-ingressgateway

#NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                                                                             
istio-ingressgateway   LoadBalancer   10.104.226.154   <pending>
```

# install MetalLB
```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

kubectl get pods -n metallb-system -w
# STATUS Running 2 (controller, speaker)

minikube ip
#config.yml file 192.168.99.106
kubectl apply -f config.yml       
==========
protocol: layer2
      addresses:
      - 192.168.99.106/28
==========

kubectl get service -n istio-system istio-ingressgateway

#NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                                                                             
istio-ingressgateway   LoadBalancer   10.104.226.154   192.168.99.96

```


# customer example
```bash
cd istio-tutorial/customer
=============================
./mvnw clean package
docker build -t example/customer .
docker images | grep example
#istioctl kube-inject -f src/main/kubernetes/Deployment.yml > istio_Deployment.yml
kubectl apply -f <(istioctl kube-inject -f src/main/kubernetes/Deployment.yml)
kubectl get pods -w
# STATUS   Running  customer
kubectl apply -f src/main/kubernetes/Service.yml
kubectl get svc
# TYPE ClusterIP  customer

kubectl apply -f customer-virtual.yml

curl http://192.168.99.96:80/customer
curl http://192.168.99.96:80
#customer => I/O error on GET request for "http://preference:8080": preference; nested exception is java.net.UnknownHostException: preference



```

# preference example
```bash
cd ../preference/
./mvnw clean package
docker build -t example/preference .
docker images | grep preference

#istioctl kube-inject -f src/main/kubernetes/Deployment.yml > istio_Deployment.yml
kubectl apply -f <(istioctl kube-inject -f src/main/kubernetes/Deployment.yml)
kubectl get pods -w
# STATUS   Running  preference
kubectl apply -f src/main/kubernetes/Service.yml
kubectl get svc
# TYPE ClusterIP  preference


curl http://192.168.99.96:80/customer
curl http://192.168.99.96:80
#customer => 503 preference => I/O error on GET request for "http://recommendation:8080": recommendation; nested exception is java.net.UnknownHostException: recommendation
```


# recommendation example
```bash
cd ../recommendation/
./mvnw clean package
docker build -t example/recommendation:v1 .
kubectl apply -f <(istioctl kube-inject -f src/main/kubernetes/Deployment.yml)
kubectl get pods -w
# STATUS   Running  recommendation
kubectl apply -f src/main/kubernetes/Service.yml
kubectl get svc
# TYPE ClusterIP  recommendation

curl http://192.168.99.96:80/customer
curl http://192.168.99.96:80
customer => preference => recommendation v1 from '679dfdf957-ctkfr': 1
```


# recommendation v2
```bash
mvn clean package
docker build -t example/recommendation:v1 .
docker build -t example/recommendation:v2 .
docker images | grep recommendation
kubectl apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment-v2.yml)


curl http://192.168.99.96:80/customer
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

```




## Testing the App
```bash
# URL will be something like: 192.168.99.100:31380/productpage 
URL="http://$(minikube ip):$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')/productpage"
curl -o /dev/null -s -w "%{http_code}\n" $URL
xdg-open $URL
```
## Install Kiali
```bash
bash <(curl -L http://git.io/getLatestKialiKubernetes)
xdg-open "https://$(minikube ip):$(kubectl -n istio-system get service kiali -o jsonpath='{.spec.ports[?(@.port==20001)].nodePort}')/kiali/console"
```
## Accessing Prometheus
```bash
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090
xdg-open http://localhost:9090/graph?g0.range_input=1h&g0.expr=istio_request_bytes_count&g0.tab=0
```
