#!/bin/bash

# curl -sL toast.sh/tools | bash

# version
DATE=
KUBECTL=
KOPS=
HELM=
DRAFT=
ISTIOCTL=
JENKINSX=
TERRAFORM=
NODE=
JAVA=
MAVEN=
HEPTIO=
GUARD=

CONFIG=~/.tools
touch ${CONFIG} && . ${CONFIG}

################################################################################

command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_result() {
    _echo "# $@" 4
}

_command() {
    _echo "$ $@" 3
}

_success() {
    _echo "+ $@" 2
    exit 0
}

_error() {
    _echo "- $@" 1
    exit 1
}

DATE=$(date '+%Y-%m-%d %H:%M:%S')

OS_NAME="$(uname | awk '{print tolower($0)}')"
OS_FULL="$(uname -a)"
OS_TYPE=

if [ "${OS_NAME}" == "linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "amzn1") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "amzn2") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "el6") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "el7") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="apt"
    elif [ $(echo "${OS_FULL}" | grep -c "coreos") -gt 0 ]; then
        OS_TYPE="apt"
    fi
elif [ "${OS_NAME}" == "darwin" ]; then
    OS_TYPE="brew"
fi

_result "${OS_FULL}"
_result "${DATE}"

if [ "${OS_TYPE}" == "" ]; then
    _error "Not supported OS. [${OS_NAME}]"
fi

# brew for mac
if [ "${OS_TYPE}" == "brew" ]; then
    command -v brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# for ubuntu
if [ "${OS_TYPE}" == "apt" ]; then
    export LC_ALL=C
fi

# update
echo "================================================================================"
_result "update..."

if [ "${OS_TYPE}" == "apt" ]; then
    sudo apt update && sudo apt upgrade -y
    command -v jq > /dev/null || sudo apt install -y jq
    command -v git > /dev/null || sudo apt install -y git
    command -v docker > /dev/null || sudo apt install -y docker
    command -v pip > /dev/null || sudo apt install -y python-pip
elif [ "${OS_TYPE}" == "yum" ]; then
    sudo yum update -y
    command -v jq > /dev/null || sudo yum install -y jq
    command -v git > /dev/null || sudo yum install -y git
    command -v docker > /dev/null || sudo yum install -y docker
    command -v pip > /dev/null || sudo yum install -y python-pip
elif [ "${OS_TYPE}" == "brew" ]; then
    brew update && brew upgrade
    command -v jq > /dev/null || brew install jq
    command -v git > /dev/null || brew install git
fi

# aws-cli
echo "================================================================================"
_result "install aws-cli..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v aws > /dev/null || brew install awscli
else
    pip install --upgrade --user awscli
fi

aws --version | xargs

if [ ! -f ~/.aws/config ]; then
    # aws region
    aws configure set default.region ap-northeast-2
fi

# kubectl
echo "================================================================================"
_result "install kubectl..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v kubectl > /dev/null || brew install kubernetes-cli
else
    VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

    if [ "${KUBECTL}" != "${VERSION}" ] || [ "$(command -v kubectl)" == "" ]; then
        _result " ${KUBECTL} >> ${VERSION}"

        curl -LO https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${OS_NAME}/amd64/kubectl
        chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl

        KUBECTL="${VERSION}"
    fi
fi

kubectl version --client --short | xargs | awk '{print $3}'

# kops
echo "================================================================================"
_result "install kops..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v kops > /dev/null || brew install kops
else
    VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r '.tag_name')

    if [ "${KOPS}" != "${VERSION}" ] || [ "$(command -v kops)" == "" ]; then
        _result " ${KOPS} >> ${VERSION}"

        curl -LO https://github.com/kubernetes/kops/releases/download/${VERSION}/kops-${OS_NAME}-amd64
        chmod +x kops-${OS_NAME}-amd64 && sudo mv kops-${OS_NAME}-amd64 /usr/local/bin/kops

        KOPS="${VERSION}"
    fi
fi

kops version 2>&1 | grep Version | xargs | awk '{print $2}'

