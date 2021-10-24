#!/bin/bash

# ${ClickHouseVersion} 1
# ${ClickHouseNodeCount} 2
# ${RootStackName} 3
# ${AWS::Region} 4
# http://s3.${AWS::Region}.${AWS::URLSuffix}/${ClickHouseBucketName}/quickstart-clickhouse-data/ 5
# ${MoveFactor} 6
# ${ClickHouseTimezone} 7
# ${ZookeeperPrivateIp1} 8
# ${ZookeeperPrivateIp2} 9
# ${ZookeeperPrivateIp3} 10
# `python3 ./find-secret.py secretfile ` 11
# ${MaxThreads} 12
# ${MaxInsertThreads} 13
# ${DistributedProductMode} 14
# ${MaxMemoryUsage} 15
# ${LoadBalancing} 16
# ${MaxDataPartSize} 17
# ShardNum 18
# ReplicaNum 19
# ${SourceCodeStorage} 20

sudo useradd -m  -s /bin/bash clickhouse
passwd clickhouse<<EOF
${11}
${11}
EOF
sudo usermod -G clickhouse clickhouse

# If one disk only, use root disk
mkdir -p /home/clickhouse/data

mkdir /home/clickhouse/data/format_schemas/
mkdir /home/clickhouse/data/access/
mkdir /home/clickhouse/data/user_files/
mkdir /home/clickhouse/data/tmp/
mkdir /home/clickhouse/data/clickhouse-data/
mkdir /home/clickhouse/data/log/

mkdir -p /home/clickhouse/data/lib
ln -s /home/clickhouse/data/lib /var/lib/clickhouse
ln -s /home/clickhouse/data/log /var/log/clickhouse-server
chown -R clickhouse.clickhouse /home/clickhouse/
chown -R clickhouse.clickhouse /var/lib/clickhouse/

cd /var/lib/clickhouse/
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh 11
export CC=clang-11
export CXX=clang++-11

if [ ${20} = github ]; then
    if [ $4 = cn-north-1 ]; then
        git config --global url."https://gitee.com".insteadOf https://github.com
        git clone --recursive https://gitee.com/mirrors/clickhouse.git
        mv clickhouse ClickHouse
    elif [ $4 = cn-northwest-1 ]; then
        git config --global url."https://gitee.com".insteadOf https://github.com
        git clone --recursive https://gitee.com/mirrors/clickhouse.git
        mv clickhouse ClickHouse
    else
        #git clone --recursive https://github.com/ClickHouse/ClickHouse.git
        wget https://github.com/ClickHouse/ClickHouse/releases/download/v${1}-lts/ClickHouse_sources_with_submodules.tar.gz
        tar -xvf ClickHouse_sources_with_submodules.tar.gz
    fi
else
    aws s3 cp ${20} ./ --region ${4}
    unzip *.zip
fi
cd ClickHouse
mkdir build-arm64
cmake . -Bbuild-arm64 -DUSE_STATIC_LIBRARIES=0 -DSPLIT_SHARED_LIBRARIES=1 -DCLICKHOUSE_SPLIT_BINARY=1
ninja -C build-arm64 clickhouse > ninja.out



cd ..
#wget https://repo.yandex.ru/clickhouse/tgz/stable/clickhouse-client-$1.tgz
#wget https://repo.yandex.ru/clickhouse/tgz/stable/clickhouse-server-$1.tgz
wget https://repo.yandex.ru/clickhouse/tgz/lts/clickhouse-server-$1.tgz
wget https://repo.yandex.ru/clickhouse/tgz/lts/clickhouse-client-$1.tgz
tar -xzvf clickhouse-client-$1.tgz
tar -xzvf clickhouse-server-$1.tgz
find /var/lib/clickhouse/clickhouse-server-$1/install/ -name 'doinst.sh' | xargs perl -pi -e  "s|done|done;rm -f /usr/bin/clickhouse-*;cp -r -f /var/lib/clickhouse/ClickHouse/build-arm64/programs/clickhouse-* /usr/bin/|g"

