My Dotfiles
===========

This is my personal dotfiles. They are managed using:

- [Ansible][1]: Ansible is the simplest way to automate apps and IT infrastructure.
- [Homebrew][3]: for OS X package management
- [pip][4]: The PyPA recommended tool for installing and managing Python packages.

Installation
------------

1. Install [Homebrew](https://brew.sh)

2. Install Python

        brew install python && . ~/.zshrc && which pip3 && pip3 install --upgrade pip

3. Install all the things

        git clone https://github.com/epicserve/dotfiles.git .dotfiles \
        && cd ~/.dotfiles && make install

4. Change your default shell

        sudo dscl . -create /Users/$USER UserShell /opt/homebrew/bin/zsh \
        && chsh -s /opt/homebrew/bin/zsh && . ~/.zshrc

5. Change your font for iTerm2 to one of the Powerline fonts like, "Roboto Mono Medium for Powerline."

8. Apps I install manually.

   - [Docker](https://www.docker.com/products/docker-desktop)
   - [Irvue](https://apps.apple.com/us/app/irvue/id1039633667?mt=12)
   - [Microsoft Office](https://www.office.com/)
   - [Elgato Control Center](https://www.elgato.com/en/downloads)
   - [Elgato Wave Link](https://www.elgato.com/en/downloads)
   - [Logitech Options](https://www.logitech.com/en-us/product/options)

9. Settings I change.

   - Increase mouse speed to 9
   - Trackpad: tap to click

 10. Archive and transfer the following folders:
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

11. Export Sequel Ace connections and copy them to the new computer.

12. Export and Import Raycast settings. 

13. Create a new AWS access key to add to aws-vault.

Inspiration
-----------

- https://github.com/jefftriplett/dotfiles


[1]: http://docs.ansible.com/ansible/
[3]: http://brew.sh/
[4]: https://pip.pypa.io/en/latest/
