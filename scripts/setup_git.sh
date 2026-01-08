#!/usr/bin/env sh

# Function to install gum if not already installed
install_gum_if_needed() {
  if command -v gum >/dev/null 2>&1; then
    return 0
  fi

  os_type=$(uname)
  
  if [ "$os_type" = "Darwin" ]; then
    # Mac - use brew
    if command -v brew >/dev/null 2>&1; then
      echo "Installing gum via brew..." >&2
      brew install -q gum || {
        echo "Failed to install gum via brew. Please install it manually." >&2
        exit 1
      }
    else
      echo "Error: brew not found. Please install Homebrew first or install gum manually." >&2
      exit 1
    fi
  elif command -v pacman >/dev/null 2>&1; then
    # Arch Linux - use pacman
    echo "Installing gum via pacman..." >&2
    sudo pacman -S --noconfirm gum || {
      echo "Failed to install gum via pacman. Please install it manually." >&2
      exit 1
    }
  elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu - use apt
    echo "Installing gum via apt..." >&2
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg || {
      echo "Failed to add gum repository key." >&2
      exit 1
    }
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null || {
      echo "Failed to add gum repository." >&2
      exit 1
    }
    sudo apt update -y && sudo apt install -y gum || {
      echo "Failed to install gum via apt. Please install it manually." >&2
      exit 1
    }
  else
    echo "Error: No supported package manager found (brew, pacman, or apt). Please install gum manually." >&2
    exit 1
  fi
}

# Function to prompt for input with default value and validation using gum
# Usage: gum_prompt_with_default "prompt text" "default_value" "validation_type"
# validation_type can be: "email", "path", "non_empty", or empty for no validation
gum_prompt_with_default() {
  prompt_text="$1"
  default_value="$2"
  validation_type="$3"
  value=""
  placeholder="$4"
  is_valid=false

  while [ "$is_valid" = false ]; do
    # Build gum input command
    if [ -n "$default_value" ]; then
      # Use --value to pre-fill the field with default value
      value=$(gum input --prompt "$prompt_text: " --value "$default_value")
      exit_code=$?
    elif [ -n "$placeholder" ]; then
      # Use --placeholder when no default value but placeholder is provided
      value=$(gum input --prompt "$prompt_text: " --placeholder "$placeholder")
      exit_code=$?
    else
      # No default or placeholder
      value=$(gum input --prompt "$prompt_text: ")
      exit_code=$?
    fi
    
    # Check if user cancelled (Ctrl+C or Esc)
    if [ $exit_code -ne 0 ]; then
      echo "" >&2
      echo "Cancelled by user." >&2
      exit 130
    fi
    
    # Use default if empty
    if [ -z "$value" ] && [ -n "$default_value" ]; then
      value="$default_value"
    fi
    
    # Expand ~ to home directory for paths
    if echo "$value" | grep -q "^~"; then
      value=$(echo "$value" | sed "s|^~|$HOME|")
    fi
    
    # Validate based on validation type
    case "$validation_type" in
      email)
        if validate_email "$value"; then
          is_valid=true
        else
          echo "Invalid email format. Please try again." >&2
        fi
        ;;
      path)
        if validate_path "$value"; then
          is_valid=true
        else
          echo "Invalid path. Please try again." >&2
        fi
        ;;
      non_empty)
        if validate_non_empty "$value"; then
          is_valid=true
        else
          echo "This field is required. Please enter a value." >&2
        fi
        ;;
      *)
        # No validation or empty - just check if not empty (unless default was used)
        if [ -n "$value" ]; then
          is_valid=true
        elif [ -n "$default_value" ]; then
          # Default was used, so it's valid
          is_valid=true
        else
          echo "This field is required. Please enter a value." >&2
        fi
        ;;
    esac
  done
  
  echo "$value"
}

# Validation function for email format
validate_email() {
  email="$1"
  # Basic email validation regex
  if echo "$email" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
    return 0
  else
    return 1
  fi
}

# Validation function for non-empty string
validate_non_empty() {
  value="$1"
  if [ -n "$value" ]; then
    return 0
  else
    return 1
  fi
}

# Validation function for directory path
validate_path() {
  path="$1"
  # Remove trailing slashes for consistency
  path=$(echo "$path" | sed 's|/*$||')
  
  # Check if it's an absolute path or starts with ~
  if echo "$path" | grep -qE '^/'; then
    # Absolute path - check if parent directory exists or is root
    parent_dir=$(dirname "$path")
    if [ -d "$parent_dir" ] || [ "$parent_dir" = "/" ]; then
      return 0
    else
      return 1
    fi
  elif echo "$path" | grep -qE '^~'; then
    # Path with ~ - should be valid after expansion
    expanded_path=$(echo "$path" | sed "s|^~|$HOME|")
    parent_dir=$(dirname "$expanded_path")
    if [ -d "$parent_dir" ] || [ "$parent_dir" = "$HOME" ] || [ "$parent_dir" = "/" ]; then
      return 0
    else
      return 1
    fi
  else
    # Relative path - check if parent exists in current directory or home
    if [ -d "$(dirname "$path")" ]; then
      return 0
    elif [ -d "$HOME/$(dirname "$path")" ]; then
      return 0
    else
      # Allow if it's just a directory name (will be created)
      return 0
    fi
  fi
}