# helm
echo "================================================================================"
_result "install helm..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v helm > /dev/null || brew install kubernetes-helm
else
    VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')

    if [ "${HELM}" != "${VERSION}" ] || [ "$(command -v helm)" == "" ]; then
        _result " ${HELM} >> ${VERSION}"

        curl -L https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-${OS_NAME}-amd64.tar.gz | tar xz
        sudo mv ${OS_NAME}-amd64/helm /usr/local/bin/helm && rm -rf ${OS_NAME}-amd64

        HELM="${VERSION}"
    fi
fi

helm version --client --short | xargs | awk '{print $2}'

# draft
echo "================================================================================"
_result "install draft..."

#if [ "${OS_TYPE}" == "brew" ]; then
#    command -v draft > /dev/null || brew install draft
#else
    VERSION=$(curl -s https://api.github.com/repos/Azure/draft/releases/latest | jq -r '.tag_name')

    if [ "${DRAFT}" != "${VERSION}" ] || [ "$(command -v draft)" == "" ]; then
        _result " ${DRAFT} >> ${VERSION}"

        curl -L https://azuredraft.blob.core.windows.net/draft/draft-${VERSION}-${OS_NAME}-amd64.tar.gz | tar xz
        sudo mv ${OS_NAME}-amd64/draft /usr/local/bin/draft && rm -rf ${OS_NAME}-amd64

        DRAFT="${VERSION}"
    fi
#fi

draft version --short | xargs

# istioctl
echo "================================================================================"
_result "install istioctl..."

# if [ "${OS_TYPE}" == "brew" ]; then
#     command -v istioctl > /dev/null || brew install istioctl
# else
    VERSION=$(curl -s https://api.github.com/repos/istio/istio/releases/latest | jq -r '.tag_name')

    if [ "${ISTIOCTL}" != "${VERSION}" ] || [ "$(command -v istioctl)" == "" ]; then
        _result " ${ISTIOCTL} >> ${VERSION}"

        if [ "${OS_NAME}" == "darwin" ]; then
            ISTIO_OS="osx"
        else
            ISTIO_OS="${OS_NAME}"
        fi
        curl -L https://github.com/istio/istio/releases/download/${VERSION}/istio-${VERSION}-${ISTIO_OS}.tar.gz | tar xz
        sudo mv istio-${VERSION}/bin/istioctl /usr/local/bin/istioctl && rm -rf istio-${VERSION}

        ISTIOCTL="${VERSION}"
    fi
# fi

istioctl version | grep "Version" | xargs | awk '{print $2}'

# # jenkins-x
# echo "================================================================================"
# _result "install jenkins-x..."

# if [ "${OS_TYPE}" == "brew" ]; then
#    command -v jx > /dev/null || brew install jx
# else
#    VERSION=$(curl -s https://api.github.com/repos/jenkins-x/jx/releases/latest | jq -r '.tag_name')

#    if [ "${JENKINSX}" != "${VERSION}" ]; then
#        _result " ${JENKINSX} >> ${VERSION}"

#        curl -L https://github.com/jenkins-x/jx/releases/download/${VERSION}/jx-${OS_NAME}-amd64.tar.gz | tar xz
#        sudo mv jx /usr/local/bin/jx

#        JENKINSX="${VERSION}"
#    fi
# fi

# jx --version | xargs

# terraform
echo "================================================================================"
_result "install terraform..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v terraform > /dev/null || brew install terraform
else
    VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | cut -c 2-)

    if [ "${TERRAFORM}" != "${VERSION}" ] || [ "$(command -v terraform)" == "" ]; then
        _result " ${TERRAFORM} >> ${VERSION}"

        curl -LO https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_${OS_NAME}_amd64.zip
        unzip terraform_${VERSION}_${OS_NAME}_amd64.zip && rm -rf terraform_${VERSION}_${OS_NAME}_amd64.zip
        sudo mv terraform /usr/local/bin/terraform

        TERRAFORM="${VERSION}"
    fi
fi

terraform version | xargs | awk '{print $2}'

# nodejs
echo "================================================================================"
_result "install nodejs..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v node > /dev/null || brew install node
else
    VERSION=10

    if [ "${NODE}" != "${VERSION}" ] || [ "$(command -v node)" == "" ]; then
        if [ "${OS_TYPE}" == "apt" ]; then
            curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
            sudo apt install -y nodejs
        elif [ "${OS_TYPE}" == "yum" ]; then
            curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
            sudo yum install -y nodejs
        fi

        NODE="${VERSION}"
    fi
fi

node -v | xargs

# java
echo "================================================================================"
_result "install java..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v java > /dev/null || brew cask install java
else
    VERSION=1.8.0

    if [ "${JAVA}" != "${VERSION}" ] || [ "$(command -v java)" == "" ]; then
        _result " ${JAVA} >> ${VERSION}"

        if [ "${OS_TYPE}" == "apt" ]; then
            sudo apt install -y openjdk-8-jdk
        elif [ "${OS_TYPE}" == "yum" ]; then
            sudo yum remove -y java-1.7.0-openjdk
            sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
        fi

        JAVA="${VERSION}"
    fi
fi

java -version 2>&1 | grep version | cut -d'"' -f2

# maven
echo "================================================================================"
_result "install maven..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v mvn > /dev/null || brew install maven
else
    VERSION=3.5.4

    if [ "${MAVEN}" != "${VERSION}" ] || [ "$(command -v mvn)" == "" ]; then
        _result " ${MAVEN} >> ${VERSION}"

        curl -L http://apache.tt.co.kr/maven/maven-3/${VERSION}/binaries/apache-maven-${VERSION}-bin.tar.gz | tar xz
        sudo mv -f apache-maven-${VERSION} /usr/local/
        sudo ln -sf /usr/local/apache-maven-${VERSION}/bin/mvn /usr/local/bin/mvn

        MAVEN="${VERSION}"
    fi
fi

mvn -version | grep "Apache Maven" | xargs | awk '{print $3}'

# heptio
echo "================================================================================"
_result "install heptio..."

VERSION=1.10.3

if [ "${HEPTIO}" != "${VERSION}" ] || [ "$(command -v heptio-authenticator-aws)" == "" ]; then
    _result " ${HEPTIO} >> ${VERSION}"

    curl -LO https://amazon-eks.s3-us-west-2.amazonaws.com/${VERSION}/2018-06-05/bin/${OS_NAME}/amd64/heptio-authenticator-aws
    chmod +x heptio-authenticator-aws && sudo mv heptio-authenticator-aws /usr/local/bin/heptio-authenticator-aws

    HEPTIO="${VERSION}"
fi

echo "${VERSION}"

# guard
echo "================================================================================"
_result "install guard..."

# VERSION=$(curl -s https://api.github.com/repos/appscode/guard/releases/latest | jq -r '.tag_name')
VERSION=0.1.4

if [ "${GUARD}" != "${VERSION}" ] || [ "$(command -v guard)" == "" ]; then
    _result " ${GUARD} >> ${VERSION}"

    curl -LO https://github.com/appscode/guard/releases/download/${VERSION}/guard-${OS_NAME}-amd64
    chmod +x guard-${OS_NAME}-amd64 && sudo mv guard-${OS_NAME}-amd64 /usr/local/bin/guard

    GUARD="${VERSION}"
fi

guard version 2>&1 | grep 'Version ' | xargs | awk '{print $3}'

# clean
echo "================================================================================"
_result "clean all..."

if [ "${OS_TYPE}" == "apt" ]; then
    sudo apt clean all
    sudo apt autoremove -y
elif [ "${OS_TYPE}" == "yum" ]; then
    sudo yum clean all
elif [ "${OS_TYPE}" == "brew" ]; then
    brew cleanup
fi

echo "================================================================================"

cat << EOF > ${CONFIG}
# version
DATE="${DATE}"
KUBECTL="${KUBECTL}"
KOPS="${KOPS}"
HELM="${HELM}"
DRAFT="${DRAFT}"
ISTIOCTL="${ISTIOCTL}"
JENKINSX="${JENKINSX}"
TERRAFORM="${TERRAFORM}"
NODE="${NODE}"
JAVA="${JAVA}"
MAVEN="${MAVEN}"
HEPTIO="${HEPTIO}"
GUARD="${GUARD}"
EOF

_success "done."