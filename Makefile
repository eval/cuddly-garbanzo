# GraalVM {{{
PLATFORM := $(shell uname -s | tr '[:upper:]' '[:lower:]')
GRAAL_ROOT ?= /tmp/.graalvm
GRAAL_VERSION ?= 22.3.3
GRAAL_HOME ?= $(GRAAL_ROOT)/graalvm-ce-java11-$(GRAAL_VERSION)
GRAAL_ARCHIVE := graalvm-ce-java11-$(PLATFORM)-amd64-$(GRAAL_VERSION).tar.gz

ifeq ($(PLATFORM),darwin)
	GRAAL_HOME := $(GRAAL_HOME)/Contents/Home
	GRAAL_EXTRA_OPTION :=
else
	GRAAL_EXTRA_OPTION := "--static"
endif

$(GRAAL_ROOT)/fetch/$(GRAAL_ARCHIVE):
	@mkdir -p $(GRAAL_ROOT)/fetch
	curl --location --output $@ https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$(GRAAL_VERSION)/$(GRAAL_ARCHIVE)

$(GRAAL_HOME): $(GRAAL_ROOT)/fetch/$(GRAAL_ARCHIVE)
	tar -xz -C $(GRAAL_ROOT) -f $<

$(GRAAL_HOME)/bin/native-image: $(GRAAL_HOME)
	$(GRAAL_HOME)/bin/gu install native-image

.PHONY: graalvm
graalvm: $(GRAAL_HOME)/bin/native-image
# }}}

target/cli.jar:
	clojure -T:build uberjar

.PHONY: uberjar
uberjar: target/cli.jar

.PHONY: cli
cli: graalvm uberjar
	$(GRAAL_HOME)/bin/native-image \
		-jar target/cli.jar \
		-H:Name=cli \
		-H:+ReportExceptionStackTraces \
		-J-Dclojure.spec.skip-macros=true \
		-J-Dclojure.compiler.direct-linking=true \
		--features=clj_easy.graal_build_time.InitClojureClasses \
		--report-unsupported-elements-at-runtime \
		-H:Log=registerResource: \
		--verbose \
		--no-fallback \
		$(GRAAL_EXTRA_OPTION) \
		"-J-Xmx3g"

.PHONY: native-image
native-image: clean cli

.PHONY: clean
clean:
	\rm -rf target .cpcache
	\rm -f cli cli.build_artifacts.txt cli.linux-amd64 cli.darwin-amd64
