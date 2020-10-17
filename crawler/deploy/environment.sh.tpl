#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-crawler"
DockerUser={{.docker.user}}
DockerPassword={{.docker.password}}
PVCName="crawler-pvc"
Configmap="go-crawler-crawler"
ConfigmapFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="docker.io/hatlonely/go-crawler-crawler"
Version="1.0.0"
