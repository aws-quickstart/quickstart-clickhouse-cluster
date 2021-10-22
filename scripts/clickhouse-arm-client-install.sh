####################


# ${ClickHouseVersion}   1
# ${DBPassword}   2
# ${RootStackName}   3
# ${AWS::Region}   4 
# ${DemoDataSize}   5
# ${ClickHouseNodeCount} 6
# ${GrafanaVersion} 7


# Install the basics
apt install unzip

flag=600
while((flag > 0))
do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard01-replica01 --region $4` > instancelist-1
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-1`
    if (( $count >= 1 ))
    then
        python3 find-clickhouse-node.py instancelist-1 result-1
        node1=`sed -n '1p' result-1`
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
        break
    fi
    echo $flag
    let flag--
    sleep 1
done

if (( $6 >= 4))
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
        break
    fi
    let flag--
    sleep 1
    done
fi

if (( $6 >= 6))
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
        break
    fi
    let flag--
    sleep 1
    done
fi

if (( $6 >= 8))
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
        break
    fi
    let flag--
    sleep 1
    done
fi

# install grafana 
mkdir -p /root/tools/install/
cd /root/tools/install/
mkdir /root/tools/install/grafana
sudo apt-get install -y adduser libfontconfig1
wget https://dl.grafana.com/oss/release/grafana_${7}_arm64.deb
sudo dpkg -i grafana_${7}_arm64.deb
sleep 1
grafana-cli plugins install vertamedia-clickhouse-datasource

systemctl stop grafana-server
systemctl start grafana-server
sleep 1
systemctl status grafana-server

# Change the default password
grafana-cli admin reset-admin-password ${2}

systemctl stop grafana-server
systemctl start grafana-server

echo "systemctl start grafana-server" > /root/grafana-start.sh
chmod +x /root/grafana-start.sh

echo "[Install]" >> /lib/systemd/system/rc-local.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/rc-local.service
echo "Alias=rc-local.service" >> /lib/systemd/system/rc-local.service
ln -s /lib/systemd/system/rc-local.service /etc/systemd/system/

# No default rc.local on Ubuntu 18+
cat << EOF > /etc/rc.local
#!/bin/bash -e
/root/grafana-start.sh
EOF
chmod +x /etc/rc.local

# demo data

if [ $5 = small ]; then
    ontimefrom=1988
    ontimeto=1989
elif [ $5 = medium ]; then
    ontimefrom=1988
    ontimeto=1995
elif [ $5 = large ]; then
    ontimefrom=1988
    ontimeto=2010
elif [ $5 = none ]; then
    ontimefrom=0
    ontimeto=0
else
    echo "Parameters not found or inaccessible."
fi

mkdir -pv /root/tools/install/demodata
cd /root/tools/install/demodata
mv /root/downloaddata.sh .

sed -i "s|ontimefrom|$ontimefrom|" /root/tools/install/demodata/downloaddata.sh
sed -i "s|ontimeto|$ontimeto|" /root/tools/install/demodata/downloaddata.sh

chmod +x /root/tools/install/demodata/downloaddata.sh 
./downloaddata.sh 
sleep 1
# Retry to download the missing file
./downloaddata.sh

ls -1 *.zip | xargs -I{} -P $(nproc) bash -c "echo {}; unzip -cq {} '*.csv' | sed 's/\.00//g' | clickhouse-client --host ${node1} --password $2 --input_format_with_names_use_header=0 --query='INSERT INTO ontime FORMAT CSVWithNames'"
sleep 1
#echo 'INSERT INTO ontime FORMAT CSVWithNames' | curl 'http://localhost:9099/?user=$replica-write&password=$replicapassword' -d @-

# Clean
rm -rf /root/find-clickhouse-node.py
rm -rf /root/instancelist-1
rm -rf /root/result-1
rm -rf /root/instancelist-2
rm -rf /root/result-2
rm -rf /root/instancelist-3
rm -rf /root/result-3
rm -rf /root/instancelist-4
rm -rf /root/result-4
rm -rf /root/instancelist-5
rm -rf /root/result-5
rm -rf /root/instancelist-6
rm -rf /root/result-6
rm -rf /root/instancelist-7
rm -rf /root/result-7
rm -rf /root/instancelist-8
rm -rf /root/result-8
rm -rf /root/tools/install/grafana_${7}_arm64.deb
rm -rf /root/tools/install/demodata/downloaddata.sh

echo " Done with installations"