chmod +x clickhouse-client-$1/install/doinst.sh
chmod +x clickhouse-server-$1/install/doinst.sh

mkdir -p /var/log/clickhouse-server
chown clickhouse.clickhouse -R /var/log/clickhouse-server
chown clickhouse.clickhouse -R /var/lib/clickhouse

clickhouse-client-$1/install/doinst.sh
clickhouse-server-$1/install/doinst.sh

mkdir /etc/clickhouse-server/config.d/
chown -R clickhouse.clickhouse /etc/clickhouse-server/config.d/

cd /root/
echo "<yandex>" >> /etc/clickhouse-server/metrika.xml
echo "<clickhouse_remote_servers>" >> /etc/clickhouse-server/metrika.xml
echo "    <quickstart_clickhouse_cluster>" >> /etc/clickhouse-server/metrika.xml
echo "        <shard>" >> /etc/clickhouse-server/metrika.xml
echo "             <internal_replication>true</internal_replication>" >> /etc/clickhouse-server/metrika.xml
echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
echo "                <host>ClickHouseNode1</host>" >> /etc/clickhouse-server/metrika.xml
echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
echo "                <host>ClickHouseNode2</host>" >> /etc/clickhouse-server/metrika.xml
echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
echo "        </shard>" >> /etc/clickhouse-server/metrika.xml

if [ $2 -ge 4 ]
then
    echo "        <shard>" >> /etc/clickhouse-server/metrika.xml
    echo "             <internal_replication>true</internal_replication>" >> /etc/clickhouse-server/metrika.xml
    echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
    echo "                <host>ClickHouseNode3</host>" >> /etc/clickhouse-server/metrika.xml
    echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
    echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
    echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
    echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
    echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
    echo "                <host>ClickHouseNode4</host>" >> /etc/clickhouse-server/metrika.xml
    echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
    echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
    echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
    echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
    echo "        </shard>" >> /etc/clickhouse-server/metrika.xml
fi

if [ $2 -ge 6 ]
then
    echo "        <shard>" >> /etc/clickhouse-server/metrika.xml
    echo "             <internal_replication>true</internal_replication>" >> /etc/clickhouse-server/metrika.xml
    echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
    echo "                <host>ClickHouseNode5</host>" >> /etc/clickhouse-server/metrika.xml
    echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
    echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
    echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
    echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
    echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
    echo "                <host>ClickHouseNode6</host>" >> /etc/clickhouse-server/metrika.xml
    echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
    echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
    echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
    echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
    echo "        </shard>" >> /etc/clickhouse-server/metrika.xml
fi

if [ $2 -ge 8 ]
then
    echo "        <shard>" >> /etc/clickhouse-server/metrika.xml
    echo "             <internal_replication>true</internal_replication>" >> /etc/clickhouse-server/metrika.xml
    echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
    echo "                <host>ClickHouseNode7</host>" >> /etc/clickhouse-server/metrika.xml
    echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
    echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
    echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
    echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
    echo "             <replica>" >> /etc/clickhouse-server/metrika.xml
    echo "                <host>ClickHouseNode8</host>" >> /etc/clickhouse-server/metrika.xml
    echo "                <port>9000</port>" >> /etc/clickhouse-server/metrika.xml
    echo "                <user>default</user>" >> /etc/clickhouse-server/metrika.xml
    echo "                <password>${11}</password>" >> /etc/clickhouse-server/metrika.xml
    echo "             </replica>" >> /etc/clickhouse-server/metrika.xml
    echo "        </shard>" >> /etc/clickhouse-server/metrika.xml
fi

