#!/bin/bash

clear

echo "Setting up HGV Deploy!"
echo ""
echo "Installing required software:"

sudo apt-get install software-properties-common

echo "Installing Ansible:"

sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible

echo "Upgrading Software:"

sudo apt-get upgrade

echo "Installing Ansible and Git:"

sudo apt-get install ansible git

echo "Cloning HGV Deploy to folder hgv-deploy-full:"

git clone https://github.com/zach-adams/hgv-deploy-full/

clear

echo "All done! Enjoy!"