get_sign_path() {
  os_type=$(uname)
  if grep -qiE "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    # Check if powershell.exe is available
    if ! command -v powershell.exe >/dev/null 2>&1; then
      echo "Warning: powershell.exe not found. Using default Linux path for op-ssh-sign." >&2
      echo "/opt/1Password/op-ssh-sign"
      return
    fi
    
    # Try to get Windows user profile path
    userprofile=$(powershell.exe -NoProfile -Command '$env:USERPROFILE' 2>/dev/null)
    if [ -z "$userprofile" ]; then
      echo "Warning: Could not determine Windows USERPROFILE. Using default Linux path for op-ssh-sign." >&2
      echo "/opt/1Password/op-ssh-sign"
      return
    fi
    
    # Convert Windows path to WSL path
    wsl_path=$(echo "$userprofile" | sed 's|C:\\|/mnt/c/|; s|\\|/|g; s|\r||')
    sign_path="${wsl_path}/AppData/Local/Microsoft/WindowsApps/op-ssh-sign.exe"
    
    # Verify the path exists
    if [ ! -f "$sign_path" ]; then
      echo "Warning: op-ssh-sign.exe not found at expected path: $sign_path" >&2
      echo "Using default Linux path instead." >&2
      echo "/opt/1Password/op-ssh-sign"
    else
      echo "$sign_path"
    fi
  elif [ "$os_type" = "Darwin" ]; then
    echo "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  else
    echo "/opt/1Password/op-ssh-sign"
  fi
}

# Build LOCAL_GIT_CONFIG template, inserting SSH_COMMAND conditionally for WSL
if [ "$IS_WSL" = true ]; then
  LOCAL_GIT_CONFIG=$(cat << 'EOF'
[user]
	name = "$GIT_NAME"
	email = $GIT_EMAIL_PERSONAL
	signingkey = $GIT_SIGNING_KEY

[core]
  sshCommand = ssh.exe

[gpg "ssh"]
  program = "$GIT_SIGN_PROGRAM_PATH"

[includeIf "gitdir:$GIT_WORK_PATH"]
    path = ~/.config/git/config_work

EOF
)
else
  LOCAL_GIT_CONFIG=$(cat << 'EOF'
[user]
	name = "$GIT_NAME"
	email = $GIT_EMAIL_PERSONAL
	signingkey = $GIT_SIGNING_KEY

[gpg "ssh"]
  program = "$GIT_SIGN_PROGRAM_PATH"

[includeIf "gitdir:$GIT_WORK_PATH"]
    path = ~/.config/git/config_work

EOF
)
fi

WORK_GIT_CONFIG=$(cat << 'EOF'
[user]
  email = $GIT_EMAIL_WORK
EOF
)

# Ensure ~/.config exists before creating symlink
mkdir -p "$HOME/.config"

ln -sf ~/.dotfiles/config/git ~/.config/

GIT_SIGN_PROGRAM_PATH="$(get_sign_path)"
GIT_LOCAL_CONFIG_PATH="$HOME/.config/git/config_local"
GIT_WORK_CONFIG_PATH="$HOME/.config/git/config_work"

if ! command -v envsubst >/dev/null 2>&1; then
  echo "Make sure you have envsubst installed, envsubst is provided with gettext."
  exit 1
fi

if [ ! -e "$GIT_LOCAL_CONFIG_PATH" ]; then
  # Install gum if needed before prompting for input
  install_gum_if_needed

  GIT_NAME=$(gum_prompt_with_default "Enter your name used for Git/GitHub" "" "non_empty" "First and Last Name")
  GIT_EMAIL_PERSONAL=$(gum_prompt_with_default "Enter the Git email you use for personal projects" "" "email" "john.doe@example.com")
  GIT_EMAIL_WORK=$(gum_prompt_with_default "Enter the Git email you use for work projects" "$GIT_EMAIL_PERSONAL" "email")

  default_work_path="~/code/work/"
  GIT_WORK_PATH=$(gum_prompt_with_default "Enter the path to your work projects (make sure to add the ending slash)" "$default_work_path" "path")
  GIT_SIGNING_KEY=$(gum_prompt_with_default "Enter your Git SSH public key" "" "non_empty" "ssh-ed25519 AAAA...")

  printf '%s\n' "$LOCAL_GIT_CONFIG" > "$GIT_LOCAL_CONFIG_PATH"
  printf '%s\n' "$WORK_GIT_CONFIG" > "$GIT_WORK_CONFIG_PATH"

  export GIT_NAME GIT_EMAIL_PERSONAL GIT_SIGNING_KEY GIT_SIGN_PROGRAM_PATH GIT_WORK_PATH GIT_EMAIL_WORK

  envsubst < "$GIT_LOCAL_CONFIG_PATH" > "$GIT_LOCAL_CONFIG_PATH.new" && mv "$GIT_LOCAL_CONFIG_PATH.new" "$GIT_LOCAL_CONFIG_PATH"
  envsubst < "$GIT_WORK_CONFIG_PATH" > "$GIT_WORK_CONFIG_PATH.new" && mv "$GIT_WORK_CONFIG_PATH.new" "$GIT_WORK_CONFIG_PATH"

fi