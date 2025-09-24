# Python project Makefile for formatting, linting, testing, and pre-commit

.PHONY: help install format lint test pre-commit

# Default target
help:
	@echo "Available commands:"
	@echo "  make install     Install dependencies and pre-commit hooks"
	@echo "  make format      Auto-format code with black and isort"
	@echo "  make lint        Run flake8 for linting"
	@echo "  make test        Run pytest"
	@echo "  make pre-commit  Run all pre-commit hooks on all files"

install:
	pip install -r requirements.txt
	pip install pre-commit
	pre-commit install

format:
	black .
	isort .

lint:
	flake8 .

test:
	pytest

pre-commit:
	pre-commit run --all-files || true
