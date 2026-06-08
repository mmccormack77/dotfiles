#!/bin/bash

# Change to the directory of the script
cd "$(dirname "${BASH_SOURCE}")";

# If debian-based system, install some necessary libraries
if [ -f /etc/debian_version ]; then
    echo "Installing necessary libraries for Debian-based systems..."
    sudo apt update && sudo apt install -y build-essential procps curl file git zip
fi

# Clone the repository
git pull origin main;

# Install Homebrew
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ "$(uname)" = "Darwin" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
fi

# Install zsh
if ! command -v zsh &>/dev/null; then
    echo "Installing zsh..."
    if [ "$(uname)" = "Darwin" ]; then
        brew install zsh
    elif [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y zsh
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y zsh
    else
        echo "Unsupported OS. Please install zsh manually."
        exit 1
    fi
fi

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
else
    echo "Default shell is already zsh."
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# Install custom_commands
for plugin_dir in plugins/*; do
    if [ -d "$plugin_dir" ]; then
        cp -r "$plugin_dir" "$HOME/.oh-my-zsh/custom/plugins"
    fi
done

# Add .zshrc
cp -f de.zshrc $HOME/.zshrc

# Add homebrew installs
brew update
brew bundle --file ./Brewfile

# Install Claude Code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Updating Claude Code..."
    claude update
fi

# Add starship toml
mkdir -p $HOME/.config 
cp -f ./configs/starship.toml $HOME/.config/starship.toml

# Add direnv toml
mkdir -p $HOME/.config/direnv
cp -f ./configs/direnv.toml $HOME/.config/direnv/direnv.toml

# Add tlrc toml
mkdir -p $HOME/.config/tlrc
cp -f ./configs/tlrc.toml $HOME/.config/tlrc/config.toml

# Add snowflake toml
mkdir -p $HOME/.snowflake
cp -f ./configs/snowflake.toml $HOME/.snowflake/config.toml
chmod 0600 $HOME/.snowflake/config.toml
snow --install-completion

# Add .gitconfig
cp -f ./configs/.gitconfig $HOME/.gitconfig

# Add .gitignore_global
cp -f ./configs/.gitignore_global $HOME/.gitignore_global

# Add Claude Code settings
mkdir -p $HOME/.claude
cp -rf ./configs/.claude/* $HOME/.claude/

# Install VS Code
if [ "$(uname)" = "Darwin" ]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
    if ! command -v code &>/dev/null; then
        echo "Installing VS Code..."
        sudo snap install code --classic
    else
        echo "VS Code is already installed."
    fi
    VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

# Copy VS Code settings
mkdir -p "$VSCODE_USER_DIR"
cp -f ./configs/vscode/settings.json "$VSCODE_USER_DIR/settings.json"

# Install VS Code extensions
# Newer VS Code Remote SSH uses ~/.vscode-server/code-<hash>; older used ~/.vscode-server/bin/.../code-server
VSCODE_SERVER_BIN=$(find ~/.vscode-server -maxdepth 1 -name "code-*" -type f 2>/dev/null | head -1)
if [ -z "$VSCODE_SERVER_BIN" ]; then
    VSCODE_SERVER_BIN=$(find ~/.vscode-server/bin -maxdepth 3 -name "code-server" -not -path "*/legacy-mode/*" 2>/dev/null | head -1)
fi
if [ -n "$VSCODE_SERVER_BIN" ]; then
    echo "Installing VS Code extensions..."
    while IFS= read -r extension; do
        "$VSCODE_SERVER_BIN" --install-extension "$extension" --force 2>&1 | grep -v "DeprecationWarning\|node --trace"
    done < ./configs/vscode/extensions.txt
else
    echo "Skipping VS Code extension install — VS Code server not found (connect to this machine via VS Code first)."
fi

# Make repos directory
mkdir -p $HOME/repos

echo "Bootstrap completed!"