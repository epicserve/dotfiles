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

2. Install Ansible

        $ sudo easy_install pip
        $ sudo pip install ansible

3. Install all the things

        $ git clone git@github.com:epicserve/dotfiles.git ~/.dotfiles
        $ cd ~/.dotfiles
        $ make install

4. Change your default shell

        $ sudo echo '/usr/local/bin/zsh' >> /etc/shells
        $ chsh -s /usr/local/bin/zsh

5. Stuff to download and install manually

    - Airmail 3
    - Monosnap
    - Microsoft Office
    - Microsoft Remote Desktop
    - [Ruby RVM](https://rvm.io/rvm/install)

6. Settings I change

    - Auto hide dock
    - Trackpad, tap to click
    - Keyboard: Fast repeat and short delay until repeat

Inspiration
-----------

- https://github.com/jefftriplett/dotfiles


[1]: http://docs.ansible.com/ansible/
[3]: http://brew.sh/
[4]: https://pip.pypa.io/en/latest/
[5]: https://github.com/mitsuhiko/pipsi
