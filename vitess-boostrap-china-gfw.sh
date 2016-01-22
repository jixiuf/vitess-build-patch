#!/bin/bash
# 1 install go1.4+
sudo yum install -y go

# 2. Install MariaDB 10.0 or MySQL 5.6. You can use any installation
# method (src/bin/rpm/deb), but be sure to include the client
# development headers (libmariadbclient-dev or libmysqlclient-dev).

# install mysql5.6
# 或者是MariaDB 10.0 来代替mysql 这里用mysql5.6
if [ `rpm -qa|grep -c mysql-community-release` -eq 0 ]; then
    sudo rpm -ih http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
fi

sudo yum install -y  mysql-server mysql mysql-devel
# sudo yum install -y mysql-server mysql mysql-devel

# Select a lock service from the options listed below. It is
# technically possible to use another lock server, but plugins
# currently exist only for ZooKeeper and etcd.
# 1.ZooKeeper 3.3.5 is included by default.
# 2. Install etcd v2.0+. If you use etcd, remember to include the etcd command on your path.
# etcd 2以上版本
sudo yum install -y etcd


sudo yum install -y bzr git make automake libtool pkgconfig bison curl unzip patch
sudo yum install -y  memcached

if [ -z $GOPATH ]; then
    export GOPATH=~/go
fi
mkdir -p $GOPATH/{bin,src/github.com/youtube/,pkg}


if [ ! -d $GOPATH/src/github.com/youtube/vitess/.git ]; then
    git clone https://github.com/youtube/vitess.git $GOPATH/src/github.com/youtube/vitess
    # cp build-vitess.sh $GOPATH/src/github.com/youtube/vitess/build-vitess.sh
    cp china-gfw.patch $GOPATH/src/github.com/youtube/vitess/
    cd $GOPATH/src/github.com/youtube/vitess;git apply -- china-gfw.patch;cd -
fi

sudo yum install -y  openssl openssl-devel gcc-c++
sudo yum install -y python-devel python-virtualenv MySQL-python
if [ ! -d ~/python ]; then
    virtualenv ~/python
    echo "source ~/python/bin/activate" >>~/.bashrc
    # sed 's|source ~/python/bin/activate||g' ~/.bashrc
fi
~/python/bin/pip install MySQL-python

# sudo yum install -y docker
# sudo service docker start
# sudo chkconfig docker on


if [ `grep -c set_vitess_env ~/.bashrc ` -eq 0 ]
then
    cat >>~/.bashrc <<EOF

# set_vitess_env
export VT_TEST_FLAGS='--topo-server-flavor=etcd'
export MYSQL_FLAVOR=MySQL56
export GODEBUG=netdns=go
export GOROOT=/usr/lib/golang/
export GOPATH=~/go
source $GOPATH/src/github.com/youtube/vitess/dev.env
EOF
fi

source ~/.bashrc

if [ -f ~/.zshrc ] && [ `grep -c set_vitess_env ~/.zshrc ` -eq 0 ]
then
    cat >>~/.bashrc <<EOF

# set_vitess_env
export VT_TEST_FLAGS='--topo-server-flavor=etcd'
export MYSQL_FLAVOR=MySQL56
export GODEBUG=netdns=go
export GOROOT=/usr/lib/golang/
export GOPATH=~/go
source $GOPATH/src/github.com/youtube/vitess/dev.env
EOF
fi


mkdir -p $GOPATH/src/golang.org/x
if [ ! -d $GOPATH/src/golang.org/x/net ]; then
    cd $GOPATH/src/golang.org/x;git clone  https://github.com/golang/net.git ;cd -
else
    cd $GOPATH/src/golang.org/x/net;git pull;cd -
fi
if [ ! -d $GOPATH/src/golang.org/x/crypto ]; then
    cd $GOPATH/src/golang.org/x;git clone   https://github.com/golang/crypto.git;cd -
else
    cd $GOPATH/src/golang.org/x/crypto;git pull;cd -
fi
if [ ! -d $GOPATH/src/golang.org/x/tools ]; then
    cd $GOPATH/src/golang.org/x;git clone  https://github.com/golang/tools.git;cd -
else
    cd $GOPATH/src/golang.org/x/tools;git pull;cd -
fi
go install golang.org/x/tools/cmd/goimports

if [ ! -d $GOPATH/src/golang.org/x/oauth2 ]; then
    cd $GOPATH/src/golang.org/x;git clone  https://github.com/golang/oauth2.git;go install;cd -
else
    cd $GOPATH/src/golang.org/x/oauth2;git pull;go install;cd -
fi
if [ ! -d $GOPATH/src/google.golang.org/cloud ]; then
    mkdir -p $GOPATH/src/google.golang.org
    cd $GOPATH/src/google.golang.org/;git clone  https://github.com/GoogleCloudPlatform/gcloud-golang.git cloud;cd -
else
    cd $GOPATH/src/google.golang.org/cloud/;git pull;go install;cd -
fi

if [ ! -d $GOPATH/src/google.golang.org/api ]; then
    mkdir -p $GOPATH/src/google.golang.org
    cd $GOPATH/src/google.golang.org/;git clone  https://github.com/google/google-api-go-client.git api;cd -
else
    cd $GOPATH/src/google.golang.org/api/googleapi;git pull;go install;cd -
fi



if [ ! -d $GOPATH/src/google.golang.org/grpc ]; then
    mkdir -p $GOPATH/src/google.golang.org
    cd $GOPATH/src/google.golang.org/;git clone  https://github.com/grpc/grpc.git;cd -
else
    cd $GOPATH/src/google.golang.org/grpc/;git pull;go install;cd -
fi


cd $GOPATH/src/github.com/youtube/vitess;./bootstrap.sh;cd -
# wget -c http://apache.opencas.org/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
# tar -xf zookeeper-3.4.6.tar.gz

# if use zookeeper need java
# maybe this is not needed ,I think etcd is simple  than zookeeper
# maybe compile vitess need this
# sudo yum install -y java
# sudo yum install -y  mercurial