echo "    </quickstart_clickhouse_cluster>" >> /etc/clickhouse-server/metrika.xml
echo "</clickhouse_remote_servers>" >> /etc/clickhouse-server/metrika.xml
echo "<zookeeper-servers>" >> /etc/clickhouse-server/metrika.xml
echo "        <node index=\"1\">" >> /etc/clickhouse-server/metrika.xml
echo "            <host>$8</host>" >> /etc/clickhouse-server/metrika.xml
echo "            <port>2181</port>" >> /etc/clickhouse-server/metrika.xml
echo "        </node>" >> /etc/clickhouse-server/metrika.xml
echo "        <node index=\"2\">" >> /etc/clickhouse-server/metrika.xml
echo "            <host>$9</host>" >> /etc/clickhouse-server/metrika.xml
echo "            <port>2181</port>" >> /etc/clickhouse-server/metrika.xml
echo "        </node>" >> /etc/clickhouse-server/metrika.xml
echo "        <node index=\"3\">" >> /etc/clickhouse-server/metrika.xml
echo "            <host>${10}</host>" >> /etc/clickhouse-server/metrika.xml
echo "            <port>2181</port>" >> /etc/clickhouse-server/metrika.xml
echo "        </node>" >> /etc/clickhouse-server/metrika.xml
echo "</zookeeper-servers>" >> /etc/clickhouse-server/metrika.xml
echo "<networks>" >> /etc/clickhouse-server/metrika.xml
echo "   <ip>::/0</ip>" >> /etc/clickhouse-server/metrika.xml
echo "</networks>" >> /etc/clickhouse-server/metrika.xml
echo "<clickhouse_compression>" >> /etc/clickhouse-server/metrika.xml
echo "<case>" >> /etc/clickhouse-server/metrika.xml
echo "  <min_part_size>10000000000</min_part_size>" >> /etc/clickhouse-server/metrika.xml             
echo "  <min_part_size_ratio>0.01</min_part_size_ratio>" >> /etc/clickhouse-server/metrika.xml
echo "  <method>lz4</method>" >> /etc/clickhouse-server/metrika.xml
echo "</case>" >> /etc/clickhouse-server/metrika.xml
echo "</clickhouse_compression>" >> /etc/clickhouse-server/metrika.xml
echo "</yandex>" >> /etc/clickhouse-server/metrika.xml

flag=600
while((flag > 0))
do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard01-replica01 --region $4` > instancelist-1
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-1`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-1 result-1
        node1=`sed -n '1p' result-1`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode1</host>|<host>${node1}</host>|g"
        break
    fi
    echo $flag
    let flag--
    sleep 1
done

flag=600
while((flag > 0))
do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard01-replica02 --region $4` > instancelist-2
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-2`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-2 result-2
        node2=`sed -n '1p' result-2`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode2</host>|<host>${node2}</host>|g"
        break
    fi
    echo $flag
    let flag--
    sleep 1
done

if (( $2 >= 4))
then
    flag=600
    while((flag > 0))
    do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard02-replica01 --region $4` > instancelist-3
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-3`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-3 result-3
        node3=`sed -n '1p' result-3`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode3</host>|<host>${node3}</host>|g"
        break
    fi
    let flag--
    sleep 1
    done

    flag=600
    while((flag > 0))
    do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard02-replica02 --region $4` > instancelist-4
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-4`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-4 result-4
        node4=`sed -n '1p' result-4`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode4</host>|<host>${node4}</host>|g"
        break
    fi
    let flag--
    sleep 1
    done
fi

if (( $2 >= 6))
then
    flag=600
    while((flag > 0))
    do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard03-replica01 --region $4` > instancelist-5
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-5`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-5 result-5
        node5=`sed -n '1p' result-5`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode5</host>|<host>${node5}</host>|g"
        break
    fi
    let flag--
    sleep 1
    done

    flag=600
    while((flag > 0))
    do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard03-replica02 --region $4` > instancelist-6
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-6`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-6 result-6
        node6=`sed -n '1p' result-6`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode6</host>|<host>${node6}</host>|g"
        break
    fi
    let flag--
    sleep 1
    done
