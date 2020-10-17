#!/usr/bin/env bash

Namespace="prod"
Name="crawler"
DockerUser={{.docker.user}}
DockerPassword={{.docker.password}}
Configmap="go-crawler"
ConfigmapFile="crawler/shicimingju.json"
ConfigFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="docker.io/hatlonely/go-crawler/crawler"
Version="1.0.0"
