#OSX

##Xcode
Install [Xcode](https://developer.apple.com/xcode/) from the App store or the Apple developer website.

Then install Xcode command line tools run the command

    xcode-select --install  

##Homebrew
~~~~
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

~~~~

##Oh My Zsh

Install oh-my-zsh on top of zsh to get additional functionality

~~~~
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
~~~~
    
Change default shell to zsh manually
~~~~
chsh -s /usr/local/bin/zsh
~~~~

### Clone repo

~~~~
$ cd ~
$ git clone https://github.com/vvdcect/dev-env-setup.git
$ cp ~/dev-env-setup/.zshrc  ~/.zshrc
$ cp ~/dev-env-setup/.vimrc  ~/.vimrc 
$ source ~/.zshrc
~~~~
Add to path zsh
~~~~~
$ echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
~~~~~

##iTerm2
Download and install [iTerm2](https://www.iterm2.com/). Import profile from folder




