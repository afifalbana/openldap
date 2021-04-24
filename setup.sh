#!/bin/bash

# Setup OpenLDAP server and phpLDAPadmin in CentOS 7.

source variables.sh
source functions.sh

# Update and upgrade software packages.
yum -y update && yum -u upgrade

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