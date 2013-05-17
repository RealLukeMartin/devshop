#!/bin/bash
#
#  DevShop Install Script
#  ======================
#
#  Install DevShop in Debian based systems.
#
#  NOTE: Only thoroughly tested in Ubuntu Precise
#
#  To install, run the following command:
#
#    $ sudo ./install.debian.sh
#
# You will be asked to create a MySQL root password.  Later you will be asked
# for this password again by the Aegir installer.
#

# Generate a secure password for MySQL
# Saves this password to /tmp/mysql_root_password in case you have to run the
# script again.
if [ -f '/tmp/mysql_root_password' ]
then
  MYSQL_ROOT_PASSWORD=$(cat /tmp/mysql_root_password)
  echo "Password found, using $MYSQL_ROOT_PASSWORD"
else
  MYSQL_ROOT_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
  echo "Generating new MySQL root password... $MYSQL_ROOT_PASSWORD"
  echo $MYSQL_ROOT_PASSWORD > '/tmp/mysql_root_password'
fi

# Add aegir debian sources
echo "deb http://debian.aegirproject.org stable main" | tee -a /etc/apt/sources.list.d/aegir-stable.list
wget -q http://debian.aegirproject.org/key.asc -O- | apt-key add -
apt-get update

# Pre-set mysql root pw
echo debconf mysql-server/root_password select $MYSQL_ROOT_PASSWORD | debconf-set-selections
echo debconf mysql-server/root_password_again select $MYSQL_ROOT_PASSWORD | debconf-set-selections

# @TODO: Preseed postfix settings

# Install git and mysql
apt-get install git mysql-server -y

# Delete anonymous MySQL users
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -D mysql -e "DELETE FROM user WHERE User=''"

# Delete test table
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -D mysql -e "DROP DATABASE test; DELETE FROM mysql.db WHERE Db LIKE 'test%'"


# Install Aegir-provision
apt-get install aegir-provision -y

# Download DevShop backend projects
su - aegir -c "drush dl provision_git-6.x devshop_provision-6.x --destination=/var/aegir/.drush -y"

# Install DevShop
MAKEFILE="/var/aegir/.drush/devshop_provision/build-devshop.make"

COMMAND="drush devshop-install --version=6.x-1.x --aegir_db_pass=$MYSQL_ROOT_PASSWORD --makefile=$MAKEFILE --profile=devshop -y"
echo "Running..."
echo $COMMAND
su - aegir -c "$COMMAND"

$comm ""
echo "================================================"
echo "DevShop has been installed!"
echo "================================================"
echo "Your MySQL root password is $MYSQL_ROOT_PASSWORD"
echo ""