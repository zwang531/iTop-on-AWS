# iTop on AWS Installation
Configure LAMP on EC2 and install iTop ITSM

### 安装环境
在Amazon Linux环境下部署LAMP，相关软件版本如下：
- httpd-2.4.57
- php-8.1.22
- mysql-8.0.34
  

### ssh远程登陆EC2
```
ssh -i yourec2key.pem ec2-user@public_ip_addr
```

### 安装Apache
1. 切换为root user，安装依赖包
```
[user@ip-... ~]# sudo -i
[root@ip-... ~]# yum install -y apr-devel apr-util-devel openssl-devel libevent-devel pcre-devel gcc
```
2. 下载Apache并解压安装
```
[root@ip-... ~]# cd /usr/local/src/
[root@ip-... src]# wget https://dlcdn.apache.org/httpd/httpd-2.4.57.tar.gz
[root@ip-... src]# tar xf httpd-2.4.57.tar.gz
[root@ip-... src]# cd httpd-2.4.57/
[root@ip-... httpd-2.4.57]# ./configure --prefix=/usr/local/httpd --enable-so --enable-ssl --enable-cgi --enable-rewrite \
                             --enable-modules=most --enable-mpms-shared=all --with-mpm=prefork --with-zlib --with-pcre \
                             --with-apr=/usr --with-apr-util=/usr
[root@ip-... httpd-2.4.57]# make && make install
```
3. 设置环境变量
```
root@ip-... httpd-2.4.57]# echo 'export PATH="/usr/local/httpd/bin:$PATH"' >>/etc/profile
root@ip-... httpd-2.4.57]# export PATH="/usr/local/httpd/bin:$PATH"
# 检测httpd安装版本
root@ip-... httpd-2.4.57]# apachectl -v
Server version: Apache/2.4.37 (Unix)
Server built:   Dec 23 2018 05:19:59
```
4. 配置Apache并启动
```
# 创建www用户
[root@ip-... httpd-2.4.57]# useradd -u 8888 -s /sbin/nologin -M www
[root@ip-... httpd-2.4.57]# id www
uid=8888(www) gid=8888(www) groups=8888(www)
# 修改配置文件
[root@ip-... httpd-2.4.57]# cp /usr/local/httpd/conf/httpd.conf{,_$(date +%Y%m%d%H%M)}
[root@ip-... httpd-2.4.57]# egrep -i '^user|^group' /usr/local/httpd/conf/httpd.conf
User daemon
Group daemon
# 配置ServerName
[root@ip-... httpd-2.4.57]# sed -ri 's#\#(ServerName )(.*)#\1 127.0.0.1:80#g' /usr/local/httpd/conf/httpd.conf
[root@ip-... httpd-2.4.57]# grep ServerName /usr/local/httpd/conf/httpd.conf
# ServerName gives the name and port that the server uses to identify itself.
ServerName www.example.com:80
# 启动httpd服务
[root@ip-... httpd-2.4.57]# apachectl 
[root@ip-... httpd-2.4.57]# ps aux|grep httpd
root      20425  0.0  0.0  76748  2088 ?        Ss   05:37   0:00 /usr/local/httpd/bin/httpd
www       20426  0.0  0.0  76748  1472 ?        S    05:37   0:00 /usr/local/httpd/bin/httpd
www       20427  0.0  0.0  76748  1472 ?        S    05:37   0:00 /usr/local/httpd/bin/httpd
www       20428  0.0  0.0  76748  1472 ?        S    05:37   0:00 /usr/local/httpd/bin/httpd
www       20429  0.0  0.0  76748  1472 ?        S    05:37   0:00 /usr/local/httpd/bin/httpd
www       20430  0.0  0.0  76748  1472 ?        S    05:37   0:00 /usr/local/httpd/bin/httpd
root      20434  0.0  0.0 112708   964 pts/0    S+   05:37   0:00 grep --color=auto httpd
[root@ip-... httpd-2.4.57]# netstat -nlutp|grep httpd
tcp6       0      0 :::80                   :::*                    LISTEN      20425/httpd
```
> ***注意：*** Apache启动命令“apachectl”，停止命令“apachectl stop”
5. 访问测试
```
[root@ip-... httpd-2.4.57]# curl 127.0.0.1
<html><body><h1>It works!</h1></body></html>
```
到此我们的Apache已经按照完成了，下面我们安装PHP

