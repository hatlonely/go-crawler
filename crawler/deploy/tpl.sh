#!/usr/bin/env bash

function main() {
  mkdir -p tmp
  gomplate -f "environment.sh.tpl" -c .="$HOME/.gomplate/crawler.json" > tmp/environment.sh
}

main "$@"
