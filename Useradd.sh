#!/bin/bash
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bkp
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bkp
cp /etc/login.defs /etc/login.defs.bkp
sed -i '/pam_listfile.so/s/^/##/' /etc/pam.d/system-auth
sed -i '/AllowGroups/s/^/##/' /etc/ssh/sshd_config
sed -i '/AllowUsers/s/^/##/' /etc/ssh/sshd_config
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   0/1' /etc/login.defs
mv /etc/raddb/server /etc/raddb/server.bkp
#sed -i '/AllowGroups/s/$/ lnx.admin1 lnx.admin2 lnx.admin3 /' sshd_config
/bin/systemctl restart sshd

/bin/tee /tmp/userlist <<EOF
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

userfile=/tmp/userlist

username=$(cat /tmp/userlist | tr 'A-Z'  'a-z')

password=My53cretP@55123

for user in $username
do

       useradd $user -d /home/PINESERVERS/$user
       echo $password | passwd --stdin $user
done

#echo "$(wc -l /tmp/userlist) users have been created"
#tail -n$(wc -l /tmp userlist) /etc/passwd

exit
