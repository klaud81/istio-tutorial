# docker, kubectl, minikube, helm, istio-1.0.5, MetalLB 로컬 환경 구축하기

## bash completion
```bash
# istioctl
istioctl collateral completion --bash -o . 
source ./istioctl.bash
# kubectl
echo "source <(kubectl completion bash)" >> ~/.bashrc && source ~/.bashrc

```

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

## delete option
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
## Download Istio(1.0.2)
```bash
curl -sL https://github.com/istio/istio/releases/download/1.0.2/istio-1.0.2-linux.tar.gz | tar xz
cd istio-1.0.2
sudo cp bin/istioctl /usr/local/bin
```

## Install config Istio(1.0.2)
```bash
## 방법 1 - kube menifest 를 이용하는 방법 
helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
kubectl create namespace istio-system
kubectl apply -f $HOME/istio.yaml
kubectl get pods -n istio-system -w

# STATUS Running or Completed 2
# label the namespace for injection
kubectl label namespace default istio-injection=enabled

kubectl get pods --namespace=istio-system

kubectl get service -n istio-system istio-ingressgateway

#NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                                                                             
istio-ingressgateway   LoadBalancer   10.104.226.154   <pending>

## 방법 2 - helm tiller 를 이용하여 add plugin을 이용하는 방법
kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
helm init --service-account tiller
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --values ../custom-values.yaml 
# --set sidecarInjectorWebhook.enabled=true
kubectl get pods -n istio-system -w
kubectl get service -n istio-system istio-ingressgateway
cat <<EOF > kiali.yml
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: istio-system
  labels:
    app: kiali
type: Opaque
data:
  username: YWRtaW4=
  passphrase: YWRtaW4=
EOF
kubectl apply -f kiali.yml

cat <<EOF > grafana.yml
apiVersion: v1
kind: Secret
metadata:
  name: grafana
  namespace: istio-system
  labels:
    app: grafana
type: Opaque
data:
  username: YWRtaW4=
  passphrase: YWRtaW4=
EOF
kubectl apply -f grafana.yml


```

# install MetalLB
```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

kubectl get pods -n metallb-system -w
# STATUS Running 2 (controller, speaker)

minikube ip
# 192.168.99.106

cat <<EOF > config.yml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: custom-ip-space
      protocol: layer2
      addresses:
      - $(minikube ip)/28
EOF
kubectl apply -f config.yml   


kubectl get service -n istio-system istio-ingressgateway

#NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                                                                             
istio-ingressgateway   LoadBalancer   10.104.226.154   192.168.99.96

IP=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

```


# customer example
```bash
# virtual service
cat <<EOF > customer-virtual.yml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: customer-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: customer
spec:
  hosts:
  - "*"
  gateways:
  - customer-gateway
  http:
  - match:
    - uri:
        prefix: /customer
    - uri:
        prefix: /
    rewrite:
        uri: /
    route:
    - destination:
        port:
          number: 8080
        host: customer
EOF
kubectl apply -f customer-virtual.yml
cd -

cd istio-tutorial/customer/java/quarkus
mvn clean package -DskipTests
docker build -t example/customer .
docker images | grep example
kubectl apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment.yml)
kubectl apply -f ../../kubernetes/Service.yml 
kubectl get po -w

curl http://192.168.99.96:80/customer
curl http://192.168.99.96:80
#customer => UnknownHostException: preference


cd -
```

# preference example
```bash
cd istio-tutorial/preference/java/quarkus
mvn clean package -DskipTests
docker build -t example/preference:v1 .
docker images | grep example
kubectl apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment.yml)
kubectl apply -f ../../kubernetes/Service.yml
kubectl get po -w
cd -


curl http://192.168.99.96:80/customer
curl http://192.168.99.96:80
#customer => Error: 503 - preference => UnknownHostException: recommendation
```


# recommendation example
```bash
cd istio-tutorial/recommendation/java/quarkus
mvn clean package -DskipTests
docker build -t example/recommendation:v1 .
docker images | grep example
kubectl apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment.yml)
kubectl apply -f ../../kubernetes/Service.yml 
kubectl get po,svc 
kubectl get po -w

curl http://192.168.99.96:80/customer
customer => preference => recommendation v1 from '6b4df7d9d9-7x2n8': 1
```


