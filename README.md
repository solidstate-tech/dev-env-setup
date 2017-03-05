##Xcode
Install [Xcode](https://developer.apple.com/xcode/) from the App store or the Apple developer website.

Then install Xcode command line tools run the command

    xcode-select --install
    
It'll prompt you to install the command line tools. Follow the instructions and now you have Xcode and Xcode command line tools both installed and running.



##Homebrew
Package managers make it so much easier to install and update applications (for Operating Systems) or libraries (for programming languages). The most popular one for OS X is Homebrew.

Install
An important dependency before Homebrew can work is the Command Line Tools for Xcode. These include compilers that will allow you to build things from source.

We can install Hombrew! In the terminal paste the following line (without the $), hit Enter, and follow the steps on the screen:

~~~~
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

~~~~

One thing we need to do is tell the system to use programs installed by Hombrew (in /usr/local/bin) rather than the OS default if it exists. We do this by adding /usr/local/bin to your $PATH environment variable:


~~~~~
$ echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile

~~~~~

##iTerm2
Since we're going to be spending a lot of time in the command-line, let's install a better terminal than the default one. Download and install [iTerm2](https://www.iterm2.com/).

##Git and GitHub

What's a developer without Git? To install, simply run:
~~~~
$ brew install git
~~~~
When done, to test that it installed fine you can run:

~~~~
$ git --version
~~~~

And  

~~~~
which git should output /usr/local/bin/git
~~~~

Next, we'll define your Git user (should be the same name and email you use for GitHub):

~~~~
$ git config --global user.name "Your Name Here"
$ git config --global user.email "your_email@youremail.com"
~~~~

They will get added to your .gitconfig file.

To push code to your GitHub repositories, we're going to use the recommended HTTPS method (versus SSH). So you don't have to type your username and password everytime, let's enable Git password caching as described here:

~~~~
$ git config --global credential.helper osxkeychain
~~~~
##Zsh
Install zsh and zsh completions using homebrew

~~~~
    brew install zsh zsh-completions
~~~~

###Oh My Zsh

Install oh-my-zsh on top of zsh to get additional functionality

~~~~
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
~~~~
    
Change default shell to zsh manually
~~~~
chsh -s /usr/local/bin/zsh
~~~~

### Clone your first repo

~~~~
$ cd ~
$ git clone https://github.com/vvdcect/devenvsetup.git
$ cp ~/devenvsetup/.zshrc  ~/.zshrc
$ cp ~/devenvsetup/.vimrc  ~/.vimrc 
$ source ~/.zshrc
~~~~

##Ruby
OS X comes with Ruby installed (Mavericks even gets version 2.0.0, previously it was only 1.8.7), as we don't want to be messing with core files we're going to use the brilliant rbenv and ruby-build to manage and install our Ruby versions for our development environment.

~~~~
$ brew install rbenv ruby-build rbenv-default-gems rbenv-gemset
~~~~

The package we just installed allow us to install different versions of Ruby and specify which version to use on a per project basis and globally. This is very useful to keep a consistent development environment if you need to work in a particular Ruby version.

~~~~~
$ rbenv install 2.1.1
$ rbenv global 2.1.1
~~~~~

Install bundler. Bundler manages an application's dependencies, kind of like a shopping list of other libraries the application needs to work.

~~~~
$ gem install bundler
$ echo 'bundler' >> "$(brew --prefix rbenv)/default-gems"
Skip r-doc generation. If you use Google for finding your Gem documentation like I do you might consider saving a bit of time when installing gems by skipping the documentation.

$ echo 'gem: --no-document' >> ~/.gemrc

~~~~

Install Rails. With Ruby installed and the minimum dependencies ready to go Rails can be installed as a Ruby Gem.

~~~~
$ gem install rails
$ echo 'rails' >> "~/.rbenv/default-gems"
When starting a ruby project, you can have sandboxed collections of gems. This lets you have multiple collections of gems installed in different sandboxes, and specify (on a per-application basis) which sets of gems should be used. To have gems install into a sub-folder in your project directory for easy later removal / editing / testing, you can use a project gemset.

$ echo '.gems' > <my_project_path>/.rbenv-gemsets
~~~~

Your gems will then get installed in project/.gems.



##Install Node.js with nvm (Node Version Manager):
###Install nvm
~~~~
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | bash

~~~~
###Install nodejs

~~~~
$ source ~/.bashrc # sources your bashrc to add nvm to path
$ command -v nvm  # check the nvm use message
$ nvm install node  # install most recent nodejs stable version
$ nvm ls  # list installed node version
$ nvm use node  # use stable as current version
$ nvm ls-remote  # list all the node versions you can install
$ nvm alias default node  # set the installed stable version as the default node 
~~~~


Node modules are installed locally in the node_modules folder of each project by default, but there are at least two that are worth installing globally. Those are CoffeeScript and Grunt:

~~~~
$ npm install -g coffee-script
$ npm install -g grunt-cli
~~~~

###Npm usage
To install a package:

~~~~
$ npm install <package> # Install locally
$ npm install -g <package> # Install globally
~~~~

To install a package and save it in your project's package.json file:

~~~~
$ npm install <package> --save
~~~~

To see what's installed:
~~~~
$ npm list # Local
$ npm list -g # Global
~~~

To find outdated packages (locally or globally):

~~~~
$ npm outdated [-g]
~~~~

To upgrade all or a particular package:

~~~~
$ npm update [<package>]
~~~~

To uninstall a package:

~~~~
$ npm uninstall <package>
~~~~

##Heroku

##Install
~~~~
$ brew install heroku-toolbelt
~~~~

The formula might not have the latest version of the Heroku Client, which is updated pretty often. Let's update it now:

~~~~
$ heroku update
~~~~

Don't be afraid to run heroku update every now and then to always have the most recent version.

Usage
Login to your Heroku account using your email and password:

~~~~
$ heroku login
~~~~

If this is a new account, and since you don't already have a public SSH key in your ~/.ssh directory, it will offer to create one for you. Say yes! It will also upload the key to your Heroku account, which will allow you to deploy apps from this computer.

If it didn't offer create the SSH key for you (i.e. your Heroku account already has SSH keys associated with it), you can do so manually by running:

~~~~
 $ mkdir ~/.ssh
 $ ssh-keygen -t rsa
~~~~

Keep the default file name and skip the passphrase by just hitting Enter both times. Then, add the key to your Heroku account:

~~~~
$ heroku keys:add
~~~~
