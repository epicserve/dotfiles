My Dotfiles
===========

This is my personal dotfiles. They are managed using:

- [Ansible][1]: Ansible is the simplest way to automate apps and IT infrastructure.
- [Homebrew][3]: for OS X package management
- [pip][4]: The PyPA recommended tool for installing and managing Python packages.
- [pipsi][5]: pip script installer. pipsi is a nice tool for Python tools which need to be installed system wide.

Installation
------------

1. Install Homebrew

        $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

2. Update your profile

        $ echo 'export PATH=/usr/local/bin:$PATH' >> ~/.profile
        # restart your terminal

3. Install Python

        $ brew install python

4. Install Ansible

        $ pip3 install ansible

5. Install all the things

        $ git clone https://github.com/epicserve/dotfiles.git .dotfiles && cd ~/.dotfiles && make install

6. Change your default shell

        $ sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
        # restart your terminal

7. Change your font for iTerm2 to one of the Powerline fonts like, "Roboto Mono Medium for Powerline."

8. Apps I install manually.

   - Airmail 3
   - Docker
   - Irvue
   - Monosnap
   - Goofy (https://github.com/danielbuechele/goofy)
   - Microsoft Office
   - Microsoft Remote Desktop
   - Virtualbox

9. Settings I change.

   - Switch to dark mode
   - Increase mouse speed to 9
   - Disable fast user switching
   - Date and Time > Clock > Show Date
   - Show bluetooth in menu bar
   - Trackpad: tap to click
   - Set screensaver to Aerial
   - Install the Sublime Style Column Selection in Atom

Inspiration
-----------

- https://github.com/jefftriplett/dotfiles


[1]: http://docs.ansible.com/ansible/
[3]: http://brew.sh/
[4]: https://pip.pypa.io/en/latest/
[5]: https://github.com/mitsuhiko/pipsi
