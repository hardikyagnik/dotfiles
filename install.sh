#!/usr/bin/env bash

export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -e 
source $DOTFILES_ROOT/utils/link
source $DOTFILES_ROOT/utils/colors

printf "${HGREEN}"
cat << 'EOF'

   _______    ______  .___________. _______  __   __       _______     _______.
  |       \  /  __  \ |           ||   ____||  | |  |     |   ____|   /       |
  |  .--.  ||  |  |  |`---|  |----`|  |__   |  | |  |     |  |__     |   (----`
  |  |  |  ||  |  |  |    |  |     |   __|  |  | |  |     |   __|     \   \    
  |  '--'  ||  `--'  |    |  |     |  |     |  | |  `----.|  |____.----)   |   
  |_______/  \______/     |__|     |__|     |__| |_______||_______|_______/      

--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--.__.--
EOF

printf "${NC}"

printf "${BPURPLE}Setting up dotfiles...${NC}"
printf "${CYAN}DOTFILES_ROOT: ${DOTFILES_ROOT}${NC}\n"

# Setup dotfiles symlinks
source $DOTFILES_ROOT/setup/symlinks.sh

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
  printf "${HBLUE}📦 Xcode Command Line Tools not found. Installing...${NC}"
  xcode-select --install
  printf ''
else
  printf "${HWHITE}📦 Xcode Command Line Tools already installed${NC}\n"
fi

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
  printf "${HBLUE}🍺 Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  printf ''
else
  printf "${HWHITE}🍺 Homebrew already installed${NC}\n"
fi

# Install brew formulaes
source $DOTFILES_ROOT/setup/brew.sh

printf "${HGREEN}🎉 Dotfiles setup completed!\n"
