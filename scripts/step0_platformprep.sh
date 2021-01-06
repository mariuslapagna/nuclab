#!/bin/bash 
# This script is to set up subscription and install ansible and the ansible user

#Choose the name for your ansible user
ANSIBLE_USER="ansible"
NUCLAB_REPO="https://github.com/mariuslapagna/nuclab"

echo ""
echo -e "######################"
echo -e "# NUCLAB first steps #"
echo -e "######################\n" 


#######################################################################
# We might not have sudoers entries yet, testing for running by root 

if [ `id -u` != 0 ] 
  then
    echo -e "Please run $0 as root, exiting. \n" 
    exit 1
  else
    echo -e "Running as root, good... \n" 
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
    echo -e "...subscription looks good, let's move on... \n"
fi

#######################################################################
# Ensuring the right repository is available 
#echo "Checking if the ansible repo is enabled" 
#if ! `subscription-manager repos --list-enabled | grep ansible-2.9-for-rhel-8-x86_64-rpms >/dev/null 2>&1` 
#  then
#    echo "...it isn't. Trying to enable..."
#    if ! `/usr/bin/subscription-manager repos --enable=ansible-2.9-for-rhel-8-x86_64-rpms >/dev/null 2>&1`
#      then
#        echo "Enabling Ansible repo failed, exiting" 
#        exit 1
#      else
#	echo -e "...success. \n"
#    fi
#  else
#    echo -e "...repo is enabled, good. \n" 
#fi

#######################################################################
# Installing ansible 
#echo "Checking if ansible is installed"
#if ! `rpm -q ansible >/dev/null 2>&1`
#  then
#    echo "...it isn't, installing..." 
#    if ! `dnf install -y -q ansible`
#      then
#        echo "Installing Ansible failed, exiting" 
#        exit 1
#      else 
#	echo -e "...done \n"
#    fi
#  else
#    echo -e "...Ansible is already installed. \n"
#fi

#######################################################################
# Installing pip 
echo "Checking if pip is installed"
if ! `rpm -q python38-pip >/dev/null 2>&1`
  then
    echo "...it isn't, installing..." 
    if ! `dnf install -y -q python38-pip && sudo alternatives --install /usr/bin/pip pip /usr/bin/pip3.8 1`
      then
        echo "Installing pip failed, exiting" 
        exit 1
      else 
	echo -e "...done \n"
    fi
  else
    echo -e "...pip is already installed. \n"
fi

#######################################################################
# Installing ansible 
echo "Checking if ansible is installed"
if ! `which ansible >/dev/null 2>&1`
  then
    echo "...it isn't, installing..." 
    if ! `pip install ansible >/dev/null 2>&1`
      then
        echo "Installing Ansible failed, exiting" 
        exit 1
      else 
	echo -e "...done \n"
    fi
  else
    echo -e "...Ansible is already installed. \n"
fi



#######################################################################
# Setting sudoers for the wheel group
echo "Setting sudoers for the wheel group, if sudoers is unchanged" 

# This is calculated from sudo-1.8.29-6.el8.x86_64.rpm
SUDOERS_ORIGINAL_CHECKSUM="1b134d95a4618029ff962a63b021e1ca  /etc/sudoers"
SUDOERS_TARGET_CHECKSUM="bfb09d72c2e7d3b8677f013312fda833  /etc/sudoers"

if [ "`md5sum /etc/sudoers`" == "$SUDOERS_ORIGINAL_CHECKSUM" ] 
  then 
    # removing comment from NOPASSWD line 
    sed -i '/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/s/^# //' /etc/sudoers 
    # adding comment to no-NOPASSWD line
    sed -i '/^%wheel\tALL=(ALL)\tALL$/s/^/# /' /etc/sudoers 
    echo "...done." 
  elif [ "`md5sum /etc/sudoers`" == "$SUDOERS_TARGET_CHECKSUM" ] 
    then
      echo -e "...sudoers seems to be already configured. \n"
  else
    echo "/etc/sudoers checksum isn't any of the expected checksums, exiting." 
    exit 1
fi 

#######################################################################
# creating the ansible user
echo "Checking if the user $ANSIBLE_USER exists"
if ! `id $ANSIBLE_USER >/dev/null 2>&1`
  then
    echo "...it isn't, creating..." 
    if ! `adduser $ANSIBLE_USER -U -G "wheel" >/dev/null 2>&1 && sudo -i -u $ANSIBLE_USER ssh-keygen -N '' -q -t rsa  <<< ""$'\n'"y" >/dev/null 2>&1`
      then
        echo "Installing Ansible user failed, exiting" 
        exit 1
      else 
	echo -e "...done. Please set a password for it: \n"
	passwd $ANSIBLE_USER
    fi
  else
    echo -e "...Ansible user is already existing \n"
fi

#######################################################################
# Installing git
echo "Checking if git is installed"
if ! `rpm -q git >/dev/null 2>&1`
  then
    echo "...it isn't, installing..." 
    if ! `dnf install -y -q git`
      then
        echo "Installing git failed, exiting" 
        exit 1
      else 
	echo -e "...done \n"
    fi
  else
    echo -e "...git is already installed. \n"
fi

#######################################################################
# creating the ansible user
echo "Cloning the nuclab repository" 
if ! `rm -rf /home/$ANSIBLE_USER/nuclab && sudo -i -u "$ANSIBLE_USER" git clone "$NUCLAB_REPO" >/dev/null 2>&1` 
  then 
    echo "Cloning the repo failed, pls check." 
    echo "exiting." 
    exit 1
  else
    echo -e "...done, cloned to /home/$ANSIBLE_USER/nuclab .\n" 
fi

#######################################################################
# Updating and requesting reboot 
echo "Updating entire system..." 

if ! `yum update -y -q >/dev/null 2>&1` 
  then 
    echo "'yum update -y -q' seemingly went wrong. Please investigate."
    echo "exiting." 
    exit 1
  else 
    echo -e "...all good. You should reboot, and create a boom snapshot for fallback now. \n" 
fi 

#######################################################################
# if all is good, then...

echo "Ready to rock'n'roll, reboot, [consider the boom boot option] and run your playbooks."

