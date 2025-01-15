
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
echo '        email = 4277512+pault-tech@users.noreply.github.com' >> ~/.gitconfig
echo '        name = Paul T' >> ~/.gitconfig

#LANG is required for spacemacs home screen, else the logo is question marks
echo chmod 700 /tmp/emacs1000 > ~/emacs.sh
echo export LANG=en_US.UTF-8 >> ~/emacs.sh
echo 'while true; do TERM=xterm-256color emacs -nw -l ~/custom.el; echo restarting; sleep 5; done'  >> ~/emacs.sh #require for gnu screen
chmod +x ~/emacs.sh
cp ~/emacs.sh ~/.local/bin/em

chmod 700 /tmp/emacs1000
ls -l /tmp/emacs*

# setup spacemacs
git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
printf "\n\n(setq vterm-always-compile-module t)" >> ~/.emacs.d/early-init.el
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

ORG="" #default self
ORG="pault-tech" #default self
# set repos (gh repo list $ORG --limit 9999 --json name)
repos=`(gh repo list --limit 9999 --json name)`
repos_to_clone=`(echo $repos | jq -r ".[].name")`

sleep 5

echo "cloning repos:\n $repos_to_clone"
for u in $repos_to_clone
do
	  echo "cloning $ORG repo $u"
	  git clone https://github.com/$ORG/$u || echo "failed to clone $u"
done

git clone https://github.com/localstack/localstack-pro-samples.git
git clone https://github.com/mrwormhole/hotdog-localstack-PoC.git
# git clone https://github.com/lombardo-chcg/kafka-local-stack.git

#NOTE: ssh protol not supported...
# git clone git@github.com:pault-tech/kafka-k8s-localstack.git
# git clone git@github.com:pault-tech/b2-demo.git

#TODO: shell script to map .spacemacs configs to devcontainer templates
cp ~/dotfiles-spacemacs/.spacemacs ~/

# curl "https://github.com/pault-tech?tab=stars" > pault_stars.html
gh ext install gh640/gh-repo-list
gh repo-list --type=starred > /workspaces/_starred.txt

}

function install_emacs {

    sudo apt update
    sudo apt install -y emacs-nox

}



if [ "$1" == "help"]; then
    echo 'usage: setup.sh [install_emacs]'
elif [ "$1" == "install_emacs"]; then
    install_emacs
else
    setup_dotfiles_spacemacs
fi
