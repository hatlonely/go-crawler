#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-analyst"
RegistryServer={{.registry.server}}
RegistryUser={{.registry.user}}
RegistryPassword={{.registry.password}}
PVCName="crawler-pvc"
Configmap="go-crawler-analyst"
ConfigmapFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="hatlonely/go-crawler-analyst"
Version="1.0.0"