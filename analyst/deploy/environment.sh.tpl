#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-analyst"
RegistryServer={{.registry.server}}
RegistryUsername={{.registry.username}}
RegistryPassword={{.registry.password}}
PVCName="crawler-pvc"
Configmap="go-crawler-analyst"
ConfigmapFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
ImageRepository="hatlonely/go-crawler-analyst"
ImageTag="1.0.0"
