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

function CreateConfigMap() {
    CreateNamespaceIfNotExists || return 1

    kubectl get configmap "${Configmap}" -n "${Namespace}" 2>/dev/null 1>&2 && return 0
    kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=../config/${ConfigFile} &&
    Info "[kubectl create configmap crawler -n prod --from-file=crawler-shicimingju.json=config/shicimingju.json] success" ||
    Warn "[kubectl create configmap crawler -n prod --from-file=crawler-shicimingju.json=config/shicimingju.json] fail"
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

function CreatePVCIfNotExists() {
    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: prod
  name: crawler-pvc
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  resources:
    requests:
      storage: 50Gi
  storageClassName: nfs-client
  selector:
EOF
}

function CreateJob() {
    kubectl apply -f - <<EOF
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
      name: crawler
    spec:
      imagePullSecrets:
      - name: ${PullSecrets}
      containers:
      - name: ${Name}
        imagePullPolicy: Always
        image: ${Image}:${Version}
        command: ["bin/crawler", "-c", "config/shicimingju.json"]

      volumes:
      - name: crawler-data
        persistentVolumeClaim:
          claimName: crawler-pvc
      - name: crawler-config
        projected:
          sources:
          - configMap:
              name: crawler
              items:
                - key: crawler-shicimingju.json
                  path: shicimingju.json
      restartPolicy: OnFailure
EOF
}

function main() {
    CreateConfigMap || return 2
    CreatePullSecretsIfNotExists || return 3
    CreateJob
}

main "$@"
