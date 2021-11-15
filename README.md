My Dotfiles
===========

This is my personal dotfiles. They are managed using:

- [Ansible][1]: Ansible is the simplest way to automate apps and IT infrastructure.
- [Homebrew][3]: for OS X package management
- [pip][4]: The PyPA recommended tool for installing and managing Python packages.

Installation
------------

1. Install Homebrew

        $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

2. Update your profile

        $ echo 'export PATH=/opt/homebrew/bin:$PATH' >> ~/.profile
        # restart your terminal

3. Install Python

        $ brew install python
        # Restart the terminal
        # Verify that you're using the correct binary
        $ which pip3
        /usr/local/bin/pip3
        # Upgrade pip3
        $ pip3 install --upgrade pip

4. Install Ansible

        $ pip3 install ansible

5. Install all the things

        $ git clone https://github.com/epicserve/dotfiles.git .dotfiles && cd ~/.dotfiles && make install
        # Note: The Ansible config found in roles/brew/tasks/main.yml doesn't seem to be installing Homebrew Cask apps
        # I had to install them manually using the following command.
        # for app in aws-vault 1password aerial bartender dropbox firefox fork iterm2 pycharm slack spectacle sequel-ace tableplus zoom elgato-control-center elgato-wave-link; do brew install $app; done

6. Change your default shell

        $ sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
        # restart your terminal

7. Change your font for iTerm2 to one of the Powerline fonts like, "Roboto Mono Medium for Powerline."

8. Apps I install manually.

   - [Airmail](https://apps.apple.com/us/app/airmail-4/id918858936?mt=12)
   - [Docker](https://download.docker.com/mac/stable/Docker.dmg)
   - [Irvue](https://apps.apple.com/us/app/irvue/id1039633667?mt=12)
   - [Microsoft Office](https://www.office.com/)
   - [Visual Studio Code](https://code.visualstudio.com)
   - [Wireguard](https://itunes.apple.com/us/app/wireguard/id1451685025?ls=1&mt=12)

9. Settings I change.

   - Switch to dark mode
   - Increase mouse speed to 9
   - Disable fast user switching
   - Date and Time > Clock > Show Date
   - Show bluetooth in menu bar
   - Trackpad: tap to click
   - Set screensaver to Aerial
   
 10. Transfer signatures in the Preview app.

 11. Archive and transfer the following folders:
     - ~/Sites
     - ~/.aws
     - ~/Downloads
     - ~/.ssh
     - ~/Library/Group Containers/2E337YPCZY.airmail

     ```
     # Create the archive
     $ tar czvf backup.tar.gz ~/Sites/ ~/.aws ~/Downloads ~/.ssh ~/Library/Group\ Containers/2E337YPCZY.airmail

     # Transfer the archive to the new computer using AirDrop or SCP
     
     # Extract archive and then move the files to correct locations
     $ tar xzvf backup.tar.gz
     ```

12. Export Sequel Ace connections and copy them to the new computer.

13. Export Wireguard VPN settings from the old computer.

14. Download the [Logitech Options](https://www.logitech.com/en-us/product/options) software if you use a logitech mouse/keyboard.

15. Create a new AWS access key to add to aws-vault.

Inspiration
-----------

- https://github.com/jefftriplett/dotfiles


[1]: http://docs.ansible.com/ansible/
[3]: http://brew.sh/
[4]: https://pip.pypa.io/en/latest/
