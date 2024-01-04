#!/bin/bash

docker compose down -v
rm -rf ./master/data/* -y
rm -rf ./slave/data/* -y
docker compose build
docker compose up -d

until docker exec mysql_master sh -c 'export MYSQL_PWD=QEFDd434f33gt!@CGg; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

priv_stmt='CREATE USER "bidsee_slv"@"%" IDENTIFIED BY "QEFDd434f33gt!@CGg"; GRANT REPLICATION SLAVE ON *.* TO "bidsee_slv"@"%"; FLUSH PRIVILEGES;'
docker exec mysql_master sh -c "export MYSQL_PWD=QEFDd434f33gt!@CGg; mysql -u root -e '$priv_stmt'"

until docker compose exec mysql_slave sh -c 'export MYSQL_PWD=QEFDd434f33gt!@CGg; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave database connection..."
    sleep 4
done

MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=QEFDd434f33gt!@CGg; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='bidsee_slv',MASTER_PASSWORD='QEFDd434f33gt!@CGg',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='export MYSQL_PWD=QEFDd434f33gt!@CGg; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'
docker exec mysql_slave sh -c "$start_slave_cmd"

docker exec mysql_slave sh -c "export MYSQL_PWD=QEFDd434f33gt!@CGg; mysql -u root -e 'SHOW SLAVE STATUS \G'"