fi

if (( $2 >= 8))
then
    flag=600
    while((flag > 0))
    do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard04-replica01 --region $4` > instancelist-7
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-7`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-7 result-7
        node7=`sed -n '1p' result-7`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode7</host>|<host>${node7}</host>|g"
        break
    fi
    let flag--
    sleep 1
    done

    flag=600
    while((flag > 0))
    do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard04-replica02 --region $4` > instancelist-8
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-8`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-8 result-8
        node8=`sed -n '1p' result-8`
        find /etc/clickhouse-server/ -name 'metrika.xml' | xargs perl -pi -e  "s|<host>ClickHouseNode8</host>|<host>${node8}</host>|g"
        break
    fi
    let flag--
    sleep 1
    done
fi

if [ $1 = 21.4.5.46 ]; then
    echo "Update the config.xml of $1"
    sed -i '508, 617d' /etc/clickhouse-server/config.xml
elif [ $1 = 21.5.5.12 ]; then
    echo "Update the config.xml of $1"
    sed -i '520, 630d' /etc/clickhouse-server/config.xml
elif [ $1 = 21.8.7.22 ]; then
    echo "Update the config.xml of $1"
    sed -i '590, 695d' /etc/clickhouse-server/config.xml
fi

find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  's|<!--</remote_url_allow_hosts>-->|<!--</remote_url_allow_hosts>--><include_from>/etc/clickhouse-server/metrika.xml</include_from><remote_servers incl="clickhouse_remote_servers" /><zookeeper incl="zookeeper-servers" optional="true" />|g'

find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|<level>trace</level>|<level>information</level>|g"
find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|<log>/var/log/clickhouse-server/clickhouse-server.log</log>|<log>/home/clickhouse/data/log/clickhouse-server.log</log>|g"
find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|<errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>|<errorlog>/home/clickhouse/data/log/clickhouse-server.err.log</errorlog>|g"
find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|<path>/var/lib/clickhouse/</path>|<path>/home/clickhouse/data/clickhouse-data/</path>|g"
find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|/var/lib/clickhouse/|/home/clickhouse/data/|g"
find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|<!-- <timezone>Europe/Moscow</timezone> -->|<timezone>$7</timezone>|g"
find /etc/clickhouse-server/ -name 'config.xml' | xargs perl -pi -e  "s|<!-- <listen_host>0.0.0.0</listen_host> -->|<listen_host>0.0.0.0</listen_host>|g"

find /etc/clickhouse-server/ -name 'users.xml' | xargs perl -pi -e  "s|<password></password>|<password>${11}</password>|g"
#password_sha256_hex=`echo -n '${11}' | sha256sum | tr -d '-' | sed 's/ //g'`
#find /etc/clickhouse-server/ -name 'users.xml' | xargs perl -pi -e  "s|<password></password>|<password_sha256_hex>${password_sha256_hex}</password_sha256_hex>|g"
sudo sed -i "9a <max_threads>${12}</max_threads>" /etc/clickhouse-server/users.xml
sudo sed -i "9a <max_insert_threads>${13}</max_insert_threads>" /etc/clickhouse-server/users.xml
sudo sed -i "9a <distributed_product_mode>${14}</distributed_product_mode>" /etc/clickhouse-server/users.xml
sudo sed -i "s|<max_memory_usage>10000000000</max_memory_usage>|<max_memory_usage>${15}</max_memory_usage>|" /etc/clickhouse-server/users.xml
sudo sed -i "s|<load_balancing>random</load_balancing>|<load_balancing>${16}</load_balancing>|" /etc/clickhouse-server/users.xml
sudo sed -i 's|<!-- <access_management>1</access_management> -->|<access_management>1</access_management>|' /etc/clickhouse-server/users.xml


