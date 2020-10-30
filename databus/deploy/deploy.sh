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
    docker tag "${Image}:${Version}" "${RegistryServer}/${Image}:${Version}"
    docker push "${RegistryServer}/${Image}:${Version}"
}

function SQLTpl() {
    cat > tmp/create_table.sql <<EOF
CREATE DATABASE IF NOT EXISTS ${MysqlDatabase};
CREATE USER IF NOT EXISTS '${MysqlUsername}'@'%' IDENTIFIED BY '${MysqlPassword}';
GRANT ALL PRIVILEGES ON ${MysqlDatabase}.* TO '${MysqlUsername}'@'%';

USE ${MysqlDatabase};
CREATE TABLE IF NOT EXISTS \`shici\` (
  \`id\` bigint(20) NOT NULL,
  \`title\` varchar(64) NOT NULL,
  \`author\` varchar(64) NOT NULL,
  \`dynasty\` varchar(32) NOT NULL,
  \`content\` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci NOT NULL,
  PRIMARY KEY (\`id\`),
  KEY \`title_idx\` (\`title\`),
  KEY \`author_idx\` (\`author\`),
  KEY \`dynasty_idx\` (\`dynasty\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF
    kubectl run -n prod -it --rm sql --image=mysql:5.7.30 --restart=Never -- mysql -uroot -hmysql -p${MysqlRootPassword} -e "$(cat tmp/create_table.sql)"
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
    cat > tmp/chart.yaml <<EOF
namespace: ${Namespace}
name: ${Name}
activeDeadlineSeconds: 86400

image:
  repository: ${RegistryServer}/${Image}
  tag: ${Version}
  pullPolicy: Always

imagePullSecrets:
  name: ${PullSecrets}

config: |
  {
    "producer": {
      "type": "file",
      "filename": "data/analyst/www.shicimingju.com/shici.json"
    },
    "consumer": {
      "type": "mysql",
      "mysql": {
        "username": "${MysqlUsername}",
        "password": "${MysqlPassword}",
        "database": "${MysqlDatabase}",
        "host": "${MysqlServer}",
        "port": 3306,
        "connMaxLifeTime": "60s",
        "maxIdleConns": 10,
        "maxOpenConns": 20
      },
      "table": "shici",
      "fields": ["id", "title", "author", "dynasty", "content"],
      "keyMap": {
        "id": "@lineno"
      }
    },
    "parallel": 1
  }
EOF
}

function Run() {
     kubectl run -n "${Namespace}" -it --rm "${Name}" --image="${RegistryServer}/${Image}:${Version}" --restart=Never -- /bin/bash
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
    echo "  sh deploy.sh render"
    echo "  sh deploy.sh install"
    echo "  sh deploy.sh upgrade"
    echo "  sh deploy.sh delete"
    echo "  sh deploy.sh diff"
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
        "render") Render;;
        "install") Render && Install;;
        "upgrade") Render && Upgrade;;
        "diff") Render && Diff;;
        "delete") Delete;;
        "run") Run;;
    esac
}

main "$@"
