default:
    @just --list

@check:
	uv run --with ansible ansible-playbook playbook.yml --check --diff -c local

@update_homebrew:
    uv run --with ansible ansible-playbook playbook.yml --tags brew

@update_dotfiles:
    uv run --with ansible ansible-playbook playbook.yml --tags dotfiles

@update_python:
    uv run --with ansible ansible-playbook playbook.yml --tags python

@update_settings:
    uv run --with ansible ansible-playbook playbook.yml --tags settings

