#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-crawler"
RegistryServer={{.registry.server}}
RegistryUser={{.registry.user}}
RegistryPassword={{.registry.password}}
PVCName="crawler-pvc"
Configmap="go-crawler-crawler"
ConfigmapFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="${RegistryServer}/hatlonely/go-crawler-crawler"
Version="1.0.0"
