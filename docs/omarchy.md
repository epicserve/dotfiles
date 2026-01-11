## Installation

1. [Install Omarchy](https://learn.omacom.io/2/the-omarchy-manual/50/getting-started)
2. Clone this project.
   ```
    git clone https://github.com/epicserve/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ```
3. Run the setup script.
   ```
   ./setup_omarchy.sh
   ```

## Manual Changes after Setup

### Hyperland Config Changes

1. If you have multiple monitors you'll need to edit `~/.config/hypr/monitors.conf` and change the settings to
   something like the following. You can use `hyprctl monitors` to see the names of your monitors. Also consult the
   [Omarchy documentation](https://learn.omacom.io/2/the-omarchy-manual/86/monitors?search=monitor#monitors).
   ```  
   monitor=DP-2,preferred,0x0,auto  
   monitor=DP-1,preferred,3840x0,auto  
   ```

### Install PyCharm

1. Install PyCharm using Jetbrains Toolbox App and then use it to install PyCharm.
2. Fix the Zoom level of PyCharm: click Help \> Edit Custom VM Options  
3. Add the line `-Dawt.toolkit.name=WLToolkit` and then restart PyCharm. See the [blog post](https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/) for context.

### Zen Browser Setup

1. Settings \> Look and Feel \> Sidebar and Top Toolbar  
2. Signin with your Firefox account  
3. Open `about:config` in a new tab and search for `zen.urlbar.replace-newtab`, change it to false.  
4. Settings \> Bookmarks \> Show bookmarks toolbar, then right-click on the bookmarks toolbar \> Bookmarks Tookbar \> Only Show on New Tab

### 1Password

1. Turn on the SSH Agent under Settings \> Developer

### AWS-Vault

1. Follow the AWS Vault setup [instructions](https://canopyllc.atlassian.net/wiki/spaces/CE/pages/739999785/How-to+Set+up+a+Engineer+s+MacBook+Pro) to finish this setup.

## Current Gripes

1. There isn’t an official Google Drive or OneDrive client  
2. LibreOffice looks really ugly compared to Microsoft Office  
3. Sleep mode doesn't work on my desktop
4. Grammarly Desktop doesn’t exist for Linux  
5. No office application for controlling my Insta 360 camera