help:
	@echo ""
	@echo "Available Commands:"
	@echo "check    - Check the status"
	@echo "install  - Install everything in the playbook"
	@echo "dotfiles - Symlink all the dotfiles"
	@echo "facts    - List facts"
	@echo ""

check:
	ansible-playbook -i  hosts playbook.yml --check --diff -c local

install:
	ansible-playbook -i hosts playbook.yml -c local

dotfiles:
	ansible-playbook -i hosts playbook.yml -c local --tags dotfiles

facts:
	ansible all -i hosts -m setup -c local