filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/openethereum

build:
	docker build --build-arg openethereum_version=$(version) -t $(image_repo):build-$(version) .

test:
	docker build --build-arg openethereum_version=$(version) --target test -t openethereum:test . && docker run --env-file test/test.env openethereum:test

release:
	docker build --build-arg openethereum_version=$(version) --target release --no-cache -t $(image_repo):$(version) .
	docker push $(image_repo):$(version)

latest:
	docker tag $(image_repo):$(version) $(image_repo):latest
	docker push $(image_repo):latest

tools:
	docker build --build-arg openethereum_version=$(version) --target tools -t $(image_repo):$(version)-tools .
	docker push ${image_repo}:$(version)-tools

.PHONY: build test release latest
