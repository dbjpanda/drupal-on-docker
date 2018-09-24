#!/usr/bin/env bash

echo "Creating a separate user who have deploy access on your server"
read -p 'Server Address ' SERVER
read -p 'Deploy User Name ' USER

# Generate ssh key pair
ssh-keygen -t rsa -N "" -f ${USER}_rsa
PUB_KEY=$(cat ${USER}_rsa.pub)
PRV_KEY=$(cat ${USER}_rsa)

# Encrypt private key with your CI tool
travis encrypt-file ${USER}_rsa ./travis/${USER}_rsa.enc --add --force

# Add rsa keys to gitignore
echo ${USER}_rsa >> .gitignore
echo ${USER}_rsa.pub >> .gitignore

ssh -t -o StrictHostKeyChecking=no root@"${SERVER}" << EOF
sudo adduser --disabled-password --gecos "" ${USER}
echo "travis ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${USER}
chmod 0440 /etc/sudoers.d/${USER}
sudo usermod -a -G docker ${USER}

sudo su ${USER}
cd ~
mkdir ~/.ssh
chmod 700 ~/.ssh
echo "${PUB_KEY}" >> ~/.ssh/authorized_keys

# Add ssh key to help cloning private github repo
echo "${PRV_KEY}" >> ~/.ssh/github_rsa
chmod 600 ~/.ssh/github_rsa
eval \$(ssh-agent)
ssh-add ~/.ssh/github_rsa
ssh-keyscan github.com >> ~/.ssh/known_hosts
echo IdentityFile ~/.ssh/github_rsa >> ~/.ssh/config
EOF

echo *********************************************************************************************************
echo "Go to https://github.com/"$(git config --get travis.slug)"/settings/keys/new and add the below text :-"
echo ---------------------------------------------------------------------------------------------------------
echo ${PUB_KEY}
echo ---------------------------------------------------------------------------------------------------------
