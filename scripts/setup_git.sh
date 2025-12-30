#!/usr/bin/env sh

# Function to prompt for input with default value and validation
# Usage: prompt_with_default "prompt text" "default_value" "validation_type"
# validation_type can be: "email", "path", "non_empty", or empty for no validation
prompt_with_default() {
  prompt_text="$1"
  default_value="$2"
  validation_type="$3"
  value=""
  is_valid=false

  while [ "$is_valid" = false ]; do
    if [ -n "$default_value" ]; then
      printf "%s [default: %s]: " "$prompt_text" "$default_value" >&2
    else
      printf "%s: " "$prompt_text" >&2
    fi
    
    read -r value
    
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

  GIT_NAME=$(prompt_with_default "Enter your name used for Git/GitHub" "" "non_empty")
  GIT_EMAIL_PERSONAL=$(prompt_with_default "Enter the Git email you use for personal projects" "" "email")
  GIT_EMAIL_WORK=$(prompt_with_default "Enter the Git email you use for work projects" "$GIT_EMAIL_PERSONAL" "email")

  default_work_path="~/code/work/"
  GIT_WORK_PATH=$(prompt_with_default "Enter the path to your work projects (make sure to add the ending slash)" "$default_work_path" "path")
  GIT_SIGNING_KEY=$(prompt_with_default "Enter your Git SSH public key" "" "non_empty")

  printf '%s\n' "$LOCAL_GIT_CONFIG" > "$GIT_LOCAL_CONFIG_PATH"
  printf '%s\n' "$WORK_GIT_CONFIG" > "$GIT_WORK_CONFIG_PATH"

  export GIT_NAME GIT_EMAIL_PERSONAL GIT_SIGNING_KEY GIT_SIGN_PROGRAM_PATH GIT_WORK_PATH GIT_EMAIL_WORK

  envsubst < "$GIT_LOCAL_CONFIG_PATH" > "$GIT_LOCAL_CONFIG_PATH.new" && mv "$GIT_LOCAL_CONFIG_PATH.new" "$GIT_LOCAL_CONFIG_PATH"
  envsubst < "$GIT_WORK_CONFIG_PATH" > "$GIT_WORK_CONFIG_PATH.new" && mv "$GIT_WORK_CONFIG_PATH.new" "$GIT_WORK_CONFIG_PATH"

fi