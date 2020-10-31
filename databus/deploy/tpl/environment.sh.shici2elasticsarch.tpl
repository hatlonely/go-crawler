#!/usr/bin/env bash

Namespace="prod"
Name="go-crawler-databus"
RegistryServer="{{.registry.server}}"
RegistryUsername="{{.registry.username}}"
RegistryPassword="{{.registry.password}}"
ElasticSearchServer="elasticsearch-master:9200"
ElasticSearchIndex="shici"
PVCName="crawler-pvc"
PullSecrets="hatlonely-pull-secrets"
ImageRepository="hatlonely/go-crawler-databus"
ImageTag="1.0.0"
ChartTpl="chart.shici2elasticsearch.yaml"
