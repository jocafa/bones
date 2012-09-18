# Options
###############################################################################
PROJECT_NAME ?= bones
MOCHA_REPORTER ?= dot

NODE_MODULES = node_modules
NODE_MODULES_BIN = $(NODE_MODULES)/.bin

# Shortcuts to Node Binaries
###############################################################################
ESPARSE = $(NODE_MODULES_BIN)/esparse
COFFEE = $(NODE_MODULES_BIN)/coffee
MOCHA = $(NODE_MODULES_BIN)/mocha
RJS = $(NODE_MODULES_BIN)/r.js
STYLUS = $(NODE_MODULES_BIN)/stylus
UGLIFYJS = $(NODE_MODULES_BIN)/uglifyjs
JSHINT = $(NODE_MODULES_BIN)/jshint

ALMONDJS = $(NODE_MODULES)/almond/almond.js


# Source and Build files
###############################################################################
SRC_JS_FILES = $(shell find src -name "*.js" -type f | sort)
SRC_JS_DEPS = $(join $(dir $(SRC_JS_FILES)),$(addsuffix .d,$(addprefix .,$(notdir $(SRC_JS_FILES)))))
BUILD_JS_FILES = $(patsubst src/%,build/plain/%,$(SRC_JS_FILES))

SRC_COFFEE_FILES = $(shell find src -name "*.coffee" -type f | sort)
BUILD_COFFEE_FILES = $(patsubst src/%,build/plain/%,$(SRC_COFFEE_FILES:.coffee=.js))

SRC_CSS_FILES = $(shell find src -name "*.css" -type f | sort)
BUILD_CSS_FILES = $(patsubst src/%,build/plain/%,$(SRC_CSS_FILES))

SRC_SCSS_FILES = $(shell find src -name "*.scss" -type f | sort)
BUILD_SCSS_FILES = $(patsubst src/%,build/plain/%,$(SRC_SCSS_FILES:.scss=.css))

SRC_STYL_FILES = $(shell find src -name "*.styl" -type f | sort)
BUILD_STYL_FILES = $(patsubst src/%,build/plain/%,$(SRC_STYL_FILES:.styl=.css))

# Test Files
###############################################################################
TEST_JS_FILES = $(shell find test -name "*-test.js" -type f | sort)

# Handy Targets
###############################################################################
all: \
	setup \
	build

clean:
	@rm -rf build
	@find src -name "*.d" -print0 | xargs -0 rm

setup: \
	node_modules \
	support

node_modules:
	@npm install

# Supporting Client-Side JS Libraries
###############################################################################
support: \
	support/jquery.js \
	support/underscore.js \
	support/backbone.js \
	support/moment.js \
	support/require.js \
	support/almond.js

support/jquery.js:
	@mkdir -p $(@D)
	@curl http://code.jquery.com/jquery-1.8.1.js > $@

support/underscore.js:
	@mkdir -p $(@D)
	@curl http://underscorejs.org/underscore.js > $@

support/backbone.js:
	@mkdir -p $(@D)
	@curl http://backbonejs.org/backbone.js > $@

support/require.js:
	@mkdir -p $(@D)
	@curl http://requirejs.org/docs/release/2.0.6/comments/require.js > $@

support/almond.js:
	@mkdir -p $(@D)
	@curl https://raw.github.com/jrburke/almond/latest/almond.js > $@

support/moment.js:
	@mkdir -p $(@D)
	@curl https://raw.github.com/timrwood/moment/1.7.0/moment.js > $@

# Builds
###############################################################################
deps: $(SRC_JS_DEPS)

.%.js.d: %.js
	@echo generating deps for $<
	@node scripts/deps.js $< > $@

%.min.js: %.js
	@rm -f $@
	@$(UGLIFYJS) < $< > $@

build: \
	deps \
	build/plain \
	build/$(PROJECT_NAME).js \
	build/$(PROJECT_NAME).min.js \
	build/$(PROJECT_NAME)-almond.js \
	build/$(PROJECT_NAME)-almond.min.js

build/plain: \
	$(BUILD_CSS_FILES) \
	$(BUILD_STYL_FILES) \
	$(BUILD_SCSS_FILES) \
	$(BUILD_JS_FILES) \
	$(BUILD_COFFEE_FILES)

$(BUILD_CSS_FILES): build/plain/%.css: src/%.css
	@mkdir -p $(@D)
	@cp $< $@

$(BUILD_STYL_FILES): build/plain/%.css: src/%.styl
	@mkdir -p $(@D)
	@stylus < $< > $@

$(BUILD_SCSS_FILES): build/plain/%.css: src/%.scss
	@compass compile $< \
		--sass-dir=src \
		--css-dir=build/plain \
		--javascripts-dir=build/plain

$(BUILD_JS_FILES): build/plain/%.js: src/%.js
	@mkdir -p $(@D)
	cp $< $@

$(BUILD_COFFEE_FILES): build/plain/%.js: src/%.coffee
	@mkdir -p $(@D)
	@coffee -sc < $< > $@

build/$(PROJECT_NAME).js: support $(BUILD_JS_FILES)
	@$(RJS) -o \
		baseUrl=./build/plain \
		out=build/$(PROJECT_NAME).js \
		name=$(PROJECT_NAME) \
		optimize=none \
		wrap=true

build/$(PROJECT_NAME)-almond.js: support $(BUILD_JS_FILES)
	@$(RJS) -o \
		baseUrl=./build/plain \
		name=$(PROJECT_NAME) \
		include=../../support/almond.js \
		out=$@ \
		wrap=true \
		optimize=none \
		insertRequire=$(PROJECT_NAME)

ifneq "$(MAKECMDGOALS)" "clean"
-include $(SRC_JS_DEPS)
endif

# Testing
###############################################################################
test: test-unit

test-unit: build/plain
	@$(MOCHA) --reporter $(MOCHA_REPORTER) $(TEST_JS_FILES)

test-phantom:
	@phantomjs --config=test/phantomjs-config.json test/phantomjs-runner.js

test-all: test-unit test-phantom

# Misc.
###############################################################################
.PHONY: \
	clean \
	setup \
	test \
	test-all \
	test-unit \
	test-phantom
