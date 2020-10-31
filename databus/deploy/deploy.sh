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

function ESIndex() {
    cat > tmp/create_index.json <<EOF
{
    "settings": {
        "analysis": {
            "tokenizer": {
                "ngram_tokenizer": {
                    "type": "nGram",
                    "min_gram": 1,
                    "max_gram": 10,
                    "token_chars": [
                        "letter",
                        "digit"
                    ]
                }
            },
            "analyzer": {
                "ngram_tokenizer_analyzer": {
                    "type": "custom",
                    "tokenizer": "ngram_tokenizer",
                    "filter": [
                        "lowercase"
                    ]
                }
            }
        },
        "max_ngram_diff": "10"
	},
	"mappings": {
		"properties": {
			"id": {
				"type": "long"
			},
			"title": {
				"type": "text",
				"analyzer": "ngram_tokenizer_analyzer",
				"search_analyzer": "standard"
			},
			"author": {
				"type": "text",
				"analyzer": "ngram_tokenizer_analyzer",
				"search_analyzer": "standard"
			},
			"dynasty": {
				"type": "text",
				"analyzer": "ngram_tokenizer_analyzer",
				"search_analyzer": "standard"
			},
			"content": {
				"type": "text",
				"analyzer": "ngram_tokenizer_analyzer",
				"search_analyzer": "standard"
			}
		}
	}
}
EOF

#    curl -XPUT -H "Content-Type: application/json" -d "$(cat tmp/create_index.json)" "127.0.0.1:9200/${ElasticSearchIndex}"
    kubectl run -n prod -it --rm esindex --image=centos:centos7 --restart=Never -- curl -XPUT -H "Content-Type: application/json" -d "$(cat tmp/create_index.json)" "${ElasticSearchServer}/${ElasticSearchIndex}"
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

    eval "cat > tmp/chart.yaml <<EOF
$(cat "tpl/${ChartTpl}")
EOF
"
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
    echo "  sh deploy.sh es"
    echo "  sh deploy.sh secret"
    echo "  sh deploy.sh render [--debug]"
    echo "  sh deploy.sh install [--debug]"
    echo "  sh deploy.sh upgrade [--debug]"
    echo "  sh deploy.sh delete"
    echo "  sh deploy.sh diff [--debug]"
    echo "  sh deploy.sh run"
}

function main() {
    case "$1" in
        "build") Build;;
        "sql") SQLTpl;;
        "es") ESIndex;;
        "secret") CreatePullSecretsIfNotExists;;
        "render") Render "$2";;
        "install") Render "$2" && Install;;
        "upgrade") Render "$2" && Upgrade;;
        "diff") Render "$2" && Diff;;
        "delete") Delete;;
        "run") Run;;
        *) Help;;
    esac
}

main "$@"
