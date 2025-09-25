
# usage:
#
# setup.sh install_emacs           Installs emacs29
# setup.sh                         git clone spacemacs repo and launches emacs in gnu screen m to intialize all packages

function setup_dotfiles_spacemacs {


#sanity check
echo setting up codespace dotfiles...
echo setting up codespace dotfiles > /var/tmp/dotfilesetup
date >> /var/tmp/dotfilesetup

#install spacevim
#curl -sLf https://spacevim.org/install.sh | bash

sudo apt update

#emacs
sudo apt-get install -y software-properties-common

# TODO: install emacs if not installed?
# apt info emacs | grep Version | grep 27 && sudo apt install -y emacs-nox

# TODO: install emacs if not installed?
# type emacs || ( sudo add-apt-repository ppa:kelleyk/emacs -y && sudo apt update && sudo apt install -y emacs27-common && sudo apt install -y emacs27 ; )

echo [user] >> ~/.gitconfig
#note see: https://github.com/settings/emails.pault-tech uses the noreply address
IFS=  && read -r -d '' TXT << EOM
[user]
  email = 4277512+pault-tech@users.noreply.github.com
  name = Paul T

#avoid error: server-ensure-safe-dir: ‘/run/user/1000/emacs’ is not a safe directory because  it is not owned by you (owner = System administrator (0))'
#see https://www.reddit.com/r/emacs/comments/18ig37r/magit_error_when_commiting/
#NOTE: 2025/01 below does not seem to fix above error, in lieu using fix in ~/custom.el
[safe]
  directory = /tmp/emacs1000/
	# directory = "*"
EOM
echo "$TXT" >> ~/.gitconfig

#LANG is required for spacemacs home screen, else the logo is question marks
echo chmod 700 /tmp/emacs1000 > ~/emacs.sh
IFS=  && read -r -d '' TXT << EOM
source ~/.profile;
export LANG=en_US.UTF-8
ssh -oBatchMode=yes git@github.com
if [ \$? -ne 0 ]; then
printf "ssh login to github failed. try adding ssh keys to session\n\n"
sleep 10
fi
while true; do
  type pylsp || ( echo 'warning: pylsp not found for python mode, see .spacemacs for installation'  && sleep 5)
  TERM=xterm-256color emacs -nw -l ~/custom.el;
  echo "restarting. use  rm -rf ~/.emacs.d/.cache/lsp to reset lsp server associations"
  #sleep 5;
  keygm='' 
  while [ -z "$keygm" ]; do
    IFS= read -t300 -n 1 -s -r -p $"Press space to continue" readkeygm
    sleep 5
    keygm="$readkeygm"
    if [[ -z "$keygm" ]]; then
    printf "\ntimed out... quiting and detaching sreen.\n"
    screen -D
    fi
  done
done
EOM
echo "$TXT" >> ~/emacs.sh
chmod +x ~/emacs.sh
mkdir -p ~/.local/bin
cp ~/emacs.sh ~/.local/bin/em
ln -s ~/dotfiles-spacemacs/custom.el ~/custom.el

chmod 700 /tmp/emacs1000
ls -l /tmp/emacs*

# setup spacemacs
ls ~/.emacs.d && printf '\n\n~/.emacs.d exists please mv that directory and retry...\n' && exit
git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
printf "\n\n(setq vterm-always-compile-module t)" >> ~/.emacs.d/early-init.el
mkdir -p ~/.emacs.d/private/snippets/python-mode/
mkdir -p ~/.emacs.d/private/snippets/sh-mode/
mkdir -p ~/.emacs.d/.cache
cp ~/dotfiles-spacemacs/.emacs.d/private/snippets/python-mode/* \
~/.emacs.d/private/snippets/python-mode/
cp ~/dotfiles-spacemacs/.emacs.d/private/snippets/sh-mode/* \
~/.emacs.d/private/snippets/sh-mode/
cp ~/dotfiles-spacemacs/.emacs.d/.cache/* ~/.emacs.d/.cache/
#gnu screen
sudo apt install -y screen


#clone other GH repos
#NOTE: requires update to devcontainer.json https://github.com/orgs/community/discussions/36228
# mkdir ~/gh
# cd ~/gh
cd /workspaces
# git clone https://github.com/pault-tech/dotfiles.git
# git clone https://github.com/pault-tech/dotfiles-spacemacs.git
# git clone https://github.com/pault-tech/kafka-k8s.git

#TODO: should instead use a_git.sh vs below?
ORG="" #default self
ORG="pault-tech" #default self
# set repos (gh repo list $ORG --limit 9999 --json name)
repos=`(gh repo list --limit 9999 --json name)`
repos_to_clone=`(echo $repos | jq -r ".[].name")`
#TODO: fix this
repos_to_clone="gh_utils"
echo $repos_to_clone
#
sleep 5
#
echo "cloning repos:\n $repos_to_clone"
cd /workspaces
for u in $repos_to_clone
do
	  echo "cloning $ORG repo $u"
	  git clone https://github.com/$ORG/$u || echo "failed to clone $u"
done

# git clone https://github.com/localstack/localstack-pro-samples.git
# git clone https://github.com/mrwormhole/hotdog-localstack-PoC.git
# git clone https://github.com/lombardo-chcg/kafka-local-stack.git

#NOTE: ssh protol not supported...
# git clone git@github.com:pault-tech/kafka-k8s-localstack.git
# git clone git@github.com:pault-tech/b2-demo.git

#TODO: shell script to map .spacemacs configs to devcontainer templates
cp ~/dotfiles-spacemacs/.spacemacs ~/

# curl "https://github.com/pault-tech?tab=stars" > pault_stars.html
gh ext install gh640/gh-repo-list
gh repo-list --type=starred > /workspaces/_starred.txt

screen -dmS e
screen -S e -X stuff 'TERM=xterm-256color emacs --eval "(kill-emacs)" && echo emacs_done > /var/tmp/emacs_done \n'
screen -ls
echo in screen e starting initial run of emacs which will download all packages. this can take awhile...

}

function install_emacs {

# sudo apt update
# type emacs || ( sudo add-apt-repository ppa:kelleyk/emacs -y && \
   # sudo apt update && sudo apt install -y emacs28-common && sudo apt install -y emacs28-nox ; )

   #TODO: is this reliable ppa?
   #TODO: prompts for mail server
yes | DEBIAN_FRONTEND=noninteractive sudo add-apt-repository ppa:ubuntuhandbook1/emacs
set -x
sudo debconf-set-selections <<< "postfix postfix/mailname string todo.hostname.com"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"
DEBIAN_FRONTEND=noninteractive sudo apt-get install --assume-yes postfix
set +x

DEBIAN_FRONTEND=noninteractive  sudo apt update && DEBIAN_FRONTEND=noninteractive sudo apt install -y emacs-common && 
  DEBIAN_FRONTEND=noninteractive sudo apt install -y emacs-nox

echo done
sleep 2
emacs --version

}

function add_folders {

# code --help

code --add /workspaces/gh_utils
code --add /workspaces/csci-e-101
code --add /workspaces/OpenDevin
code --add ~/dotfiles-spacemacs

}

function init_pthon_mode_deps {

    pip install 'python-lsp-server[all]'

    pip install 'jupytext'

}

function init_lsp_servers {

# bash mode
/usr/bin/npm -g --prefix /home/ubuntu/.emacs.d/.cache/lsp/npm/bash-language-server install bash-language-server

# typescript mode
# /usr/bin/npm -g --prefix /home/ubuntu/.emacs.d/.cache/lsp/npm/typescript-language-server install typescript-language-server
sudo npm install -g typescript-language-server typescript


}


if [ "$1" == "help" ]; then
    echo 'usage: setup.sh [install_emacs]'
elif [ "$1" == "install_emacs" ]; then
    echo install_emacs
    sleep 2
    install_emacs
elif [ "$1" == "add_folders" ]; then
    echo add_folders
    sleep 2
    add_folders
elif [ "$1" == "sup" ] && [ "$2" == "2" ]; then
    echo sup 2 setup codespace after restart
    sleep 2
    add_folders
elif [ "$1" == "sup" ]; then
    echo sup setup
    sleep 2
    install_emacs
    setup_dotfiles_spacemacs
    add_folders
    init_lsp_servers
    init_pthon_mode_deps
else
    echo setup_dotfiles_spacemacs
    echo NOTE: use setup.sh sup for full install including emacs
    sleep 2
    setup_dotfiles_spacemacs
fi










