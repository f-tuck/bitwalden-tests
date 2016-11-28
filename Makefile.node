NPM=./build/node/bin/npm
NODE=./build/node/bin/node
NODE_VERSION=4.4.6
NODEENV_VERSION=0.13.6

default: deps

deps: build/node/bin/node node_modules

.PHONY: clean

build/nodeenv-src/nodeenv.py:
	git clone --branch $(NODEENV_VERSION) https://github.com/ekalinin/nodeenv.git build/nodeenv-src

$(NODE) $(NPM): build/nodeenv-src/nodeenv.py
	python ./build/nodeenv-src/nodeenv.py --node=$(NODE_VERSION) --prebuilt build/node
	find build/node -exec touch {} \;

node_modules: build/node/bin/npm package.json
	./build/node/bin/npm install

clean:
	rm -rf node_modules
