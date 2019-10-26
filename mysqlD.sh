#! /bin/bash
glhost1=59
glhost2=60
for i in ${glhost1} ${glhost2}
do
  scp -o StrictHostKeyChecking=no /linux-soft/03/mysql/mysql-5.7.17.tar root@192.168.4.${i}:/root
  ssh root@192.168.4.${i} '
  	host1=59
	host2=60
  	mkdir /root/Imysql
	tar -xf /root/mysql-5.7.17.tar -C /root/Imysql
	rm -rf /var/lib/mysql
	rm -rf /var/log/mysqld.log
	systemctl stop mysqld
	systemctl disable mysqld
	yum -y remove mysql-com*
	cd /root/Imysql
	yum -y install mysql-com*.rpm
	systemctl restart mysqld
	systemctl enable mysqld
	mysqladmin -uroot -p"$(grep -w password /var/log/mysqld.log | head -1 | cut -d " " -f 11)" password "123qqq...A"
	myid=$(ifconfig eth0 | grep inet | cut -d " " -f 10 | cut -d "." -f 4)
	sed -i "/\[mysqld\]/a server_id="${myid}"\nlog_bin=/mylog/master"${myid}"" /etc/my.cnf
	mkdir /mylog
	chown mysql:mysql /mylog
	systemctl restart mysqld
	host[${host1}]=${host2}
	host[${host2}]=${host1}
	mysql -uroot -p123qqq...A -e "
		grant replication slave on *.* to repluser@\"%\" identified by \"123qqq...A\";
		reset master;
		stop slave;
		change master to master_host=\"192.168.4.${host[${myid}]}\",
				 master_user=\"repluser\",
				 master_password=\"123qqq...A\",
				 master_log_file=\"master${host[${myid}]}.000001\",
				 master_log_pos=154;
		start slave;
	"
  '
done
sleep 1
for i in ${glhost1} ${glhost2}
do
  ssh root@192.168.4.${i} 'mysql -uroot -p123qqq...A -e "show slave status\G" | grep -i running'
done
