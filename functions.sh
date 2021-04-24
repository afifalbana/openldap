#!/bin/bash

# Generate password for LDAP admin using slappasswd.
ldap_password () {
TEMP_PASS=$LDAP_PASS
LDAP_PASS=$(sudo slappasswd -h {SSHA} -s $TEMP_PASS)
}

# Modify base domain, admin user, and password.
modify_olc () {
cat > olc.ldif << EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $LDAP_BASE

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: $LDAP_USER

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $LDAP_PASS
EOF

sudo ldapmodify -Y EXTERNAL  -H ldapi:/// -f olc.ldif
}

# Modify monitor access only to LDAP admin.
modify_monitor () {
cat > monitor.ldif << EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base=$LDAP_USER read by * none
EOF

sudo ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif
}

# Create base domain, admin user, user base dn, and group base dn. 
modify_base () {
cat > base.ldif << EOF
dn: $LDAP_BASE
dc: $LDAP_TOPD
objectClass: top
objectClass: domain

dn: $LDAP_USER
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager

dn: $LDAP_USER_BASEDN
objectClass: organizationalUnit
ou: People

dn: $LDAP_GROUP_BASEDN
objectClass: organizationalUnit
ou: Group
EOF

sudo ldapadd -x -W -D "$LDAP_USER" -f base.ldif
}

run_modify_db () {
  ldap_password
  modify_olc
  modify_base
  modify_monitor
}