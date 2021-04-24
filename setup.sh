#!/bin/bash

# Setup OpenLDAP server and phpLDAPadmin in CentOS 7.

source variables.sh
source functions.sh

# Install epel and update software packages.
sudo yum -y install epel-release
sudo yum -y update 

# Install OpenLDAP-server and dependencies .
sudo yum -y install openldap \
    openldap-servers \
    openldap-clients \
    openldap-devel

# Start OpenLDAP daemon
sudo systemctl start slapd
sudo systemctl enable slapd

# Run modifier for LDAP database for base dn, and user.
run_modify_db

# Add additional LDAP schema.
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# Enable LDAP log to rsyslog
sudo echo "local4.* /var/log/ldap.log" >> /etc/rsyslog.conf
sudo systemctl restart rsyslog

# Install phpLDAPAdmin from EPEL repository.
sudo yum -y install phpldapadmin

# Grant phpLDAPadmin to be access from all network.
sudo sed -i -e 's/Require local/Require all granted/' /etc/httpd/conf.d/phpldapadmin.conf
sudo systemctl restart httpd

# Configure phpLDAPAdmin.
CONF_FILE=/etc/phpldapadmin/config.php
sudo sed -i -e "s/Local LDAP Server/$LDAP_SERVER_NAME/" $CONF_FILE
sudo sed -i -e "s/$servers->setValue('login','attr','uid');/\/\/ $servers->setValue('login','attr','uid');" $CONF_FILE
sudo echo "$servers->setValue('server','host','$LDAP_HOST');" >> $CONF_FILE
sudo echo "$servers->setValue('server','port', $LDAP_PORT);" >> $CONF_FILE
sudo echo "$servers->setValue('server','base',array('$LDAP_BASE'));" >> $CONF_FILE
sudo echo "$servers->setValue('login','attr','dn');" >> $CONF_FILE