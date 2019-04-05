
# 기본 설치 및 준비사항들

ref:  https://riptutorial.com/ko/openshift/example/30544/minishift-%EC%8B%9C%EC%9E%91%ED%95%98%EA%B8%B0

or

https://github.com/redhat-developer-demos/istio-tutorial/blob/master/documentation/modules/ROOT/pages/1setup.adoc


## install 기본 설치 파일
```bash
sudo apt-get install linux-headers-$(uname -r|sed 's,[^-]*-[^-]*-,,') virtualbox
sudo apt-get install siege
sudo apt-get install linuxbrew-wrapper
sudo systemctl enable virtualbox && systemctl start virtualbox
```


## intstall minishift
```bash
# minishift 1.0.0 version
#wget -O $HOME/minishift/minishift.tar.gz https://github.com/minishift/minishift/releases/download/v1.0.0/minishift-1.0.0-linux-amd64.tgz && \

mkdir $HOME/minishift && \
wget -O $HOME/minishift/minishift.tar.gz https://github.com/minishift/minishift/releases/download/v1.33.0/minishift-1.33.0-linux-amd64.tgz && \
tar -xf $HOME/minishift/minishift.tar.gz -C $HOME/minishift
```

## PATH 추가
```bash
echo "export PATH=\$PATH:$HOME/minishift" >> $HOME/.bashrc && \
  source $HOME/.bashrc
```

## stern 설정(brew가 설치된 경로의 bin 패스 추가 )
```bash
echo "PATH=/home/linuxbrew/.linuxbrew/bin:\$PATH" >> $HOME/.bashrc 
echo "export MANPATH=$(brew --prefix)/share/man:\$MANPATH" >> $HOME/.bashrc 
echo "export INFOPATH=$(brew --prefix)/share/info:\$INFOPATH" >> $HOME/.bashrc 
source $HOME/.bashrc
```

## 설치확인 
```bash
./check.sh
```

## minishift 실행
```bash
minishift profile set tutorial
minishift config set memory 8GB
minishift config set cpus 3
minishift config set vm-driver virtualbox
minishift config set image-caching true
minishift addon enable admin-user
minishift config set openshift-version v3.11.0

minishift start
# 오래 걸리잖아 ~~!!!
```


## PATH에 openshift 클라이언트 명령을 내 보냅니다.
```
echo "export PATH=\$PATH:$(dirname $(find $HOME/.minishift -name oc -type f))" >> $HOME/.bashrc && \
  source $HOME/.bashrc
```



## minishift에 로그인
```bash
eval $(minishift oc-env)
eval $(minishift docker-env)

oc login -u system:admin https://$(minishift ip):8443
```

## node info
```bash
oc get node -o wide
```

## Upstream Istio installation
```bash
# Mac OS:
curl -L https://github.com/istio/istio/releases/download/1.1.1/istio-1.1.1-osx.tar.gz | tar xz

# Fedora/RHEL:
curl -L https://github.com/istio/istio/releases/download/1.1.1/istio-1.1.1-linux.tar.gz | tar xz

# Both:
cd istio-1.1.1
export ISTIO_HOME=`pwd`
export PATH=$ISTIO_HOME/bin:$PATH

oc apply -f install/kubernetes/helm/istio-init/files/crd-11.yaml

oc apply -f install/kubernetes/istio-demo.yaml

oc project istio-system

oc expose svc istio-ingressgateway
oc expose svc grafana
oc expose svc prometheus
oc expose svc tracing
oc expose service kiali --path=/kiali
oc adm policy add-cluster-role-to-user admin system:serviceaccount:istio-system:kiali-service-account -z default

```
Wait for Istio’s components to be ready
```bash
oc get pods -w

NAME                                        READY     STATUS      RESTARTS   AGE
grafana-6995b4fbd7-ntp4f                    1/1       Running     0          57m
istio-citadel-54f4678f86-jnv5s              1/1       Running     0          57m
istio-cleanup-secrets-nch4k                 0/1       Completed   0          57m
istio-egressgateway-5d7f8fcc7b-r76gg        1/1       Running     0          57m
istio-galley-7bd8b5f88f-nlczb               1/1       Running     0          57m
istio-grafana-post-install-lffq2            0/1       Completed   0          57m
istio-ingressgateway-6f58fdc8d7-gbzzq       1/1       Running     0          57m
istio-pilot-d99689994-zh66q                 2/2       Running     0          57m
istio-policy-766bf4bd6d-skwkp               2/2       Running     0          57m
istio-sidecar-injector-85ccf84984-crmhv     1/1       Running     0          57m
istio-statsd-prom-bridge-55965ff9c8-76nx4   1/1       Running     0          57m
istio-telemetry-55b6b5bbc7-qmf2l            2/2       Running     0          57m
istio-tracing-77f9f94b98-kknh7              1/1       Running     0          57m
prometheus-7456f56c96-nxdvv                 1/1       Running     0          57m
servicegraph-684c85ffb9-f7tjp               1/1       Running     2          57m
```
Wait for Istio’s components to be ready
```bash
oc get pods -n istio-system
NAME                                          READY     STATUS      RESTARTS   AGE
elasticsearch-0                               1/1       Running     0          3m
grafana-648c7d5cc6-d4cgr                      1/1       Running     0          3m
istio-citadel-64f86c964-vjd6f                 1/1       Running     0          5m
istio-egressgateway-8579f6f649-zwmqh          1/1       Running     0          5m
istio-galley-569c79fcbf-rc24l                 1/1       Running     0          5m
istio-ingressgateway-5457546784-gct2p         1/1       Running     0          5m
istio-pilot-78d8f7465f-kmclw                  2/2       Running     0          5m
istio-policy-b57648f9f-cvj82                  2/2       Running     0          5m
istio-sidecar-injector-5876f696f-s2pdt        1/1       Running     0          5m
istio-statsd-prom-bridge-549d687fd9-g2gmc     1/1       Running     0          5m
istio-telemetry-56587b8fb6-wpg9k              2/2       Running     0          5m
jaeger-agent-6qgrl                            1/1       Running     0          3m
jaeger-collector-9cbd5f46c-kt9w9              1/1       Running     0          3m
jaeger-query-6678967b5-8sgdp                  1/1       Running     0          3m
kiali-6b8c686d9b-mkxdv                        1/1       Running     0          2m
openshift-ansible-istio-installer-job-rj7pj   0/1       Completed   0          7m
prometheus-6ffc56584f-zgbv8                   1/1       Running     0          5m

```



# apendix. minishift stop&delete
```bash
minishift stop
minishift delete tutorial 
minishift profile delete tutorial

# appendix ui ref 
minishift console
```

