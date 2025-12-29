My Dotfiles
===========

This is my personal dotfiles for Brent O'Connor. It includes configurations and setup scripts for macOS, WSL/Ubuntu, 
and Omarchy.

- [Homebrew][homebrew]: for macOS package management
- Shell scripts: Simple, OS-specific setup and automation
- [UV][uv]: Python package installer and manager

[homebrew]: http://brew.sh/
[uv]: https://docs.astral.sh/uv/


Installation
------------

There are setup scripts for macOS, WSL/Ubuntu, and Omarchy (Linux/Arch):

- For macOS: `./setup_macos.sh`
- For WSL/Ubuntu: `./setup_wsl_ubuntu.sh`
- For Omarchy/Arch: `./setup_omarchy.sh`

1. Clone this repo

        git clone https://github.com/epicserve/dotfiles.git ~/.dotfiles
        cd ~/.dotfiles

2. Run the setup script for your OS

3. Change Git user and email in `~/.dotfiles/git/config` and `~/.dotfiles/git/config_work`

4. Also change the `signingkey` in `~/.dotfiles/git/config`. You can get your key from your 1Password SSH item for GitHub.

5. Change your terminal font to a Powerline font (e.g., "Roboto Mono Medium for Powerline") for proper prompt display.

6. Export and Import Raycast settings from your previous computer.


Contributing
------------

I welcome pull requests and issues, especially for bug fixes, documentation improvements, or anything that helps others
use or understand these dotfiles. However, please note that this project is highly opinionated and tailored to my
personal workflow. I will review contributions thoughtfully, but I may decline suggestions or PRs that don't align with 
my preferences or the intended purpose of this setup.

**Guidelines:**
- Bug fixes and documentation tweaks are especially appreciated.
- Feel free to open issues or pull requests—I'll consider all submissions.
- Features and major changes should be discussed before opening a PR.
- If a change doesn't align with my usage or needs, please don't take rejection personally—thanks for understanding!

Thanks for being respectful and constructive in your contributions!
