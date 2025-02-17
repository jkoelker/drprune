MAKEFLAGS += --warn-undefined-variables

export CLIENT_VERSION	= $(CLIENT_VERSION)
export GO_VERSION		= $(GO_VERSION)
export GIT_BRANCH		= $(GIT_BRANCH)

# ================================================
# GENERIC VARIABLES
# ================================================

BINDIR      	:= $(CURDIR)/bin
BINNAME     	?= drprune
CLIENT_VERSION	:= $(shell git describe --tags --abbrev=0 2> /dev/null || echo '1.0.0' )
BUILD_DATE 		:= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
MAIN            ?= $(CURDIR)/cmd/drprune/main.go

# ================================================
# GIT VARIABLES
# ================================================

GIT_BRANCH			:= $(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT			:= $(shell git rev-parse HEAD)
GIT_SHORT_COMMIT	:= $(shell git rev-parse --short HEAD)
GIT_TAG				:= $(shell if [ -z "`git status --porcelain`" ]; then git describe --exact-match --tags HEAD 2>/dev/null; fi)
GIT_TREE_STATE		:= $(shell if [ -z "`git status --porcelain`" ]; then echo "clean" ; else echo "dirty"; fi)

# ================================================
# GO VARIABLES
# ================================================

GO_VERSION	:= $(shell go version)
GOPATH		?= $(shell go env GOPATH)

# Ensure GOPATH is set before running build process.
ifeq "$(GOPATH)" ""
  $(error Please set the environment variable GOPATH before running `make`)
endif

GO 		:= go
GOOS   	:= $(shell go env GOOS)
GOARCH	:= $(shell go env GOARCH)

# NOTE: '-race' requires cgo; enable cgo by setting CGO_ENABLED=1
BUILD_FLAG	:= -race
GOBUILD    	:= CGO_ENABLED=1 GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO) build $(BUILD_FLAG)

LDFLAGS	:= -w -s
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.cliVersion=$(CLIENT_VERSION)"
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.builtDate=$(BUILD_DATE)"
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.builtBy=makefile"
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.commit=$(GIT_COMMIT)"
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.commitShort=$(GIT_SHORT_COMMIT)"
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.commitBranch=$(GIT_BRANCH)"
LDFLAGS += -X "github.com/ci-monk/drprune/internal/version.goVersion=$(GO_VERSION)"

##################################################
# HELPER
##################################################

.PHONY: help
help:
	@echo ""
	@echo "🤖 Management commands"
	@echo ""
	@echo "======================"
	@echo ""
	@echo "✨ Golang Commands"
	@echo ""
	@echo "1. make setup"
	@echo "2. make build"
	@echo "3. make install"
	@echo "4. make clean"
	@echo "5. make verify-goreleaser"
	@echo "6. make snapshot"
	@echo "7. make release"
	@echo ""

##################################################
# GOLANG SHORTCUTS
##################################################

.PHONY: setup
setup:
	@echo "==> Setup..."
	$(GO) mod download
	$(GO) generate -v ./...
	@echo ""

.PHONY: build
build:
	@echo "==> Building..."
	$(GOBUILD) -o $(BINDIR)/$(BINNAME) -ldflags '$(LDFLAGS)' $(MAIN)
	@echo ""

.PHONY: install
install:
	@echo "==> Installing..."
	$(GO) install -x $(MAIN)
	@echo ""

.PHONY: clean
clean:
	@echo "==> Cleaning..."
	$(GO) clean -x -i $(MAIN)
	rm -rf ./bin/* ./vendor ./dist *.tar.gz
	@echo ""

.PHONY: verify-goreleaser
verify-goreleaser:
ifeq (, $(shell which goreleaser))
	$(error "No goreleaser in $(PATH), consider installing it from https://goreleaser.com/install")
endif
	goreleaser --version

.PHONY: snapshot
snapshot: verify-goreleaser
	goreleaser --snapshot --skip-publish  --rm-dist

.PHONY: release
release: verify-goreleaser
	goreleaser release --rm-dist --debug
