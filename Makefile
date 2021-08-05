filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/demo

build:
	docker build -t $(image_repo):$(version) .

test:
	docker build --target test -t demo:test . && docker run demo:test

release:
	docker build --no-cache -t $(image_repo):$(version) .
	docker push $(image_repo):$(version)

latest:
	docker tag $(image_repo):$(version) $(image_repo):latest
	docker push $(image_repo):latest

.PHONY: build test release latest
