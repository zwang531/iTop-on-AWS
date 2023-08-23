#!/bin/bash
# 安装环境aws linux 2023

# ssh远程登陆EC2
# ssh -i yourec2key.pem ec2-user@public_ip_addr

# 安装Apache
# sudo su
yum install -y apr-devel apr-util-devel openssl-devel libevent-devel pcre-devel gcc
cd /usr/local/src/
wget https://dlcdn.apache.org/httpd/httpd-2.4.57.tar.gz
tar xf httpd-2.4.57.tar.gz
cd httpd-2.4.57/
./configure --prefix=/usr/local/httpd --enable-so --enable-ssl --enable-cgi --enable-rewrite \
			--enable-modules=most --enable-mpms-shared=all --with-mpm=prefork --with-zlib --with-pcre \
			--with-apr=/usr --with-apr-util=/usr
make && make install
echo 'export PATH="/usr/local/httpd/bin:$PATH"' >>/etc/profile
export PATH="/usr/local/httpd/bin:$PATH"

# 检测httpd安装版本
apachectl -v
# 创建www用户
useradd -u 8888 -s /sbin/nologin -M www
id www
# 修改配置文件
cp /usr/local/httpd/conf/httpd.conf{,_$(date +%Y%m%d%H%M)}
egrep -i '^user|^group' /usr/local/httpd/conf/httpd.conf
# 配置ServerName
sed -ri 's#\#(ServerName )(.*)#\1 127.0.0.1:80#g' /usr/local/httpd/conf/httpd.conf
grep ServerName /usr/local/httpd/conf/httpd.conf
# 启动httpd服务
apachectl
ps aux|grep httpd
netstat -nlutp|grep httpd
curl 127.0.0.1

# 安装PHP
yum install -y  libpng-devel libjpeg-devel bison bison-devel zlib-devel \
		openssl-devel libxml2-devel libcurl-devel bzip2-devel readline-devel libedit-devel \
		sqlite-devel jemalloc jemalloc-devel openldap-devel oniguruma-devel libtool gd gd-devel
cd /usr/local/src/
wget https://www.php.net/distributions/php-8.1.22.tar.gz
tar xf php-8.1.22.tar.gz
cd php-8.1.22/
cp -frp /usr/lib64/libldap* /usr/lib/
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-apxs2=/usr/local/httpd/bin/apxs \
--disable-debug \
--disable-rpath \
--enable-shared \
--enable-opcache \
--enable-fpm \
--enable-gd \
--with-fpm-user=www \
--with-fpm-group=www \
--with-mysqli \
--with-openssl \
--with-zip \
--with-zlib \
--with-curl \
--with-iconv \
--with-ldap \
--with-ldap-sasl \
--with-bz2 \
--with-readline \
--with-gettext \
--with-mhash \
--with-zlib \
--with-jpeg \
--with-freetype \
--enable-soap \
--enable-mbstring \
--enable-bcmath \
--enable-pcntl \
--enable-shmop \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--enable-sockets
sed -ri 's#(^EXTRA_LIBS =.*)#\1 -llber#gp' Makefile
make && make install
libtool --finish /usr/local/src/php-8.1.22/libs
# 拷贝配置文件
cp php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf{.default,}

# 修改Apache配置文件并重启Apache
# 在DirectoryIndex后面添加：index.php
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.php/' /usr/local/httpd/conf/httpd.conf
grep "DirectoryIndex"  /usr/local/httpd/conf/httpd.conf
# 在AddType application/x-gzip .gz .tgz后面添加：AddType application/x-httpd-php .php
sed -i '/AddType application\/x-gzip .gz .tgz/a AddType application/x-httpd-php .php' /usr/local/httpd/conf/httpd.conf
grep -A 2 'AddType application/x-gzip .gz' /usr/local/httpd/conf/httpd.conf
# 重启Apache
apachectl stop
apachectl
# 创建index.php文件访问测试
cat >/usr/local/httpd/htdocs/index.php<<EOF
<?php
phpinfo();
?>
EOF

# 安装MySQL
cd ~
yum install -y make tree gcc-c++ cmake bison-devel ncurses-devel libaio libaio-devel perl-Data-Dumper \
libtirpc libtirpc-devel rpcgen
yum groupinstall -y "Development Tools"
cd /usr/local/src/
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.34.tar.gz
tar xf mysql-8.0.34.tar.gz
cd mysql-8.0.34
dnf install java-11-amazon-corretto-devel
mkdir build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DMYSQL_UNIX_ADDR=/usr/local/mysql/tmp/mysql.sock \
-DEXTRA_CHARSETS=gbk,gb2312,utf8,ascii \
-DENABLED_LOCAL_INFILE=ON \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
-DWITH_FAST_MUTEXES=1 \
-DWITH_ZLIB=bundled \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_EMBEDDED_SERVER=1 \
-DWITH_DEBUG=0 \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=/usr/local/src/boost
make && make install
# 设置环境变量
ln -s /usr/local/mysql/scripts/mysql_install_db /usr/local/mysql/bin/
echo 'export PATH="/usr/local/mysql/bin:$PATH"' >>/etc/profile
export PATH="/usr/local/mysql/bin:$PATH"
mysql -V
# mysql  Ver 8.0.34 for Linux on x86_64 (Source distribution)
# 创建mysql用户
groupadd -g 8000 mysql
useradd -u 8000 -g 8000 mysql
# 创建数据库目录
mkdir -p /data/dbdata/mysql_3306/{binlogs,innodb_data,innodb_logs,logs,relaylogs,socket,tmp}
chown -R mysql.mysql /data/dbdata/mysql_3306/
# 配置my.conf文件 /etc/my.conf
# 初始化数据库目录
mysqld --defaults-file=/etc/my.cnf \
       --user=mysql \
       --basedir=/usr/local/mysql \
       --datadir=/data/dbdata/mysql_3306/mydata \
       --initialize
# 创建error.log
touch /data/dbdata/mysql_3306/logs/error.log
chown mysql.mysql /data/dbdata/mysql_3306/logs/error.log
# 启动mysql
mysqld_safe &
netstat -nlutp|grep mysql
