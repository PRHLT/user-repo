#!/bin/bash

if [ "$EUID" -ne 0 ]
then
    >&2 echo "This script must be run as root."
    exit
fi

export INSTALLATION_DIR=/opt/user-repo
export CONFIG=''

while getopts ":d:c:" opt; do
    case ${opt} in
	d )
	    export INSTALLATION_DIR=${OPTARG}
	    ;;
	c )
	    export CONFIG=${OPTARG}
	    ;;
	\? )
	    >&2 echo "Usage: $0 -c conf_file {-d installation_directory}"
	    >&2 echo "     -c conf_file: apache configuration for the svn."
	    >&2 echo "     -d installation_directory: path for the installation. (Default: /opt/user-repo.)"
    esac
done

if [[ ${CONFIG} == '' ]]
then
    >&2 echo "Error: missing configuration file."
    >&2 echo "Usage: $0 -c conf_file {-d installation_directory}"
    >&2 echo "     -c conf_file: apache configuration for the svn."
    >&2 echo "     -d installation_directory: path for the installation. (Default: /opt/user-re\
po.)"
    exit
fi

if [ ! -f ${CONFIG} ] || [[ ${CONFIG} == '' ]]
then
    >&2 echo "Error: file ${CONFIG} does not exist."
    exit
fi

mkdir -p ${INSTALLATION_DIR}

apt-get update && apt-get install -y wget build-essential devscripts cmake pandoc git  rsync debhelper apache2-dev apache2 subversion

git clone https://github.com/PRHLT/user-repo.git ${INSTALLATION_DIR}

(
  cd ${INSTALLATION_DIR}

  mkdir build && cd build && cmake .. && make deb

  apt install -y ${INSTALLATION_DIR}/build/libapache2-mod-user-repo_2021.10.20-1_all.deb

  echo "LoadModule macro_module /usr/lib/apache2/modules/mod_macro.so" > /etc/apache2/mods-enabled/macro.load
)

cp ${CONFIG} /etc/apache2/sites-enabled/

a2enmod ssl
