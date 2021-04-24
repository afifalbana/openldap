#!/bin/bash

# Setup OpenLDAP server and phpLDAPadmin in CentOS 7.

source variables.sh
source functions.sh

# Install epel, update and upgrade software packages.
yum -y install epel-release && yum -y update && yum -u upgrade

# Install OpenLDAP-server and dependencies .
yum -y install openldap \
    openldap-servers \
    openldap-clients \
    openldap-devel

# Start OpenLDAP daemon
systemctl start slapd
systemctl enable slapd

# Run modifier for LDAP database for base dn, and user.
run_modify_db

# Add additional LDAP schema.
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# Enable LDAP log to rsyslog
echo "local4.* /var/log/ldap.log" >> /etc/rsyslog.conf
systemctl restart rsyslog

# Install phpLDAPAdmin from EPEL repository.
yum -y phpldapadmin

# Grant phpLDAPadmin to be access from all network.
sed -i -e 's/Require local/Require all granted/' /etc/httpd/conf.d/phpldapadmin.conf
systemctl restart httpd

# Configure phpLDAPAdmin.
CONF_FILE=/etc/phpldapadmin/config.php
sed -i -e "s/Local LDAP Server/$LDAP_SERVER_NAME/" $CONF_FILE
sed -i -e "s/$servers->setValue('login','attr','uid');/\/\/ $servers->setValue('login','attr','uid');" $CONF_FILE
echo "$servers->setValue('server','host','$LDAP_HOST');" >> $CONF_FILE
echo "$servers->setValue('server','port', $LDAP_PORT);" >> $CONF_FILE
echo "$servers->setValue('server','base',array('$LDAP_BASE'));" >> $CONF_FILE
echo "$servers->setValue('login','attr','dn');" >> $CONF_FILE