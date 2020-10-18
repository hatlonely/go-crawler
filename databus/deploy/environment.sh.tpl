#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-databus"
RegistryServer={{.registry.server}}
RegistryUsername={{.registry.username}}
RegistryPassword={{.registry.password}}
MysqlServer={{.mysql.server}}
MysqlRootPassword={{.mysql.rootPassword}}
MysqlUsername={{.mysql.username}}
MysqlPassword={{.mysql.password}}
MysqlDatabase="ancient"
PVCName="crawler-pvc"
Configmap="go-crawler-databus"
ConfigmapFile="shicimingju.json"
PullSecrets="hatlonely-pull-secrets"
Image="hatlonely/go-crawler-databus"
Version="1.0.0"