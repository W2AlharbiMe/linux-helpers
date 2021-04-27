#!/bin/bash
VER=3.0.1

echo -e "
Welcome, this script will compile ruby v$VER, it will install rbenv, git, ruby-build, rails, node, yarn 
"

# Prompt to continue
read -p "  Continue? (y/n) " ans
if [[ $ans != "y" ]]; then
  echo -e "\nQuitting...\n"
  exit
fi

START_TIME=$SECONDS


# update the list of packages available to install
sudo apt update -y

# Ensure git is installed
sudo apt install -y git
sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev

if [[ -d ~/.rbenv ]]; then
  echo "rbenv already installed - pull latest updates:"
  git -C ~/.rbenv pull
else
  # Check out rbenv into ~/.rbenv
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
fi

# Add ~/.rbenv/bin to $PATH, enable shims and autocompletion
# rbenv variable
read -d '' String <<"EOF"
# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
EOF

# check if rbenv is exists in .bashrc
grep -q rbenv ~/.bashrc; if [[ "$?" = "0" ]]; then
  echo "rbenv already enabled in ~/.bashrc"
else
  # Save to ~/.bashrc
  echo -e "\n${String}" >> ~/.bashrc
fi

echo "$PATH" | grep -q "/.rbenv/bin:"; if [[ "$?" = "0" ]]; then
  echo "rbenv already enabled in current shell"
  RBENV_ENABLED=yes
else
  RBENV_ENABLED=no
  # Enable rbenv for current shell
  eval "${String}"
fi;

if [[ -d ~/.rbenv/plugins/ruby-build ]]; then
  echo "ruby-build already installed - pull latest updates:"
  git -C ~/.rbenv/plugins/ruby-build pull
else
  # Install ruby-build as an rbenv plugin, adds `rbenv install` command
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Install Ruby ($VER), don't generate RDoc to save lots of time
CONFIGURE_OPTS="--disable-install-doc --enable-shared" rbenv install $VER --verbose
rbenv global $VER

# Don't install docs for gems (saves lots of time)
if [[ -e ~/.gemrc ]]; then
  grep -q "gem: --no-document" ~/.gemrc; if [[ "$?" != "0" ]]; then
    # ~/.gemrc exists, but doesn't contain this line:
    echo "gem: --no-document" >> ~/.gemrc
  fi
else
  # ~/.gemrc doesn't exist:
  echo "gem: --no-document" > ~/.gemrc
fi

if [[ "$RBENV_ENABLED" = "no" ]]; then
  # Reminder to reload the shell
  echo -e "\nQuit and reload the current shell to get access to Ruby and rbenv."
  echo "Or, if you want to keep this shell open, re-load your .bashrc file, with:"
  echo "  source ~/.bashrc"
fi

# Print the time elapsed
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo -e "\nCompiled Ruby in $(($ELAPSED_TIME/60/60)) hr, $(($ELAPSED_TIME/60%60)) min, and $(($ELAPSED_TIME%60)) sec\n"
echo "Install Bundle && Bundler"
gem install bundle bundler
rbenv rehash

RVER=6.1.3.1
START_RAILS_TIME=$SECONDS

echo "installing rails v$RVER, Nodejs v12, Yarn"

echo "1. installing Nodejs v12"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

echo "2. Install Yarn"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt update -y && sudo apt-get install -y nodejs yarn

echo "3. install rails $RVER"

gem install rails -v $RVER
rbenv rehash

echo "NODE VER: $(node -v)"
echo "YARN VER: $(yarn --version)"
echo "RAILS VER: $(rails -v)"


ELAPSED_RAILS_TIME=$(($SECONDS - $START_RAILS_TIME))
echo -e "\nInstalled Rails v$RVER in $(($ELAPSED_RAILS_TIME/60/60)) hr, $(($ELAPSED_RAILS_TIME/60%60)) min, and $(($ELAPSED_RAILS_TIME%60)) sec\n"