### 安装PHP
1. 安装依赖包
```
[root@ip-... ~]# yum install -y libpng-devel libjpeg-devel bison bison-devel zlib-devel \
                     openssl-devel libxml2-devel libcurl-devel bzip2-devel readline-devel libedit-devel \
                     sqlite-devel jemalloc jemalloc-devel openldap-devel oniguruma-devel libtool
```
> ***注意：***
> libmcrypt-devel mcrypt mhash-devel are deprecated, so ignored
2. 下载PHP并解压安装
```
[root@ip-... ~]# cd /usr/local/src/
[root@ip-... src]# wget https://www.php.net/distributions/php-8.1.22.tar.gz
[root@ip-... src]# tar xf php-8.1.22.tar.gz
[root@ip-... src]# cd php-8.1.22/
[root@ip-... php-8.1.22]# cp -frp /usr/lib64/libldap* /usr/lib/
[root@ip-... php-8.1.22]# ./configure --prefix=/usr/local/php \
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
[root@ip-... php-8.1.22]# sed -ri 's#(^EXTRA_LIBS =.*)#\1 -llber#gp' Makefile
[root@ip-... php-8.1.22]# make && make install
[root@ip-... php-8.1.22]# libtool --finish /usr/local/src/php-8.1.22/libs
# 拷贝配置文件
[root@ip-... php-8.1.22]# cp php.ini-production /usr/local/php/etc/php.ini
[root@ip-... php-8.1.22]# cp /usr/local/php/etc/php-fpm.conf{.default,}
```
> ***注意:***
> configure: WARNING: unrecognized options: --enable-inline-optimization, --with-mysql, --with-gd, --with-jpeg-dir, --with-png-dir, --with-mcrypt, --with-libxml-dir, --enable-zip

3. 修改Apache配置文件并重启Apache
```
# 在DirectoryIndex后面添加：index.php
[root@ip-... php-8.1.22]# grep "DirectoryIndex"  /usr/local/httpd/conf/httpd.conf
# DirectoryIndex: sets the file that Apache will serve if a directory
   DirectoryIndex index.html index.php
# 在AddType application/x-gzip .gz .tgz后面添加：AddType application/x-httpd-php .php
[root@ip-... php-8.1.22]# grep -A 2 'AddType application/x-gzip .gz' /usr/local/httpd/conf/httpd.conf
    AddType application/x-gzip .gz .tgz
    AddType application/x-httpd-php .php
# 重启Apache
[root@ip-... php-8.1.22]# apachectl stop
[root@ip-... php-8.1.22]# apachectl
```
4. index.php文件访问测试
```
[root@ip-... php-8.1.22]# cat >/usr/local/httpd/htdocs/index.php<<EOF
<?php
   phpinfo();
?>
EOF
```

### Enable HTTPS and systemctl
1. Enable TLS on the server
```
[root@ip-... ~]# yum install openssl mod_ssl
[root@ip-... ~]# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/localhost.key -out \     
                         /etc/pki/tls/certs/localhost.crt
```
2. 在httpd.conf文件中添加Listen 443和VirtualHost
```
[root@ip-... ~]# grep Listen /usr/local/httpd/conf/httpd.conf
#Listen 12.34.56.78:80
Listen 80
# 在后面添加Listen 443
[root@ip-... ~]# grep Listen /usr/local/httpd/conf/httpd.conf
#Listen 12.34.56.78:80
Listen 80
Listen 443
# uncomment line "LoadModule ssl_module modules/mod_ssl.so"
# 添加VirtualHost
<VirtualHost *:443>
    DocumentRoot "/path/to/your/documentroot"
    ServerName 127.0.0.1:443
    SSLEngine on
    SSLCertificateFile "/path/to/your/certificatefile.crt"
    SSLCertificateKeyFile "/path/to/your/privatekeyfile.key"
</VirtualHost>
# 如何寻找”/path/to/your/certificatefile.crt“和"/path/to/your/privatekeyfile.key"
[root@ip-... ~]# find / -name "localhost.crt" 2>/dev/null
/etc/pki/tls/certs/localhost.crt
[root@ip-... ~]# find / -name "localhost.key" 2>/dev/null
/etc/pki/tls/private/localhost.key
# 如何寻找"/path/to/your/documentroot"
[root@ip-... ~]# grep -ri "DocumentRoot" /usr/local/httpd/conf/
/usr/local/httpd/htdocs
# 检查conf的Syntax
[root@ip-... ~]# apachectl configtest
[root@ip-... ~]# apachectl restart
```
3. 创建httpd.service文件，因为Apache是从tar文件被安装的，所以httpd.service没有自动创建
```
# locate apachectl
[root@ip-... ~]# which apachectl
/usr/local/httpd/bin/apachectl
# create /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "[Unit]" > /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "Description=The Apache HTTP Server" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "After=network.target remote-fs.target nss-lookup.target" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "[Service]" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "Type=forking" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "ExecStart=/usr/local/httpd/bin/apachectl start" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "ExecReload=/usr/local/httpd/bin/apachectl graceful" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "ExecStop=/usr/local/httpd/bin/apachectl stop" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "PrivateTmp=true" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "[Install]" >> /usr/lib/systemd/system/httpd.service
[root@ip-... ~]# echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/httpd.service
# Override systemd service
[root@ip-... ~]# systemctl edit httpd
# add the following to httpd.service.d
[Service]
ExecStart=
ExecStart=/usr/local/httpd/bin/apachectl start
ExecReload=
ExecReload=/usr/local/httpd/bin/apachectl graceful
ExecStop=
ExecStop=/usr/local/httpd/bin/apachectl stop
[root@ip-... ~]# systemctl daemon-reload
[root@ip-... ~]# systemctl restart httpd
# Ensure systemctl starts on boot
[root@ip-... ~]# systemctl enable httpd
```
> ***注意：***
> 1. 确保certificate的名称为localhost, for development use.
> 2. 因为使用的是self-signed certificate，所以即使开启SSL/TSL，https连接依然会显示为"not secured". This could be solved with a certificate from a recognized CA and make sure the domain name matchs with the certificate.

