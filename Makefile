.PHONY: venv install install-uv lock sync dev clean distclean build-docker

PYTHON_VERSION := 3.11

venv:
	uv venv --python $(PYTHON_VERSION) .venv
	@echo 'Virtualenv created at .venv. Activate with: source .venv/bin/activate'

install:
	uv sync --no-dev

install-uv:
	uv install querysource
	uv install azure-teambots

lock:
	uv lock

sync:
	uv sync --frozen --no-dev

dev:
	uv sync

clean:
	rm -rf build/ dist/ *.egg-info/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

distclean:
	rm -rf .venv
	rm -rf uv.lock

build-docker:
	docker build -t flowcore .

# Development helpers
format:
	uv run black .

lint:
	uv run pylint .

type-check:
	uv run mypy .

test:
	uv run pytest
