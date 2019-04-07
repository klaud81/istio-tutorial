wget -O $HOME/minishift/minishift.tar.gz https://github.com/minishift/minishift/releases/download/v1.33.0/minishift-1.33.0-

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
curl -L https://github.com/istio/istio/releases/download/0.5.1/istio-0.5.1-osx.tar.gz | tar xz

# Fedora/RHEL:
curl -L https://github.com/istio/istio/releases/download/0.5.1/istio-0.5.1-linux.tar.gz | tar xz

# Both:
cd istio-0.5.1
export ISTIO_HOME=`pwd`
export PATH=$ISTIO_HOME/bin:$PATH

oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account \
 -n istio-system
oc adm policy add-scc-to-user anyuid -z default -n istio-system
oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system

oc create -f install/kubernetes/istio.yaml

oc project istio-system
oc get pods -w

oc apply -f install/kubernetes/addons/prometheus.yaml
oc apply -f install/kubernetes/addons/grafana.yaml
oc apply -f install/kubernetes/addons/servicegraph.yaml
oc process -f  https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f -

oc expose svc servicegraph
oc expose svc grafana
oc expose svc prometheus
oc expose svc istio-ingress

oc get pods

# source download and branch
cd ..
./source_downlod.sh

oc new-project tutorial
oc adm policy add-scc-to-user privileged -z default -n tutorial
#oc create namespace tutorial


cd istio-tutorial/customer
./build.sh
docker images | grep example

# error -> vi  >> privileged: true
============================
          capabilities:
            add:
            - NET_ADMIN
          privileged: true
============================


oc project default
oc get all 
#check router
deploymentconfig.apps.openshift.io/router            1          1         1         config

curl customer-tutorial.$(minishift ip).nip.io
customer => I/O error on GET request for "http://preference:8080": preference; nested exception is java.net.UnknownHostException: preference

cd ../preference/
./build.sh
docker images | grep example
curl customer-tutorial.$(minishift ip).nip.io
customer => 503 preference => I/O error on GET request for "http://recommendation:8080": recommendation; nested exception is java.net.UnknownHostException: recommendation

cd ../recommendation/
./build.sh
docker images | grep example
curl customer-tutorial.$(minishift ip).nip.io
customer => preference => recommendation v1 from '749df8b687-w94vc': 1


```


# apendix. minishift stop&delete
```bash
minishift stop
minishift delete tutorial 
minishift profile delete tutorial

# appendix ui ref 
minishift console
```

