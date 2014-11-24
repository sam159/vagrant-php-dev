#!/bin/bash

msg()  {
	echo "--- "$*" ---"
}
err() {
	echo "*** "$*" ***"
	exit 1
}
installpkg() {
	msg "Installing "$*
	$APTGET install $*
}

#Config
HOST="app.dev"
PASS=""
DBNAME=""
DBUSER=""
DBPASS=""

. /vagrant/provision/config.def

export DEBIAN_FRONTEND=noninteractive;
#Programs
APTGET="apt-get -qq "

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

msg "Setup Swapfile"
dd if=/dev/zero of=/.swapfile bs=1024k count=1024 >/dev/null #1024MB
chmod 600 /.swapfile
mkswap /.swapfile
echo "/.swapfile	none	swap	none	0	0" >> /etc/fstab
swapon -a

msg "Updating /etc/hosts"
sed -i 's/localhost/localhost ${HOST}/' /etc/hosts

msg "Base packages"
installpkg git build-essential htop curl nano wget

msg "Mysql"
echo "mysql-server mysql-server/root_password password "$PASS | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password "$PASS | debconf-set-selections
installpkg mysql-server mysql-client
service mysql restart

if [ ! -f /var/log/dbinstalled ];
then
    echo "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}'" | mysql -uroot -p$PASS
    echo "CREATE DATABASE ${DBNAME}" | mysql -uroot -p$PASS
    echo "GRANT ALL ON ${DBNAME}.* TO '${DBUSER}'@'localhost'" | mysql -uroot -p$PASS
    echo "Flush Privileges" | mysql -uroot -p$PASS
    touch /var/log/dbinstalled
fi

msg "Apache"
add-apt-repository -y ppa:ondrej/apache2 >/dev/null #For Apache 2.4.10
apt-key adv --keyserver keyserver.ubuntu.com --recv E5267A6C >/dev/null
$APTGET update
installpkg apache2
msg "Configuring Apache2"
echo "ServerName "$HOST >> /etc/apache2/apache2.conf
a2enmod proxy_fcgi rewrite > /dev/null
ln -s /vagrant/provision/config/site.conf /etc/apache2/sites-available/app.dev.conf
a2ensite app.dev
a2dissite 000-default 
rm /etc/apache2/mods-enabled/mpm_event.conf
ln -s /vagrant/provision/config/mpm_event.conf /etc/apache2/mods-enabled/mpm_event.conf
service apache2 restart

msg "PHP5"
installpkg php5-fpm php5-curl php5-gd php5-sqlite php5-mcrypt php5-mysqlnd php5-cli php5-dev 
ln -s /vagrant/provision/config/php.ini /etc/php5/mods-available/app.dev.ini
php5enmod app.dev
ln -s /vagrant/provision/config/pool.conf /etc/php5/fpm/pool.d/app.dev.conf
rm /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart

exit 0