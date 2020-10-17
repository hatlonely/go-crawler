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
    docker tag ${Image}:${Version} ${RegistryServer}/${Image}:${Version}
    docker login --username="${RegistryUser}" --password="${RegistryPassword}" "${RegistryServer}"
    docker push ${RegistryServer}/${Image}:${Version}
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
        --docker-server="${RegistryServer}" \
        --docker-username="${RegistryUser}" \
        --docker-password="${RegistryPassword}" \
        --namespace="prod" &&
    Info "[kubectl create secret docker-registry ${PullSecrets}] success" ||
    Warn "[kubectl create secret docker-registry ${PullSecrets}] failed"
}

function CreateConfigMap() {
    CreateNamespaceIfNotExists || return 1

cat > tmp/${ConfigmapFile} <<EOF
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

    kubectl get configmap "${Configmap}" -n "${Namespace}" 2>/dev/null 1>&2 && return 0
    kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=tmp/${ConfigmapFile} &&
    Info "[kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=tmp/${ConfigmapFile}] success" ||
    Warn "[kubectl create configmap "${Configmap}" -n "${Namespace}" --from-file=${ConfigmapFile}=tmp/${ConfigmapFile}] fail"
}

function CreatePVCIfNotExists() {
    cat > tmp/pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: prod
  name: ${PVCName}
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
    kubectl apply -f tmp/pvc.yaml &&
    Info "[kubectl apply -f tmp/pvc.yaml] success" ||
    Warn "[kubectl apply -f tmp/pvc.yaml] failed"
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
        command: ["bin/crawler", "-c", "config/shicimingju.json"]
        volumeMounts:
        - name: ${Name}-data
          mountPath: /var/docker/crawler/data
        - name: ${Name}-config
          mountPath: /var/docker/crawler/config
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

    kubectl get job -n "${Namespace}" "${Name}" && kubectl delete job -n "${Namespace}" "${Name}"
    kubectl apply -f tmp/job.yaml &&
    Info "[kubectl apply -f tmp/job.yaml] success" ||
    Warn "[kubectl apply -f tmp/job.yaml] failed"
}

function Help() {
    echo "sh deploy.sh <action>"
    echo "example"
    echo "  sh deploy.sh build"
    echo "  sh deploy.sh configmap"
    echo "  sh deploy.sh secret"
    echo "  sh deploy.sh job"
}

function main() {
    if [ -z "$1" ]; then
        Help
        return 0
    fi

    case "$1" in
        "build") Build;;
        "configmap") CreateConfigMap;;
        "secret") CreatePullSecretsIfNotExists;;
        "job") CreateJob;;
    esac
}

main "$@"
