
## ref  https://riptutorial.com/ko/openshift/example/30544/minishift-%EC%8B%9C%EC%9E%91%ED%95%98%EA%B8%B0

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

## PATH에 openshift 클라이언트 명령을 내 보냅니다.
```
echo "export PATH=\$PATH:$(dirname $(find $HOME/.minishift -name oc -type f))" >> $HOME/.bashrc && \
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
```

## minishift에 로그인
``bash
eval $(minishift oc-env)
eval $(minishift docker-env)

oc login -u system:admin https://$(minishift ip):8443
```

## node info
```bash
oc get node -o wide
```

# apendix. minishift stop&delete
```bash
minishift stop
minishift delete tutorial 

# appendix ui ref 
minishift console
```

