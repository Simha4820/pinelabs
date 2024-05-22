#!/bin/bash
# Backup necessary configuration files
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bkp
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkp
cp /etc/login.defs /etc/login.defs.bkp

# Modify configuration files
sed -i '/pam_listfile.so/s/^/##/' /etc/pam.d/system-auth
sed -i '/AllowGroups/s/^/##/' /etc/ssh/sshd_config
sed -i '/AllowUsers/s/^/##/' /etc/ssh/sshd_config
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   0/' /etc/login.defs

# Backup the raddb server file if it exists
if [ -f /etc/raddb/server ]; then
    mv /etc/raddb/server /etc/raddb/server.bkp
fi

# Restart the sshd service
/bin/systemctl restart sshd

# Create a list of users
cat <<EOF > /tmp/userlist
lnxpladmin
lnx.admin1
lnx.admin2
lnx.admin3
lnx.sudo1
lnx.sudo2
lnx.sudo3
lnx.ro1
lnx.ro2
lnx.ro3
EOF

# Set the password for the users
password='My53cretP@55123'

# Convert usernames to lowercase and create users
for user in $(cat /tmp/userlist | tr 'A-Z' 'a-z'); do
    useradd $user -d /home/PINESERVERS/$user
    echo "$user:$password" | chpasswd
done

exit
