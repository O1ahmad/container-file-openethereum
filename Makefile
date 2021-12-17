filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/openethereum
build_type      ?=      package

build:
	DOCKER_BUILDKIT=1 docker build --tag $(image_repo):$(version) --target build-condition --build-arg build_type=$(build_type) --build-arg openethereum_version=$(version) .

test:
	DOCKER_BUILDKIT=1 docker build --tag openethereum:test --target test --build-arg build_type=$(build_type) --build-arg openethereum_version=$(version) . && docker run --env-file test/test.env openethereum:test

test-compose:
	echo "image=${image_repo}:${version}" > compose/.env-test
	cd compose && docker-compose --env-file .env-test config && docker-compose --env-file .env-test up -d && \
	sleep 5 && docker-compose logs 2>&1 | grep "Configured for Kovan Testnet" && docker-compose logs 2>&1 | grep "Listening for new connections" && \
	docker-compose down && rm .env-test

release:
	DOCKER_BUILDKIT=1 docker build --tag $(image_repo):$(version) --target release --build-arg build_type=$(build_type) --build-arg openethereum_version=$(version) .
	docker push $(image_repo):$(version)

latest:
	docker tag $(image_repo):$(version) $(image_repo):latest
	docker push $(image_repo):latest

tools:
	DOCKER_BUILDKIT=1 docker build --tag $(image_repo):$(version)-tools --target tools --build-arg build_type=$(build_type) --build-arg openethereum_version=$(version) .
	docker push ${image_repo}:$(version)-tools

.PHONY: build test release tools latest
