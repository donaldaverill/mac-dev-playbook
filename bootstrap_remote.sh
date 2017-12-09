#!/bin/sh

# Inspired by:
# https://raw.githubusercontent.com/siyelo/laptop/master/install.sh

# This script bootstraps our OSX laptop to a point where we can run
# Ansible on localhost.
#  1. Installs
#    - xcode
#    - homebrew
#    - ansible (via brew)
#    - a few ansible galaxy playbooks (cask etc)
#  2. Kicks off the ansible playbook
#    - main.yml
#
# It will ask you for your sudo password

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

fancy_echo "Bootstrapping..."

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

# Here we go.. ask for the administrator password upfront and run a
# keep-alive to update existing `sudo` time stamp until script has finished
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Ensure Apple's command line tools are installed
if ! command -v cc >/dev/null; then
  fancy_echo "Installing xcode ..."
  xcode-select --install
else
  fancy_echo "Xcode already installed. Skipping."
fi

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
else
  fancy_echo "Homebrew already installed. Skipping."
fi

# [Install Ansible](http://docs.ansible.com/intro_installation.html).
if ! command -v ansible >/dev/null; then
  fancy_echo "Installing Ansible..."
  brew install ansible
else
  fancy_echo "Ansible already installed. Skipping."
fi

if ! command -v git >/dev/null; then
  fancy_echo "Installing Git..."
  brew install git
else
  fancy_echo "Git already installed. Skipping."
fi

# Clone the repository to your local drive.
if [ -d ~/tmp_laptop ]; then
  fancy_echo "tmp_laptop repo dir exists. Removing ..."
  rm -rf ~/tmp_laptop
fi

mkdir ~/tmp_laptop
cd ~/tmp_laptop

fancy_echo "Cloning mac-dev-playbook repo ..."
git clone https://github.com/donaldaverill/mac-dev-playbook.git

fancy_echo "Changing to mac-dev-playbook repo dir ..."
cd ~/tmp_laptop/mac-dev-playbook

mkdir ~/tmp_laptop/mac-dev-playbook/roles
cd ~/tmp_laptop/mac-dev-playbook/roles

fancy_echo "Cloning ansible-role-visual-studio-code-extensions repo ..."
git clone https://github.com/donaldaverill/ansible-role-visual-studio-code-extensions.git

mv ~/tmp_laptop/mac-dev-playbook/roles/ansible-role-visual-studio-code-extensions ~/tmp_laptop/mac-dev-playbook/roles/visual-studio-code-extensions

cd ~/tmp_laptop/mac-dev-playbook
cp config_template.yml config.yml

# fancy_echo "Installing ansible requirements for this playbook..."
ansible-galaxy install -r requirements.yml

# fancy_echo "Running ansible playbook..."
ansible-playbook main.yml -i hosts --ask-sudo-pass -vvvv

fancy_echo "Removing ~/tmp_laptop ..."
rm -rf ~/tmp_laptop
