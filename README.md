My Dotfiles
===========

This is my personal dotfiles. They are managed using:

- [Ansible][ansible]: Ansible is the simplest way to automate apps and IT infrastructure.
- [Homebrew][homebrew]: for OS X package management
- [UV][uv]: The PyPA recommended tool for installing and managing Python packages.

[ansible]: http://docs.ansible.com/ansible/
[homebrew]: http://brew.sh/
[uv]: https://docs.astral.sh/uv/


Installation
------------

1. Install all the things

        git clone https://github.com/epicserve/dotfiles.git .dotfiles \
        && cd ~/.dotfiles && ./install.sh

2. Change your font for iTerm2 to one of the Powerline fonts like, "Roboto Mono Medium for Powerline."

3. Apps I install manually.

   - [Docker](https://www.docker.com/products/docker-desktop)
   - [Irvue](https://apps.apple.com/us/app/irvue/id1039633667?mt=12)
   - [Microsoft Office](https://www.office.com/)
   - [Elgato Control Center](https://www.elgato.com/en/downloads)
   - [Elgato Wave Link](https://www.elgato.com/en/downloads)
   - [Logitech Options](https://www.logitech.com/en-us/product/options)

4. Settings I change.

   - Increase mouse speed to 9
   - Trackpad: tap to click

5. Archive and transfer the following folders:
     - ~/Sites
     - ~/.aws
     - ~/Downloads
     - ~/.ssh

     ```
     # Create the archive
     $ tar czvf backup.tar.gz ~/Sites/ ~/.aws ~/Downloads ~/.ssh

     # Transfer the archive to the new computer using AirDrop or SCP
     
     # Extract archive and then move the files to correct locations
     $ tar xzvf backup.tar.gz
     ```

6. Export Sequel Ace connections and copy them to the new computer.

7. Export and Import Raycast settings. 

8. Create a new AWS access key to add to aws-vault.

Inspiration
-----------

- https://github.com/jefftriplett/dotfiles
- https://github.com/adamchainz/mac-ansible
