#!/bin/bash 

# This script is to set up subscription and install ansible 

# We might not have sudoers entries yet, testing for running by root 

if [ `id -u` != 0 ] 
  then
    echo "Please run $0 as root, exiting." 
    exit 1
fi

# Testing subscription setup

echo "Testing subscription status"
if ! `subscription-manager status >/dev/null 2>&1`
  then
    echo "'subscription-manager status' doesn't return 0, running s-m clean and register, pls provide user and password:" 
    subscription-manager clean
    subscription-manager register --auto-attach
fi

# Ensuring the right repository is available 
echo "Checking if the ansible repo is enabled" 
if ! `subscription-manager repos --list-enabled | grep ansible-2.9-for-rhel-8-x86_64-rpms >/dev/null 2>&1` 
  then
    if ! `/usr/bin/subscription-manager repos --enable=ansible-2.9-for-rhel-8-x86_64-rpms`
      then
        echo "Enabling Ansible repo failed, exiting" 
        exit 1
    fi
fi

# Installing ansible 
echo "Checking if ansible is installed"
if ! `rpm -q ansible >/dev/null 2>&1`
  then
    echo "...it isn't, installing..." 
    if ! `dnf install -y ansible`
      then
        echo "Installing Ansible failed, exiting" 
        exit 1
    fi
  else
    echo "Ansible is already installed."
fi

echo "Ready to rock'n'roll, run your playbooks."

