binary=crawler
dockeruser=hatlonely
gituser=hatlonely
repository=crawler
version=1.0.0
export GOPROXY=https://goproxy.io

.PHONY: build
build: cmd/main.go Makefile
	mkdir -p build/bin
	go build -ldflags "-X 'main.Version=`sh ../scripts/version.sh`'" cmd/main.go && mv main build/bin/${binary} && cp -r config build/

vendor: go.mod go.sum
	@echo "install golang dependency"
	go mod vendor

.PHONY: dockerenv
dockerenv:
	if [ -z "$(shell docker network ls --filter name=testnet -q)" ]; then \
		docker network create -d bridge testnet; \
	fi
	if [ -z "$(shell docker ps -a --filter name=go-build-env -q)" ]; then \
		docker run --name go-build-env --network testnet -d hatlonely/go-build-env:1.0.0 tail -f /dev/null; \
	fi

.PHONY: cleandockerenv
cleandockerenv:
	if [ ! -z "$(shell docker ps -a --filter name=go-build-env -q)" ]; then \
		docker stop go-build-env  && docker rm go-build-env; \
	fi
	if [ ! -z "$(shell docker network ls --filter name=testnet -q)" ]; then \
		docker network rm testnet; \
	fi

.PHONY: image
image: dockerenv
	rm -rf docker
	docker exec go-build-env rm -rf /data/src/${gituser}/${repository}
	docker exec go-build-env mkdir -p /data/src/${gituser}/${repository}/crawler
	docker cp ../scripts go-build-env:/data/src/${gituser}/${repository}
	docker cp ../go.mod go-build-env:/data/src/${gituser}/${repository}
	docker cp ../go.sum go-build-env:/data/src/${gituser}/${repository}
	docker cp cmd go-build-env:/data/src/${gituser}/${repository}/crawler/
	docker cp config go-build-env:/data/src/${gituser}/${repository}/crawler/
	docker cp Makefile go-build-env:/data/src/${gituser}/${repository}/crawler/
	docker exec go-build-env bash -c "cd /data/src/${gituser}/${repository}/crawler && make build"
	docker cp go-build-env:/data/src/${gituser}/${repository}/crawler/build/ docker/
	docker build --tag=hatlonely/${repository}:${version} .

