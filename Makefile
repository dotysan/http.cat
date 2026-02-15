#! /usr/bin/env -S make -f

PYVER := 3.14
VB = .venv/bin
UV_BIN := $(shell command -v uv 2>/dev/null)

node_modules/.bin/next: $(VB)/npm |uv
	uv run npm install

$(VB)/npm: $(VB)/nodeenv |uv
	@uv run nodeenv --python-virtualenv --node=lts && \
	touch -r $(VB)/activate.csh $(VB)/activate && \
	uv run npm install --global npm

$(VB)/nodeenv: $(VB)/activate |uv
	@uv pip install nodeenv

$(VB)/activate: |uv
	@uv venv --managed-python --python=$(PYVER)

.PHONY: uv
uv:
ifeq ($(UV_BIN),)
	curl --location https://gist.github.com/dotysan/fdbfc77b924a08ceab7197d010280dac/raw/uv-install.sh |bash
else
	@uv self update
endif

.PHONY: clean
clean:
	rm --recursive --force out .next node_modules .venv
