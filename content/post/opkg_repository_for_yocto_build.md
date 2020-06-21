---
title: "Custom opkg repository"
description: "Simple repository server o handle opkg utiliey in embbeded systems"
draft: false
tags : 
 - "opkg"
 - "yocto"
date : "2020-06-18"
archives : "2020"
categories : 
 - "linux"

menu : "no-main"
---
The post presenst simple example to create opkg repository to upgrade embbded linux systems using nginx server. The opkg pakcge should be installed as part of the image furing the first instalation. To add opkg to yocto image type type folloing line in file *conf/local.conf*
```bash
IMAGE_INSTALL_append = "
	opkg \
"
```
downlad and install opkg utils:
```bash
git clonbe git://git.yoctoproject.org/opkg-utils
```

and create Packages.gz file:
```bash
cd /path-to-yocto-build/build/tmp/deploy/ipk
~/opkg-utils/opkg-make-index . > Packages.gz
```

## install nginx
I haved used gentoo system , so inorder to install nginx on gentoo type:
```bash
emerge nginx
```
now , config a simple nxing configuration file under */etc/nginx/nginx.conf*
```bash
user nginx nginx;
worker_processes 1;

error_log /var/log/nginx/error_log info;

events {
	worker_connections 1024;
	use epoll;
}

http {
	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	log_format main
		'$remote_addr - $remote_user [$time_local] '
		'"$request" $status $bytes_sent ' 
		'"$http_referer" "$http_user_agent" '
		'"$gzip_ratio"';

	client_header_timeout 10m;
	client_body_timeout 10m;
	send_timeout 10m;

	connection_pool_size 256;
	client_header_buffer_size 1k;
	large_client_header_buffers 4 2k;
	request_pool_size 4k;

	gzip off;

	output_buffers 1 32k;
	postpone_output 1460;

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;

	keepalive_timeout 75 20;

	ignore_invalid_headers on;
#	include /etc/nginx/sites-enabled/*;
#	index Packages.gz;


	server {
		listen 80 default_server;
		listen         [::]:80 default_server;
		server_name localhost;

		location / {
			root /path-to-yocto-build/build/tmp/deploy/ipk;
			rewrite  ^/repo(.*)$ /$1  last;
  			break;
		}
	}

}
```

and then restart nginx:
```bash
/etc/init.d/nginx restart
```

## define the device
In the linux device, add the following line to */etc/opkg/opkg.con*/
```bash
src/gz  repo  http://server.name.or.ip.address/repo
```

to test it type:
```bash
opkg update
```

## References
[1] https://stackoverflow.com/questions/9650756/nginx-ignore-location-part
