# packer-xenial-flask
A vagrant box based on ubuntu xenial with flask for virtualbox

# Prerequisites
## Install vagrant
Grab vagrant and learn how to install it from [here](https://www.vagrantup.com/docs/installation/).

## Install packer
Grab packer and learn how to install it from [here](https://www.packer.io/intro/getting-started/install.html).

## Install kitchen
ToDo

# How to build

    make
    

# How to test
ToDO
    

# How to clean up
    
    make


# Purpose

This repository attempts to store the minimum amount of code that is required to create a:
- Ubuntu Xenial64 box
- With Flask running in development mode on port 8080
- with standard nginx rerouting port 80 to 8080
- using Packer
- for VirtualBox

# To Do
- [ ] add kitchen install instructions
- [ ] create kitchen test
- [ ] add kitchen test to makefile

# Done
- [x] add nginx to box
- [x] add flask to box
- [x] create json template file
- [x] copy boot provisioning script
- [x] create makefile
- [x] build initial readme
