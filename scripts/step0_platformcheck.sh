#!/bin/bash 

# This script is to set up subscription and install ansible 

#######################################################################
# We might not have sudoers entries yet, testing for running by root 

if [ `id -u` != 0 ] 
  then
    echo "Please run $0 as root, exiting." 
    exit 1
  else
    echo "Running as root, good..." 
fi

#######################################################################
# Testing subscription setup

echo "Testing subscription status"
if ! `subscription-manager status >/dev/null 2>&1`
  then
    echo "'subscription-manager status' doesn't return 0, running s-m clean and register, pls provide user and password:" 
    subscription-manager clean
    subscription-manager register --auto-attach
    if [ $? != 0 ] 
      then 
        echo "'subscription-manager register --auto-attach' didn't work out, please check."
	echo "exiting."
	exit 1
    fi
  else
    echo "Subscription looks good, let's move on..."
fi

#######################################################################
# Ensuring the right repository is available 
echo "Checking if the ansible repo is enabled" 
if ! `subscription-manager repos --list-enabled | grep ansible-2.9-for-rhel-8-x86_64-rpms >/dev/null 2>&1` 
  then
    echo "...it isn't. Trying to enable..."
    if ! `/usr/bin/subscription-manager repos --enable=ansible-2.9-for-rhel-8-x86_64-rpms`
      then
        echo "Enabling Ansible repo failed, exiting" 
        exit 1
      else
	echo "...success."
    fi
  else
    echo "...repo is enabled, good." 
fi

#######################################################################
# Installing ansible 
echo "Checking if ansible is installed"
if ! `rpm -q ansible >/dev/null 2>&1`
  then
    echo "...it isn't, installing..." 
    if ! `dnf install -y -q ansible`
      then
        echo "Installing Ansible failed, exiting" 
        exit 1
      else 
	echo "...done"
    fi
  else
    echo "Ansible is already installed."
fi

#######################################################################
# Setting sudoers for the wheel group
echo "Setting sudoers for the wheel group, if sudoers is unchanged" 

# This is calculated from sudo-1.8.29-6.el8.x86_64.rpm
SUDOERS_CHECKSUM="1b134d95a4618029ff962a63b021e1ca  /etc/sudoers"

if [ "`md5sum /etc/sudoers`" == "$SUDOERS_CHECKSUM" ] 
  then 
    # removing comment from NOPASSWD line 
    sed -i '/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/s/^# //' /etc/sudoers 
    # adding comment to no-NOPASSWD line
    sed -i '/^%wheel\tALL=(ALL)\tALL$/s/^/# /' /etc/sudoers 
    echo "...done." 
  else
    echo "/etc/sudoers is not the expected $SUDOERS_CHECKSUM, exiting." 
    exit 1
fi 

#######################################################################
# if all is good, then...

echo "Ready to rock'n'roll, run your playbooks."

