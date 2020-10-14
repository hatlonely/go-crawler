#!/usr/bin/env bash

Namespace="prod"
Name="crawler"
DockerUser={{.docker.user}}
DockerPassword={{.docker.password}}
Configmap="crawler"
ConfigmapFile="crawler-shicimingju.json"
ConfigFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="docker.io/hatlonely/crawler"
Version="1.0.0"