# recommendation v2
```bash
cd src/main/java/com/redhat/developer/demos/recommendation/rest && { curl -O -L https://raw.githubusercontent.com/istiokrsg/handson/master/file/RecommendationResource.java ; cd -; }

mvn clean package -DskipTests
docker build -t example/recommendation:v2 .

docker images | grep recommendation
kubectl apply -f <(istioctl kube-inject -f ../../kubernetes/Deployment-v2.yml)
kubectl get po -w

curl http://192.168.99.96:80/customer
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

# v2 로만 패킷이 가도록 설정
# destination rule 부여- 라벨링
kubectl create -f ../../../istiofiles/destination-rule-recommendation-v1-v2.yml -n tutorial
kubectl create -f ../../../istiofiles/virtual-service-recommendation-v2.yml -n tutorial
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

# v1 로만 패킷이 가도록 재설정
kubectl replace -f ../../../istiofiles/virtual-service-recommendation-v1.yml 
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

## istio 관련 확인 명령어들
# istio ingressgateway logs 확인
kubectl logs -n istio-system -f istio-ingressgateway-7b58d599d8-cf8v2
# istio virtural service 설정 확인 
kubectl describe virtualservices.networking.istio.io
istioctl get virtualservice
# istio ingressgateway 설정 확인
kubectl describe gateways.networking.istio.io
istioctl get gateway 
# istio destinationrules 설정 확인
kubectl describe destinationrules.networking.istio.io
istioctl get destinationrule
# virtual service 삭제
kubectl delete -f ../../../istiofiles/virtual-service-recommendation-v1.yml

```
# canary deployment
v2 를 새 버전이라고 가정
v1 : 90%, v2 : 10% 의 비율로 트래픽을 조절
```bash
kubectl create -f ../../../istiofiles/virtual-service-recommendation-v1_and_v2.yml
while true; do curl http://192.168.99.96:80/customer; sleep .5; done


```
virtual service 교체 (트래픽 비율 수정 75:25)
```bash
kubectl replace -f  ../../../istiofiles/virtual-service-recommendation-v1_and_v2_75_25.yml
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

# virtual service 삭제
kubectl delete -f ../../../istiofiles/virtual-service-recommendation-v1_and_v2_75_25.yml
```

# Load Balancing
```bash
# 확인 config
kubectl apply -f ../../../istiofiles/destination-rule-recommendation_lb_policy_app.yml --dry-run -o yaml
kubectl apply -f ../../../istiofiles/destination-rule-recommendation_lb_policy_app.yml

while true; do curl http://192.168.99.96:80/customer; sleep .5; done

istioctl get destinationrule
istioctl delete destinationrule recommendation

```

# Timeout
```bash
time curl http://192.168.99.96:80/customer
cd src/main/java/com/redhat/developer/demos/recommendation/rest && { curl -L https://raw.githubusercontent.com/istiokrsg/handson/master/file/RecommendationResource-time.java -o RecommendationResource.java  ; cd -; }
cat src/main/java/com/redhat/developer/demos/recommendation/rest/RecommendationResource.java | grep timeout
#주석 없는거 확인
mvn clean package -DskipTests
docker build -t example/recommendation:v2 .
kubectl delete pod -l app=recommendation,version=v2
while true; do time curl http://192.168.99.96:80/customer; sleep .5; done
###########################################################################
customer => preference => recommendation v2 from '7fb655b9bf-s2lpl': 3
real	0m3.031s
user	0m0.003s
sys	0m0.005s
customer => preference => recommendation v1 from '6b4df7d9d9-74wpb': 85
real	0m0.054s
user	0m0.017s
###########################################################################
kubectl apply -f ../../../istiofiles/virtual-service-recommendation-timeout.yml --dry-run -o yaml
kubectl apply -f ../../../istiofiles/virtual-service-recommendation-timeout.yml
while true; do time curl http://192.168.99.96:80/customer; sleep .5; done

##########################################################################
[2019-04-12T09:57:53.105Z] "GET /customer HTTP/1.1" 503 - 0 77 1011 1010 "172.17.0.1" "curl/7.58.0" "32b36d68-172a-93dc-8cd6-123e9d91df94" "192.168.99.96" "172.17.0.20:8080"
[2019-04-12T09:57:54.646Z] "GET /customer HTTP/1.1" 200 - 0 72 12 12 "172.17.0.1" "curl/7.58.0" "cfdbf8bd-5cfd-9ff6-8fdb-3f4f2b00e08d" "192.168.99.96" "172.17.0.20:8080"
##########################################################################
istioctl get virtualservice
istioctl delete virtualservice recommendation

```