### 安装MySQL
1. 安装依赖包
```
[root@ip-... ~]# yum install -y make gcc-c++ cmake bison-devel ncurses-devel libaio libaio-devel perl-Data-Dumper libtirpc libtirpc-devel rpcgen
[root@ip-... ~]# yum groupinstall -y "Development Tools"
```
2.下载mysql，解压安装
```
[root@ip-... ~]# cd /usr/local/src/
[root@ip-... src]# wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.34.tar.gz
[root@ip-... src]# tar xf mysql-8.0.34.tar.gz
[root@ip-... src]# cd mysql-8.0.34
[root@ip-... mysql-8.0.34]# dnf install java-11-amazon-corretto-devel
[root@ip-... mysql-8.0.34]# mkdir build
[root@ip-... mysql-8.0.34]# cd build
[root@ip-... build]# cmake ../ -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
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
[root@ip-... build]# make && make install
```
3. 设置环境变量
```
[root@ip-... mariadb-10.6.15]# ln -s /usr/local/mysql/scripts/mysql_install_db /usr/local/mysql/bin/
[root@ip-... mariadb-10.6.15]# echo 'export PATH="/usr/local/mysql/bin:$PATH"' >>/etc/profile
[root@ip-... mariadb-10.6.15]# tail -1 /etc/profile
export PATH="/usr/local/mysql/bin:$PATH"
[root@ip-... mariadb-10.6.15]# export PATH="/usr/local/mysql/bin:$PATH"
[root@ip-... mariadb-10.6.15]# mysql -V
mysql  Ver 15.1 Distrib 10.6.15-MariaDB, for Linux (x86_64) using  EditLine wrapper
```
4. 创建mysql用户
```
[root@ip-... mariadb-10.6.15]# groupadd -g 8000 mysql
[root@ip-... mariadb-10.6.15]# useradd -u 8000 -g 8000 mysql
[root@ip-... mariadb-10.6.15]# id mysql
uid=8000(mysql) gid=8000(mysql) groups=8000(mysql)
```
5.创建数据库目录
```
[root@ip-... mariadb-10.6.15]# mkdir -p /data/dbdata/mysql_3306/{binlogs,innodb_data,innodb_logs,logs,mydata,relaylogs,socket,tmp}
[root@ip-... mariadb-10.6.15]# tree /data/dbdata/mysql_3306/
/data/dbdata/mysql_3306/
├── binlogs
├── innodb_data
├── innodb_logs
├── logs
├── mydata
├── relaylogs
├── socket
└── tmp

8 directories, 0 files
[root@ip-... mariadb-10.6.15]# chown -R mysql:mysql /data/dbdata/mysql_3306/
[root@ip-... mariadb-10.6.15]# chmod -R 770 /data/dbdata/mysql_3306/
```
6. 配置my.conf文件
```
[root@ip-... mariadb-10.6.15]# cat /etc/my.cnf
[root@linux-node1 mysql-5.6.37]# cat /etc/my.cnf
[client]
port = 3306
socket = /data/dbdata/mysql_3306/socket/mysql.sock

[mysql]
no-auto-rehash

[mysqld]
user = mysql
port = 3306
basedir = /usr/local/mysql/
datadir = /data/dbdata/mysql_3306/mydata
pid-file = /data/dbdata/mysql_3306/logs/mysqld.pid
socket = /data/dbdata/mysql_3306/socket/mysql.sock
tmpdir = /data/dbdata/mysql_3306/tmp
character_set_server = utf8mb4
open_files_limit    = 1024
back_log = 600
max_connections = 800
max_connect_errors = 3000
table_open_cache = 614
external-locking = FALSE
max_allowed_packet =128M
sort_buffer_size = 1M
join_buffer_size = 1M


thread_cache_size = 100
thread_stack = 192K
tmp_table_size = 2M
max_heap_table_size = 2M

# 主从复制配置
server-id = 1
slow_query_log = 1
slow_query_log_file = /data/dbdata/mysql_3306/logs/slowq.log
long_query_time = 1
log-bin = /data/dbdata/mysql_3306/binlogs/mysql-bin
relay-log = /data/dbdata/mysql_3306/relaylogs/relay-bin
binlog_cache_size = 1M
max_binlog_cache_size = 1M
max_binlog_size = 512M
key_buffer_size = 16M
read_buffer_size = 1M
read_rnd_buffer_size = 1M
bulk_insert_buffer_size = 1M
lower_case_table_names = 1
skip-name-resolve
replica_skip_errors = 1032,1062

# innodb引擎配置
default_storage_engine = InnoDB
innodb_data_home_dir = /data/dbdata/mysql_3306/innodb_data
innodb_log_group_home_dir = /data/dbdata/mysql_3306/innodb_logs
innodb_buffer_pool_size = 128M
innodb_data_file_path = ibdata1:128M:autoextend
innodb_thread_concurrency = 8
innodb_flush_log_at_trx_commit = 0
innodb_log_buffer_size = 32M
innodb_redo_log_capacity = 384M
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
innodb_file_per_table = 1
innodb_change_buffering = all
innodb_purge_threads = 1
innodb_read_io_threads = 6
innodb_write_io_threads = 6
innodb_io_capacity = 2000

[mysqldump]
quick
max_allowed_packet = 2M

[mysqld_safe]
log-error=/data/dbdata/mysql_3306/logs/error.log
pid-file=/data/dbdata/mysql_3306/logs/mysqld.pid
```
7. 初始化数据库目录
```
[root@linux-node1 mysql-5.6.37]# mysqld --defaults-file=/etc/my.cnf \
                                        --user=mysql \
                                        --basedir=/usr/local/mysql \
                                        --datadir=/data/dbdata/mysql_3306/mydata \
                                        --initialize
```
8. 启动MySQL数据库
```
# 创建error.log
[root@linux-node1 mysql-5.6.37]# touch /data/dbdata/mysql_3306/logs/error.log
[root@linux-node1 mysql-5.6.37]# chown mysql.mysql /data/dbdata/mysql_3306/logs/error.log
# 启动mysql
[root@linux-node1 mysql-5.6.37]# mysqld_safe &
[root@linux-node1 mysql-5.6.37]# netstat -nlutp|grep mysql
tcp6       0      0 :::3306                 :::*                    LISTEN      330472/mysqld       
tcp6       0      0 :::33060                :::*                    LISTEN      330472/mysqld 
```
> ***注意:*** Starting from MySQL 8.0, 33060 is the port for the MySQL X Protocol, which is a new protocol for client-server communication, different from the classic MySQL protocol used on port 3306. The X Protocol supports more advanced features, including the MySQL Document Store.
9. Create /etc/systemd/system/httpd.service
```
[root@linux-node1 mysql-5.6.37]# cat /etc/systemd/system/httpd.service
[Unit]
Description=MySQL Community Server
After=network.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld_safe
ExecStop=/usr/local/mysql/bin/mysqladmin shutdown
Restart=on-failure

[Install]
WantedBy=multi-user.target
[root@linux-node1 mysql-5.6.37]# systemctl daemon-reload
[root@linux-node1 mysql-5.6.37]# systemctl enable mysql
[root@linux-node1 mysql-5.6.37]# systemctl start mysql
```
10. 创建itop数据库并授权给itop用户
```
[root@linux-node1 mysql-5.6.37]# mysql -u root -p
mysql> create database itop;
mysql> CREATE USER 'itop'@'%' IDENTIFIED BY 'itop';
mysql> GRANT ALL ON itop.* TO 'itop'@'%';
```
> *** 注意：*** root password is eccom@123 and itop password is itop
11. 使用PHP连接mysql测试
```
[root@linux-node1 mysql-5.6.37]# yum install -y php-mysqli
[root@linux-node1 mysql-5.6.37]# cat /usr/local/httpd/htdocs/mysql.php
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$link = mysqli_connect("127.0.0.1", "itop", "itop");

if (!$link) {
    echo "FAILED! Connection error: " . mysqli_connect_error();
} else {
    echo "OK! Connected successfully";
}
?> 
[root@linux-node1 mysql-5.6.37]# curl http://127.0.0.1/mysql.php
OK! Connected successfully
```
12. Configure MySQL to accept remote connections
```
# optional
```

### Prerequisites
- Web Server: Apache Httpd :white_check_mark:
- GraphViz 
- DB Server: MySQL :white_check_mark:
```
[root@ip-... ~]# yum install graphviz
```
