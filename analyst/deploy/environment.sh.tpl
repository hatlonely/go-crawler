#!/usr/bin/env bash

Namespace="prod"
Name="crawler"
DockerUser={{.docker.user}}
DockerPassword={{.docker.password}}
PVCName="crawler-pvc"
Configmap="go-crawler"
ConfigmapFile="analyst.shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="docker.io/hatlonely/go-crawler-analyst"
Version="1.0.0"