# HTTP Error 503, Delay, Retry, Timeout
```bash
# HTTP Error 503 
kubectl apply -f ../../../istiofiles/recommendation-destination-rule.yml
kubectl apply -f ../../../istiofiles/recommendation-virtual-service-503.yml
while true; do time curl http://192.168.99.96:80/customer; sleep .5; done

kubectl delete -f ../../../istiofiles/recommendation-virtual-service-503.yml

# Delay
kubectl apply -f ../../../istiofiles/recommendation-virtual-service-delay.yml
while true; do time curl http://192.168.99.96:80/customer; sleep .5; done

kubectl delete -f ../../../istiofiles/recommendation-virtual-service-delay.yml
kubectl delete -f ../../../istiofiles/recommendation-destination-rule.yml

# Retry
# set v2 503 setting
kubectl exec -it $(kubectl get pods|grep recommendation-v2|awk '{ print $1 }'|head -1) \
-c recommendation -- curl 127.0.0.1:8080/misbehave
## Following requests to / will return a 503
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

kubectl apply -f ../../../istiofiles/recommendation-virtual-service-v2_retry.yml
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

# You can see the active Virtual Services via
kubectl  get virtualservices -o yaml
# Now, delete the retry rule and see the old behavior, where v2 throws 503s
kubectl delete virtualservice recommendation
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

# 정상동작하게 등록
kubectl exec -it $(kubectl get pods|grep recommendation-v2|awk '{ print $1 }'|head -1) \
-c recommendation -- curl 127.0.0.1:8080/behave
# random load-balancing between v1 and v2
while true; do curl http://192.168.99.96:80/customer; sleep .5; done

# Timeout
kubectl apply -f ../../../istiofiles/recommendation-v2_slow.yml
# confirm slow v2
while true; do time curl http://192.168.99.96/customer ; sleep .5; done


kubectl apply -f ../../../istiofiles/recommendation-virtual-service-timeout.yml
while true; do time curl http://192.168.99.96/customer ; sleep .5; done

## clean up
### Replace the recommendation:v2 slow version by the standard one.
kubectl apply -f ../../../istiofiles/recommendation-v2.yml
### Delete the timeout rule.
kubectl delete -f ../../../istiofiles/recommendation-virtual-service-timeout.yml

```

## Circuit Breaker
```bash
# v2 slow
kubectl apply -f ../../../istiofiles/recommendation-v2_slow.yml
# v1, v2 destination-rule 설정-라벨링
kubectl apply -f ../../../istiofiles/recommendation-destination-rule-v1-v2.yml
# 부하분산 트래픽 설정 virtual service
kubectl apply -f ../../../istiofiles/recommendation-virtual-service-v1_and_v2_50_50.yml
# Test 1: Load test without circuit breaker - siege 를 이용한 부하 테스트
docker run --rm funkygibbon/siege siege -r 2 -c 20 -v http://192.168.99.96/customer
# Test 2: Load test with circuit breaker - - siege 를 이용한 부하 테스트
kubectl apply -f ../../../istiofiles/recommendation-destination-rule-cb_policy_version.yml
docker run --rm funkygibbon/siege siege -r 2 -c 20 -v http://192.168.99.96/customer

## clean up
### Replace the slow version by the standard one
kubectl apply -f ../../../istiofiles/recommendation-v2.yml

kubectl delete DestinationRule recommendation

kubectl delete VirtualService recommendation

```


## Pool Ejection
```bash
# destinationrule and virtualservice 50/50
kubectl apply -f ../../../istiofiles/recommendation-destination-rule-v1-v2.yml

kubectl apply -f ../../../istiofiles/recommendation-virtual-service-v1_and_v2_50_50.yml
# v2 Scale up 2
kubectl scale deployment recommendation-v2 --replicas=2

# Test 1: Load test without failing instances
## Throw some requests at the customer endpoint:

while true; do curl http://192.168.99.96/customer; sleep .5; done

# Test 2: Load test with failing instance
## Let’s get the name of the pods from recommendation v2:

kubectl get pods -l app=recommendation,version=v2
# v2 503 misbehave
kubectl exec -it $(kubectl get pods|grep recommendation-v2|awk '{ print $1 }'|head -1) -c recommendation -- curl 127.0.0.1:8080/misbehave

## The error rate is 25 %. Because 1/2 of v2 is in error, v2 is 50% of traffic, hence 1/2 of 50% is in error which is equal to 25%.
while true; do curl http://192.168.99.96/customer; sleep .5; done


# Test 3: Load test with failing instance and with pool ejection
## error 1개 검출 될때, 100% 로 15초동안 제거됨, 검사주기는 5초
kubectl apply -f ../../../istiofiles/recommendation-destination-rule-cb_policy_pool_ejection.yml
while true; do curl http://192.168.99.96/customer; sleep .5; done

# Test 4: Ultimate resilience with retries, circuit breaker, and pool ejection
## Circuit Breaker: 인스터스에 대한 여러개의 동시 요청을 방지
## Pool Ejection: 응답 인스턴스 폴에서 실패한 인스턴스를 제거
## Retries: 풀에 배출 발생한 경우를 대비하여 다른 인스턴스로 요청을 전달
kubectl apply -f ../../../istiofiles/fault-injection/retry/recommendation-virtual-service-v2_retry.yml
while true; do curl http://192.168.99.96/customer; sleep .5; done



## clean up

kubectl scale deployment recommendation-v2 --replicas=1
kubectl delete pod -l app=recommendation,version=v2

kubectl delete virtualservice recommendation
kubectl delete destinationrule recommendation

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


ref: https://medium.com/@emirmujic/istio-and-metallb-on-minikube-242281b1134b
