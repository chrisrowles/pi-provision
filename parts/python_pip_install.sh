#!/usr/bin/env bash

# configure python3 (assumes it is installed... usually is on latest version of raspbian OS)
echo "checking for python 3"
python_default=`python -V | awk -F ' ' '{print $2}' | awk -F '.' '{print $1}'`;
if [[ $python_default == "3" ]]
    then
        echo "python 3 is set as default"
    else
        # TODO check update-alternatives --list first
        echo "configuring python 3 as default"
        update-alternatives --install /usr/bin/python python /usr/bin/python3 1
        update-alternatives --set python /usr/bin/python3
fi

# configure pip3
echo "checking for pip3"
pip_install=`dpkg -s python3-pip | grep Status`;
if [[ $pip_install == S* ]]
    then
        echo "pip3 is installed"
    else
        echo "installing pip3"
        apt-get -y install python3-pip
fi
echo "configuring pip3 as default"
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
update-alternatives --set pip /usr/bin/pip3