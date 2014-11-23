#!/bin/bash

#Config
HOST="app.dev"
PASS="honor"
DBNAME="app"
DBUSER="app"
DBPASS="harrington"

export DEBIAN_FRONTEND=noninteractive;
#Programs
APTGET="apt-get -qq "

msg()  {
	echo "--- "$*" ---"
}
err() {
	echo "*** "$*" ***"
}
installpkg() {
	msg "Installing "$*
	$APTGET install $*
}

msg "Starting Provision"

msg "Setting timezone"
echo "Europe/London" > /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

msg "Updating apt"
$APTGET update

msg "Upgrading system"
dpkg-reconfigure -plow grub-pc
$APTGET upgrade
$APTGET autoremove

msg "Base packages"
installpkg git build-essential htop curl nano wget

msg "Mysql"
installpkg debconf-utils
debconf-set-selections <<< "mysql-server mysql-server/root_password password "$PASS
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password "$PASS
installpkg mysql-server mysql-client

if [ ! -f /var/log/dbinstalled ];
then
    echo "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}'" | mysql -uroot -p${PASS}
    echo "CREATE DATABASE ${DBNAME}" | mysql -uroot -p${PASS}
    echo "GRANT ALL ON ${DBNAME}.* TO 'mysqluser'@'localhost'" | mysql -uroot -p${PASS}
    echo "flush privileges" | mysql -uroot -p${PASS}
    touch /var/log/dbinstalled
fi

msg "Apache"
add-apt-repository -y ppa:ondrej/apache2 >/dev/null
$APTGET update
installpkg apache2
a2enmod proxy_fcgi rewrite > /dev/null
ln -s /vagrant/provision/config/site.conf /etc/apache2/sites-available/app.dev.conf
a2ensite app.dev >/dev/null
a2dissite 000-default >/dev/null
service apache2 restart

msg "PHP5"
installpkg php5-fpm php5-curl php5-gd php5-sqlite php5-mcrypt php5-mysqlnd php5-cli php5-dev 
ln -s /vagrant/provision/config/php.ini /etc/php5/mods-available/app.dev.ini
php5enmod app.dev
service php5-fpm restart