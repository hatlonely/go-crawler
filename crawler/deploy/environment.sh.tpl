#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-crawler"
RegistryServer={{.registry.server}}
RegistryUsername={{.registry.username}}
RegistryPassword={{.registry.password}}
PVCName="crawler-pvc"
Configmap="go-crawler-crawler"
ConfigmapFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
ImageRepository="hatlonely/go-crawler-crawler"
ImageTag="1.0.0"
