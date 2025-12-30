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

Before running the setup script, make sure you have the following information for your Git configuration. The Git
configuration assumes you use 1Password for storing your SSH keys and signing commits
(see the [1Password docs](https://developer.1password.com/docs/ssh/) for more information).

* Name
* Personal email address
* Work email address
* Parent path to work projects (e.g., `~/code/work`) 
* SSH Public Key for GitHub (from 1Password)

1. Clone this repo

        git clone https://github.com/epicserve/dotfiles.git ~/.dotfiles
        cd ~/.dotfiles

2. Run the setup script for your OS.

3. Change your terminal font to a MesloLGS Nerd Font for proper prompt display.
   See [the powerlevel10k theme guide][font-guide] for different terminals. The powerlevel10k theme
   [doesn't work properly][jetbrains-bug] in IntelliJ/Jet Brains IDE terminals, so we fallback to the eastwood theme in
   a Jet Brains IDE terminal.

4. If you want to customize your terminal prompt, edit the `~/.config/zsh/p10k.zsh` file in your home directory or run `p10k configure`.

5. Export and Import Raycast settings from your previous computer.

[font-guide]: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#fonts
[jetbrains-bug]: https://youtrack.jetbrains.com/issue/IJPL-106259/Launching-IntelliJ-from-the-shell-script-break-the-prompt-of-the-IJ-terminal-in-combination-with-Powerlevel10ks-transient-prompt

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
