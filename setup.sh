#sanity check
echo setting up codespace dotfiles...
echo setting up codespace dotfiles > /var/tmp/dotfilesetup
date >> /var/tmp/dotfilesetup

#install spacevim
#curl -sLf https://spacevim.org/install.sh | bash

#emacs    

sudo apt-get install software-properties-common
 
sudo add-apt-repository ppa:kelleyk/emacs -y 
sudo apt update 
# If you want, you can install the text-only user interface via 
#sudo apt install -y emacs-nox 
#sudo apt install -y emacs-nox # sudo apt install -y emacs27 
sudo apt install -y emacs27
# .emacs.d copied above git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d #LANG is required for spacemacs home screen, else the logo is question marks echo export LANG=en_US.UTF-8 >> ~/emacs.sh echo TERM=xterm-256color emacs -l ~/src/qg/q_utils_orig/_load-all-min.elc >> ~/emacs.sh 
#sudo apt install -y emacs27-common

# .emacs.d copied above git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d #LANG is required for spacemacs home screen, else the logo is question marks echo export LANG=en_US.UTF-8 >> ~/emacs.sh echo TERM=xterm-256color emacs -l ~/src/qg/q_utils_orig/_load-all-min.elc >> ~/emacs.sh 



# .emacs.d copied above
git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
#clone other GH repos
#NOTE: requires update to devcontainer.json https://github.com/orgs/community/discussions/36228
cd ~/
git clone https://github.com/pault-tech/dotfiles.git
git clone https://github.com/pault-tech/dotfiles_spacemacs.git

