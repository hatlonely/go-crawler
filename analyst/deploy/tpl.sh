#!/usr/bin/env bash

function main() {
    mkdir -p tmp
    gomplate -f "environment.sh.tpl" -c .="$HOME/.gomplate/root.json" > tmp/environment.sh
}

main "$@"
