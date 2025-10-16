# Makefile for Navigator API project
.PHONY: venv install develop setup develop update setup clean distclean lock sync build-docker

# Python version to use
PYTHON_VERSION := 3.11

# Auto-detect available tools
HAS_UV := $(shell command -v uv 2> /dev/null)
HAS_PIP := $(shell command -v pip 2> /dev/null)

# Install uv for faster workflows
install-uv:
	curl -LsSf https://astral.sh/uv/install.sh | sh
	@echo "uv installed! You may need to restart your shell or run 'source ~/.bashrc'"
	@echo "Then re-run make commands to use uv workflows"

# Create virtual environment
venv:
	uv venv --python $(PYTHON_VERSION) .venv
	@echo 'run `source .venv/bin/activate` to start navigator.'

# Generate lock files (uv only)
lock:
ifdef HAS_UV
	uv lock
else
	@echo "Lock files require uv. Install with: pip install uv"
endif

install:
	uv sync --no-dev --extra production
	@echo "Production dependencies installed. Use 'make develop' for development setup."

# Install all dependencies including dev dependencies
develop:
	uv sync --frozen --extra dev

# Alternative: install without lock file (faster for development)
develop-fast:
	uv pip install -e .[dev]

# Setup development environment from requirements file (if you still have one)
setup:
	uv pip install -r requirements/requirements-dev.txt

# Update all dependencies
update:
	uv lock --upgrade

# Show project info
info:
	uv tree

# Clean build artifacts
clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	find . -name "*.pyc" -delete
	find . -name "*.pyo" -delete
	find . -name "*.so" -delete
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete."

# Remove virtual environment
distclean:
	rm -rf .venv
	rm -rf uv.lock

# Build Docker image
build-docker:
	docker build -t flowcore .

# Help:
help:
	@echo "Available targets:"
	@echo "  venv         - Create virtual environment"
	@echo "  install      - Install production dependencies"
	@echo "  develop      - Install development dependencies"
	@echo "  build        - Build package"
	@echo "  clean        - Clean build artifacts"
	@echo "  install-uv   - Install uv"
	@echo "  lock         - Generate lock files"
	@echo "  sync         - Sync dependencies"
	@echo "  update       - Update all dependencies"
	@echo "  info         - Show project info"
	@echo "  distclean    - Remove virtual environment and lock files"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Current setup: $(TOOL_INFO)"
