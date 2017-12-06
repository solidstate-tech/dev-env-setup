export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=/usr/local/share/npm/bin:$PATH
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="/:usr/local/pgsql/bin$PATH"
export PATH="$PATH:$GOPATH/bin"
export EDITOR='vim'
export NVM_DIR="$HOME/.nvm"
export PROMPT
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:$PATH" plugin=s(git osx)
eval "$(docker-machine env)"
 #Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export TLY_BACKUPS="/Users/stephensinniah/workspace/production-sites/touristly/backups"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"
#

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)
source $ZSH/oh-my-zsh.sh

# User configuration
# Get branch name in underscores
# Useful for Git-aware database.yml in Rails
# Requires prefix as the param (without underscore)
alias brails="bundle exec rails"

function gbdb() {
  app_env=`brails r "print Rails.env"`
  feature_branch=`echo "$(current_branch)" | tr '-' '_' | tr '/' '_'`
  project_prefix=$1

  if [[ "$app_env" = 'development' ]]; then
    app_env="dev"
  fi

  echo "${project_prefix}_${app_env}_${feature_branch}"
}
function mysqlcopydb() {
# Set up the local profile with mysql_config_editor first
  DBSNAME=$1
  DBNAME=$2

  fCreateTable=""
  fInsertData=""
  echo "Copying database ... (may take a while ...)"
  echo "DROP DATABASE IF EXISTS ${DBNAME}" | mysql --login-path=local
  echo "CREATE DATABASE ${DBNAME}" | mysql --login-path=local
  for TABLE in `echo "SHOW TABLES" | mysql --login-path=local $DBSNAME | tail -n +2`; do
          createTable=`echo "SHOW CREATE TABLE ${TABLE}"|mysql --login-path=local -B -r $DBSNAME|tail -n +2|cut -f 2-`
          fCreateTable="${fCreateTable} ; ${createTable}"
          insertData="INSERT INTO ${DBNAME}.${TABLE} SELECT * FROM ${DBSNAME}.${TABLE}"
          fInsertData="${fInsertData} ; ${insertData}"
  done;
  echo "$fCreateTable ; $fInsertData" | mysql --login-path=local $DBNAME
}

# Requires prefix as the param (without underscore)
function setupgbdb() {
  BRANCH_DB=$(gbdb $1)

  mysqlcopydb $1_dev_develop $BRANCH_DB
}
export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias wp7pd="ssh ubuntu@ec2-13-228-142-178.ap-southeast-1.compute.amazonaws.com"
alias wp8st="ssh  ubuntu@ec2-52-221-246-33.ap-southeast-1.compute.amazonaws.com"
alias zshconfig="vim  ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias be="bundle exec"
alias pg-start="launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
alias pg-stop="launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist" 
export NVM_DIR="/Users/stephensinniah/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
alias st='/usr/bin/sublime-text'
DEFAULT_USER=sds
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


source "/Users/stephensinniah/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
export PATH="/usr/local/opt/qt@5.5/bin:$PATH"
