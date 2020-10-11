binary=crawler
export GOPROXY=https://goproxy.io

.PHONY: build
build: cmd/main.go
	mkdir -p build/bin
	go build -ldflags "-X 'main.Version=`sh ../scripts/version.sh`'" cmd/main.go && mv main build/bin/${binary} && cp -r config build/

codegen: api/ancient.proto
	mkdir -p api/gen/go && mkdir -p api/gen/swagger
	protoc -I.. -I. --gofast_out=plugins=grpc,paths=source_relative:api/gen/go/ $<
	protoc -I.. -I. --grpc-gateway_out=logtostderr=true,paths=source_relative:api/gen/go $<
	protoc -I.. -I. --swagger_out=logtostderr=true:api/gen/swagger $<
