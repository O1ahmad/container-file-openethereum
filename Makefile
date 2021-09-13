filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/openethereum

build:
	docker build --build-arg openethereum_version=$(version) --tag $(image_repo):build-$(version) .

test:
	docker build --build-arg openethereum_version=$(version) --target test --tag openethereum:test . && docker run --env-file test/test.env openethereum:test

test-compose:
	cd compose && docker-compose config && docker-compose up -d && \
	sleep 5 && docker-compose logs 2>&1 | grep "Configured for Kovan Testnet" && docker-compose logs 2>&1 | grep "Listening for new connections" && \
	docker-compose down

release:
	docker build --build-arg openethereum_version=$(version) --target release --tag $(image_repo):$(version) .
	docker push $(image_repo):$(version)

latest:
	docker tag $(image_repo):$(version) $(image_repo):latest
	docker push $(image_repo):latest

tools:
	docker build --build-arg openethereum_version=$(version) --target tools --tag $(image_repo):$(version)-tools .
	docker push ${image_repo}:$(version)-tools

.PHONY: build test release latest
