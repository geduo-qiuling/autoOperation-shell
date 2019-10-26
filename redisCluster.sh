#! /bin/bash
startHost=58
stopHost=59
for i in $(seq ${startHost} ${stopHost})
do
	scp -o StrictHostKeyChecking=no /linux-soft/03/redis/redis-4.0.8.tar.gz root@192.168.4.${i}:/root
	ssh root@192.168.4.${i} '
		export myIp=$(ifconfig eth0 | grep inet | cut -d " " -f 10 | cut -d "." -f 4)
		export myPort=63${myIp}
		export Config_file=/etc/redis/${myPort}.conf
		export Log_file=/var/log/redis_${myPort}.log
		export Data_dir=/var/lib/redis/${myPort}
		export Executable=/usr/local/bin/redis-server
		export Cli_Executable=/usr/local/bin/redis-cli
		rm -rf /root/redis-4.0.8
		rm -rf /var/lib/redis/${myPort}/*
		tar -xf /root/redis-4.0.8.tar.gz
		cd /root/redis-4.0.8
		yum -y install gcc
		make && make install
		cd ./utils
		installSH=install_server.sh
		sed -i "s/6379/"${myPort}"/" ${installSH}
		sed -i "68,129d;146,148d" ${installSH}
		sed -i "47a REDIS_PORT=\$1\nREDIS_CONFIG_FILE=\$2\nREDIS_LOG_FILE=\$3\nREDIS_DATA_DIR=\$4\nREDIS_EXECUTABLE=\$5\nCLI_EXEC=\$6" ${installSH}
		bash ./${installSH} ${myPort} ${Config_file} ${Log_file} ${Data_dir} ${Executable} ${Cli_Executable}
		redisconf_PATH=/etc/redis/${myPort}.conf
		sed -i "/^bind/d;/^port/d;/cluster-enabled/d;/cluster-config-file/d;/cluster-node-timeout/d" ${redisconf_PATH}
		lineNUM=$(wc -l ${redisconf_PATH} | cut -d " " -f 1)
		sed -i ""${lineNUM}"a bind\ 192.168.4."${myIp}"\nport\ "${myPort}"\ncluster-enabled\ yes\ncluster-config-file\ nodes-"${myPort}".conf\ncluster-node-timeout\ 5000" ${redisconf_PATH}
		sed -i "s/6379/"${myPort}"/" /etc/rc.d/init.d/redis_${myPort}
		sed -i "s/\$CLIEXEC\ -p\ \$REDISPORT\ shutdown/\$CLIEXEC\ -p\ \$REDISPORT\ -h\ 192.168.4."${myIp}" shutdown/" /etc/rc.d/init.d/redis_${myPort}
		redis-cli -h 127.0.0.1 -p ${myPort} shutdown
		/etc/init.d/redis_${myPort} stop
		/etc/init.d/redis_${myPort} start
	'
done

for i in $(seq ${startHost} ${stopHost})
do
	ssh root@192.168.4.${i} 'echo -e "\033[32m$(hostname)\033[0m";netstat -antulp | grep --color=always redis'
done
