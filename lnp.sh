#! /bin/bash
for i in {11..13}
do
  ssh root@192.168.2.${i} '
      rm -rf /usr/local/nginx;
      killall nginx;
      yum -y install gcc make pcre-devel openssl-devel;
      yum -y install php php-fpm php-mysql;
      cd /mnt/nginx-1.12.2/;
      useradd nginx;
      ./configure --user=nginx --group=nginx --with-http_ssl_module;
      make && make install;
      sed -i "45{s/index.html/index.php index.html/}" /usr/local/nginx/conf/nginx.conf;
      sed -i "65,71{s/#//}" /usr/local/nginx/conf/nginx.conf;
      sed -ri "69{s/([^a-Z]*)([a-Z]{1,})(.*)/\1#\2\3/}" /usr/local/nginx/conf/nginx.conf;
      sed -i "70{s/fastcgi_params;/fastcgi.conf;/}" /usr/local/nginx/conf/nginx.conf;

      echo "[Unit]
      Description=The nginx Server
      After=network.target remote-fs.target nss-lookup.target
      
      [Service]
      Type=forking
      ExecStart=/usr/local/nginx/sbin/nginx 
      ExecReload=/usr/local/nginx/sbin/nginx -s reload
      ExecStop=/bin/killall nginx
      
      [Install]
      WantedBy=multi-user.target" > /usr/lib/systemd/system/nginx.service;
      systemctl restart nginx.service;
      systemctl enable nginx.service;
      systemctl restart php-fpm;
      systemctl enable php-fpm;
  '
done
