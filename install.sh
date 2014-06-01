# Installer script for sysconf "nef.cloud"    -*- shell-script -*-

_install_packages()
{
    local _packages=""

    _packages="$_packages mongodb-clients" # for nef-cloud apps functionality

    sysconf_apt-get install --no-upgrade $_packages

    rm -f /etc/nginx/sites-enabled/default
}

_install_packages
