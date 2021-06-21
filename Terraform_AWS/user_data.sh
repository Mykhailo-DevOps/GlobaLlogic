#!/bin/bash
apt -y update
apt -y install apache2

myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<body bgcolor="gray">
<h2><font color="gold">Build by Power of Terraform<font color="red"> GlobalLogic BaseCamp</font></h2><br><p>
<font color="green">Server PrivateIP: <font color="aqua">$myip<br><br>
<font color="magenta">
<b>Version 3.46.0</b>
</body>
</html>
EOF

sudo service apache2 start
chkconfig apache2 on
