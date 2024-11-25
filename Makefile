help:
	@echo ""
	@echo "Available Commands:"
	@echo "check    - Check the status"
	@echo "install  - Install everything in the playbook"
	@echo "dotfiles - Symlink all the dotfiles"
	@echo "facts    - List facts"
	@echo ""

check:
	uv run --with ansible ansible-playbook -i  hosts playbook.yml --check --diff -c local

install:
	curl -LsSf https://astral.sh/uv/install.sh | sh
	uv run --with ansible ansible-playbook -i hosts playbook.yml -c local
	sudo dscl . -create /Users/$USER UserShell /opt/homebrew/bin/zsh
	chsh -s /opt/homebrew/bin/zsh && . ~/.zshrc

dotfiles:
	uv run --with ansible ansible-playbook -i hosts playbook.yml -c local --tags dotfiles

facts:
	ansible all -i hosts -m setup -c local
