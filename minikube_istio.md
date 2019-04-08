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

minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.10.0 \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" \
    --vm-driver='virtualbox'
```
## Install Helm(2.12.1)
```bash
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz
tar -xzvf helm-v2.12.1-linux-amd64.tar.gz
chmod +x linux-amd64/helm
mv linux-amd64/helm /usr/local/bin/helm
```
## Download Istio(1.0.5)
```bash
git clone https://github.com/istio/istio.git
cd istio/
git checkout tags/1.0.5
sudo cp bin/istioctl /usr/local/bin
```
## Install Istio(1.0.5)
```bash
helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
kubectl create namespace istio-system
kubectl apply -f $HOME/istio.yaml
kubectl get pods -n istio-system
```
## Run Bookinfo App
```bash
cd istio/
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml)
kubectl get services
kubectl get pods
## You need to wait to have all pods running this take some time
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl get gateway
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