echo "<yandex>" >> /etc/clickhouse-server/config.d/storage.xml
echo "  <storage_configuration>" >> /etc/clickhouse-server/config.d/storage.xml
echo "    <policies>" >> /etc/clickhouse-server/config.d/storage.xml
echo "      <tiered>" >> /etc/clickhouse-server/config.d/storage.xml
echo "        <volumes>" >> /etc/clickhouse-server/config.d/storage.xml
echo "          <main>" >> /etc/clickhouse-server/config.d/storage.xml
echo "              <disk>default</disk>" >> /etc/clickhouse-server/config.d/storage.xml
echo "              <max_data_part_size_bytes>${17}</max_data_part_size_bytes>" >> /etc/clickhouse-server/config.d/storage.xml
echo "              <perform_ttl_move_on_insert>false</perform_ttl_move_on_insert>" >> /etc/clickhouse-server/config.d/storage.xml
echo "          </main>" >> /etc/clickhouse-server/config.d/storage.xml
echo "        </volumes>" >> /etc/clickhouse-server/config.d/storage.xml
echo "      </tiered>" >> /etc/clickhouse-server/config.d/storage.xml
echo "    </policies>" >> /etc/clickhouse-server/config.d/storage.xml
echo "  </storage_configuration>" >> /etc/clickhouse-server/config.d/storage.xml
echo "</yandex>" >> /etc/clickhouse-server/config.d/storage.xml

#echo "<yandex>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "  <storage_configuration>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "    <disks>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "      <s3>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <type>s3</type>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <endpoint>$5</endpoint>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <use_environment_credentials>true</use_environment_credentials>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <max_connections>10000</max_connections>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "      </s3>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "    </disks>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "    <policies>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "      <tiered>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <volumes>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "          <main>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "              <disk>default</disk>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "              <max_data_part_size_bytes>${17}</max_data_part_size_bytes>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "              <perform_ttl_move_on_insert>false</perform_ttl_move_on_insert>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "          </main>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "          <external>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "              <disk>s3</disk>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "          </external>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        </volumes>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <move_factor>${6}</move_factor>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "      </tiered>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "      <s3only>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        <volumes>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "          <s3>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "            <disk>s3</disk>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "          </s3>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "        </volumes>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "      </s3only>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "    </policies>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "  </storage_configuration>" >> /etc/clickhouse-server/config.d/storage.xml
#echo "</yandex>" >> /etc/clickhouse-server/config.d/storage.xml

echo "<yandex>" >> /etc/clickhouse-server/config.d/macros.xml
echo "    <macros>" >> /etc/clickhouse-server/config.d/macros.xml
echo "        <replica>cluster01-${18}-${19}</replica>" >> /etc/clickhouse-server/config.d/macros.xml
echo "        <shard>${18}</shard>" >> /etc/clickhouse-server/config.d/macros.xml
echo "        <layer>01</layer>" >> /etc/clickhouse-server/config.d/macros.xml
echo "    </macros>" >> /etc/clickhouse-server/config.d/macros.xml
echo "</yandex>" >> /etc/clickhouse-server/config.d/macros.xml

chown -R clickhouse.clickhouse /home/clickhouse/
chown -R clickhouse.clickhouse /etc/clickhouse-server/

echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 131072" >> /etc/security/limits.conf
echo "* hard nproc 131072" >> /etc/security/limits.conf

systemctl stop clickhouse-server
systemctl start clickhouse-server
systemctl status clickhouse-server

# Restart ClickHouse
sleep 5
systemctl stop clickhouse-server
systemctl start clickhouse-server
systemctl status clickhouse-server
sleep 1

echo "[Install]" >> /lib/systemd/system/rc-local.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/rc-local.service
echo "Alias=rc-local.service" >> /lib/systemd/system/rc-local.service
ln -s /lib/systemd/system/rc-local.service /etc/systemd/system/

# No default rc.local on Ubuntu 18+
cat << EOF > /etc/rc.local
#!/bin/bash -e
systemctl start clickhouse-server
EOF
chmod +x /etc/rc.local
