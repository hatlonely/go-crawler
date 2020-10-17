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

function CreateNamespaceIfNotExists() {
    kubectl get namespaces "${Namespace}" 2>/dev/null 1>&2 && return 0
    kubectl create namespace "${Namespace}" &&
    Info "create namespace ${Namespace} success" ||
    Warn "create namespace ${Namespace} failed"
}

function CreatePullSecretsIfNotExists() {
    kubectl get secret "${PullSecrets}" -n "${Namespace}" 2>/dev/null 1>&2 && return 0
    kubectl create secret docker-registry ${PullSecrets} \
        --docker-server="docker.io" \
        --docker-username="${DockerUser}" \
        --docker-password="${DockerPassword}" \
        --namespace="prod" &&
    Info "[kubectl create pull secret ${DockerUser}] success" ||
    Warn "[kubectl create pull secret ${DockerPassword}] failed"
}

function CreateConfigMap() {
    CreateNamespaceIfNotExists || return 1

cat > tmp/${ConfigmapFile} <<EOF
{
  "book": {
    "root": "data/crawler/www.shicimingju.com",
    "out":  "data/analyst/www.shicimingju.com/book.json"
  },
  "shiCi": {
    "root": "data/crawler/www.shicimingju.com",
    "out":  "data/analyst/www.shicimingju.com/shici.json"
  }
}
EOF

    kubectl get configmap "${Configmap}" -n "${Namespace}" 2>/dev/null 1>&2 && return 0

    kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=tmp/${ConfigmapFile} &&
    Info "[kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=tmp/${ConfigmapFile}] success" ||
    Warn "[kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=tmp/${ConfigmapFile}] fail"
}

function CreateJob() {
    cat > tmp/job.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${Name}
  namespace: ${Namespace}
spec:
  parallelism: 1
  completions: 1
  activeDeadlineSeconds: 1800
  backoffLimit: 1
  template:
    metadata:
      name: ${Name}
    spec:
      imagePullSecrets:
      - name: ${PullSecrets}
      containers:
      - name: ${Name}
        imagePullPolicy: Always
        image: ${Image}:${Version}
        command: [ "bin/analyst", "-c", "config/shicimingju.json" ]
        volumeMounts:
        - name: ${Name}-data
          mountPath: /var/docker/${Name}/data
        - name: ${Name}-config
          mountPath: /var/docker/${Name}/config
      volumes:
      - name: ${Name}-data
        persistentVolumeClaim:
          claimName: ${PVCName}
      - name: ${Name}-config
        projected:
          sources:
          - configMap:
              name: ${Configmap}
              items:
                - key: ${ConfigmapFile}
                  path: shicimingju.json
      restartPolicy: OnFailure
EOF
    kubectl apply -f tmp/job.yaml &&
    Info "[kubectl apply -f tmp/job.yaml] success" ||
    Warn "[kubectl apply -f tmp/job.yaml] failed"
}

function main() {
    CreateConfigMap || return 2
    CreatePullSecretsIfNotExists || return 3
    CreateJob
}

main "$@"
