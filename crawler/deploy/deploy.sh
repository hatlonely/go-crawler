#!/usr/bin/env bash

source tmp/environment.sh

function Trac() {
    echo "[TRAC] [$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

function Info() {
    echo "\033[1;32m[INFO] [$(date +"%Y-%m-%d %H:%M:%S")] $1\033[0m"
}

function Warn() {
    echo "\033[1;31m[WARN] [$(date +"%Y-%m-%d %H:%M:%S")] $1\033[0m"
    return 1
}

function Build() {
    cd .. && make image && cd -
    docker login --username="${RegistryUsername}" --password="${RegistryPassword}" "${RegistryServer}"
    docker tag "${ImageRepository}:${ImageTag}" "${RegistryServer}/${ImageRepository}:${ImageTag}"
    docker push "${RegistryServer}/${ImageRepository}:${ImageTag}"
}

function CreateNamespaceIfNotExists() {
    kubectl get namespaces "${Namespace}" 2>/dev/null 1>&2 && return 0
    kubectl create namespace "${Namespace}" &&
    Info "create namespace ${Namespace} success" ||
    Warn "create namespace ${Namespace} failed"
}

function CreatePullSecretsIfNotExists() {
    kubectl get secret "${PullSecrets}" -n "${Namespace}" 2>/dev/null 1>&2 && return 0
    kubectl create secret docker-registry "${PullSecrets}" \
        --docker-server="${RegistryServer}" \
        --docker-username="${RegistryUsername}" \
        --docker-password="${RegistryPassword}" \
        --namespace="prod" &&
    Info "[kubectl create secret docker-registry ${PullSecrets}] success" ||
    Warn "[kubectl create secret docker-registry ${PullSecrets}] failed"
}

function Render() {
    debug="false"
    if [ "$1" == "--debug" ]; then
        debug="true"
    fi

    cat > tmp/chart.yaml <<EOF
debug: ${debug}
namespace: ${Namespace}
name: ${Name}
activeDeadlineSeconds: 86400

pvc:
  name: ${PVCName}
  storage: 50Gi
  storageClassName: nfs-client

image:
  repository: ${RegistryServer}/${ImageRepository}
  tag: ${ImageTag}
  pullPolicy: Always

imagePullSecrets:
  name: ${PullSecrets}

config: |
  {
    "directory": "data/crawler/www.shicimingju.com",
    "parallel": 1,
    "delay": "5s",
    "maxDepth": 30,
    "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36",
    "allowDomains": "www.shicimingju.com",
    "startPage": "https://www.shicimingju.com/"
  }
EOF
}

function Run() {
     kubectl run -n "${Namespace}" -it --rm "${Name}" --image="${RegistryServer}/${ImageRepository}:${ImageTag}" --restart=Never -- /bin/bash
}

function Install() {
    helm install "${Name}" -n "${Namespace}" "./chart/${Name}" -f "tmp/chart.yaml"
}

function Upgrade() {
    helm upgrade "${Name}" -n "${Namespace}" "./chart/${Name}" -f "tmp/chart.yaml"
}

function Delete() {
    helm delete "${Name}" -n "${Namespace}"
}

function Diff() {
    helm diff upgrade "${Name}" -n "${Namespace}" "./chart/${Name}" -f "tmp/chart.yaml"
}

function Help() {
    echo "sh deploy.sh <action>"
    echo "example"
    echo "  sh deploy.sh build"
    echo "  sh deploy.sh sql"
    echo "  sh deploy.sh secret"
    echo "  sh deploy.sh render [--debug]"
    echo "  sh deploy.sh install [--debug]"
    echo "  sh deploy.sh upgrade [--debug]"
    echo "  sh deploy.sh delete"
    echo "  sh deploy.sh diff [--debug]"
    echo "  sh deploy.sh run"
}

function main() {
    if [ -z "$1" ]; then
        Help
        return 0
    fi

    case "$1" in
        "build") Build;;
        "sql") SQLTpl;;
        "secret") CreatePullSecretsIfNotExists;;
        "render") Render "$2";;
        "install") Render "$2" && Install;;
        "upgrade") Render "$2" && Upgrade;;
        "diff") Render "$2" && Diff;;
        "delete") Delete;;
        "run") Run;;
    esac
}

main "$@"
