#!/bin/bash -xe
DBPassword=$(aws ssm get-parameters --region ap-south-1 --names \
/ALBDemo/Wordpress/DBPassword --with-decryption --query Parameters[0].Value) 

DBPassword=`echo $DBPassword | sed -e 's/^"//' -e 's/"$//'`

DBRootPassword=$(aws ssm get-parameters --region ap-south-1 --names \
/ALBDemo/Wordpress/DBRootPassword --with-decryption --query \ Parameters[0].Value)

DBRootPassword=`echo $DBRootPassword | sed -e 's/^"//' -e 's/"$//'`

DBUser=$(aws ssm get-parameters --region ap-south-1 --names \
/ALBDemo/Wordpress/DBUser --query Parameters[0].Value) 

DBUser=`echo $DBUser | sed -e 's/^"//' -e 's/"$//'`

DBName=$(aws ssm get-parameters --region ap-south-1 --names \
/ALBDemo/Wordpress/DBName --query Parameters[0].Value)
 
DBName=`echo $DBName | sed -e 's/^"//' -e 's/"$//'`
DBEndpoint=$(aws ssm get-parameters --region ap-south-1 --names \
/ALBDemo/Wordpress/DBEndpoint --query Parameters[0].Value) 

DBEndpoint=`echo $DBEndpoint | sed -e 's/^"//' -e 's/"$//'`


yum -y update 
yum -y upgrade
yum install -y mariadb-server httpd wget 
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2 
amazon-linux-extras install epel -y
systemctl enable httpd 
systemctl enable mariadb 
systemctl start httpd
systemctl start mariadb

#setting up mariadb password
mysqladmin -u root password $DBRootPassword

wget http://wordpress.org/latest.tar.gz -P /var/www/html 
cd /var/www/html
tar -zxvf latest.tar.gz 
cp -rvf wordpress/* . 
rm -rf wordpress
rm latest.tar.gz
cp ./wp-config-sample.php ./wp-config.php
sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php 
sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php 
sed -i "s/'localhost'/'$DBEndpoint'/g" wp-config.php

usermod -a -G apache ec2-user 
chown -R ec2-user:apache /var/www 

chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \; 
find /var/www -type f -exec chmod 0664 {} \;
echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup 
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup 
rm /tmp/db.setup