BIN = docker-inspect
BUILD_DIR = ./dist/docker-inspect_linux_amd64
BUILD_PATH = $(BUILD_DIR)/$(BIN)
PWD := ${CURDIR}
PRODUCTION_REGISTRY = docker.io
TEST_IMAGE = busybox:latest

all: gofmt clean build

## For CI

ci-unit-test:
	go test -cover -v -race ./...

ci-static-analysis:
	grep -R 'const allowTestDataCapture = false' runtime/ui/viewmodel
	go vet ./...
	@! gofmt -s -l . 2>&1 | grep -vE '^\.git/' | grep -vE '^\.cache/'
	golangci-lint run

ci-install-go-tools:
	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sudo sh -s -- -b /usr/local/bin/ latest

ci-install-ci-tools:
	curl -sfL https://install.goreleaser.com/github.com/goreleaser/goreleaser.sh | sudo sh -s -- -b /usr/local/bin/ "v0.122.0"

ci-docker-login:
	echo '${DOCKER_PASSWORD}' | docker login -u '${DOCKER_USERNAME}' --password-stdin '${PRODUCTION_REGISTRY}'

ci-docker-logout:
	docker logout '${PRODUCTION_REGISTRY}'

ci-publish-release:
	goreleaser --rm-dist

ci-build-snapshot-packages:
	goreleaser \
		--snapshot \
		--skip-publish \
		--rm-dist

ci-release:
	goreleaser release --rm-dist

# todo: add --pull=never when supported by host box
ci-test-production-image:
	docker run \
		--rm \
		-t \
		-v //var/run/docker.sock://var/run/docker.sock \
		'${PRODUCTION_REGISTRY}/nextlinux/docker-inspect:latest' \
			'${TEST_IMAGE}' \
			--ci

ci-test-deb-package-install:
	docker run \
		-v //var/run/docker.sock://var/run/docker.sock \
		-v /${PWD}://src \
		-w //src \
		ubuntu:latest \
			/bin/bash -x -c "\
				apt update && \
				apt install -y curl && \
				curl -L 'https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz' | \
					tar -vxzf - docker/docker --strip-component=1 && \
					mv docker /usr/local/bin/ &&\
				docker version && \
				apt install ./dist/docker-inspect_*_linux_amd64.deb -y && \
				docker-inspect --version && \
				docker-inspect '${TEST_IMAGE}' --ci \
			"

ci-test-rpm-package-install:
	docker run \
		-v //var/run/docker.sock://var/run/docker.sock \
		-v /${PWD}://src \
		-w //src \
		fedora:latest \
			/bin/bash -x -c "\
				curl -L 'https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz' | \
					tar -vxzf - docker/docker --strip-component=1 && \
					mv docker /usr/local/bin/ &&\
				docker version && \
				dnf install ./dist/docker-inspect_*_linux_amd64.rpm -y && \
				docker-inspect --version && \
				docker-inspect '${TEST_IMAGE}' --ci \
			"

ci-test-linux-run:
	chmod 755 ./dist/docker-inspect_linux_amd64/docker-inspect && \
	./dist/docker-inspect_linux_amd64/docker-inspect '${TEST_IMAGE}'  --ci && \
    ./dist/docker-inspect_linux_amd64/docker-inspect --source docker-archive .data/test-kaniko-image.tar  --ci --ci-config .data/.docker-inspect-ci

# we're not attempting to test docker, just our ability to run on these systems. This avoids setting up docker in CI.
ci-test-mac-run:
	chmod 755 ./dist/docker-inspect_darwin_amd64/docker-inspect && \
	./dist/docker-inspect_darwin_amd64/docker-inspect --source docker-archive .data/test-docker-image.tar  --ci --ci-config .data/.docker-inspect-ci

# we're not attempting to test docker, just our ability to run on these systems. This avoids setting up docker in CI.
ci-test-windows-run:
	./dist/docker-inspect_windows_amd64/docker-inspect --source docker-archive .data/test-docker-image.tar  --ci --ci-config .data/.docker-inspect-ci



## For development

run: build
	$(BUILD_PATH) build -t docker-inspect-example:latest -f .data/Dockerfile.example .

run-large: build
	$(BUILD_PATH) amir20/clashleaders:latest

run-podman: build
	podman build -t docker-inspect-example:latest -f .data/Dockerfile.example .
	$(BUILD_PATH) localhost/docker-inspect-example:latest --engine podman

run-podman-large: build
	$(BUILD_PATH) docker.io/amir20/clashleaders:latest --engine podman

run-ci: build
	CI=true $(BUILD_PATH) docker-inspect-example:latest --ci-config .data/.docker-inspect-ci

build: gofmt
	go build -o $(BUILD_PATH)

generate-test-data:
	docker build -t docker-inspect-test:latest -f .data/Dockerfile.test-image . && docker image save -o .data/test-docker-image.tar docker-inspect-test:latest && echo 'Exported test data!'

test: gofmt
	./.scripts/test-coverage.sh

dev:
	docker run -ti --rm -v $(PWD):/app -w /app -v docker-inspect-pkg:/go/pkg/ golang:1.13 bash

clean:
	rm -rf dist
	go clean

gofmt:
	go fmt -x ./...