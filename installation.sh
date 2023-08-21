# 安装环境 AWS Linux 2023

# ssh远程登陆EC2
# ssh -i yourec2key.pem ec2-user@public_ip_addr

# 安装Apache
sudo -i
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

# 安装PHP
cd
yum install -y libpng-devel libjpeg-devel bison bison-devel zlib-devel openssl-devel libxml2-devel libcurl-devel \
bzip2-devel readline-devel libedit-devel sqlite-devel jemalloc jemalloc-devel openldap-devel oniguruma-devel
cd /usr/local/src/
wget https://www.php.net/distributions/php-8.2.9.tar.gz
tar xf php-8.2.9.tar.gz
cd php-8.2.9/
cp -frp /usr/lib64/libldap* /usr/lib/
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-apxs2=/usr/local/httpd/bin/apxs \
--enable-inline-optimization \
--disable-debug \
--disable-rpath \
--enable-shared \
--enable-opcache \
--enable-fpm \
--with-fpm-user=www \
--with-fpm-group=www \
--with-mysql \
--with-mysqli \
--with-openssl \
--with-zlib \
--with-curl \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-iconv \
--with-ldap \
--with-mcrypt \
--with-bz2 \
--with-readline \
--with-libxml-dir \
--with-gettext \
--with-mhash \
--enable-zip \
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
# 拷贝配置文件
cp php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf{.default,}
# 修改Apache配置文件并重启Apache

# 安装MySQL
# TODO 

# 安装GraphViz
# TODO

# 部署配置iTop
# TODO
