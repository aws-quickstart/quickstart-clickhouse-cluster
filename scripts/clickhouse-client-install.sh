####################


# ${ClickHouseVersion}   1
# ${DBPassword}   2
# ${RootStackName}   3
# ${AWS::Region}   4 
# ${DemoDataSize}   5
# ${ClickHouseNodeCount} 6
# ${GrafanaVersion} 7


# Install the basics
yum -y update -y
yum -y install jq -y
yum install python3.7 -y

pip3 install awscli --upgrade --user
echo "export PATH=~/.local/bin:$PATH" >> .bash_profile
sleep 1
pip3 install boto3 --user
pip3 install awscli --upgrade --user
sleep 1


yum install yum-utils
rpm --import https://repo.clickhouse.tech/CLICKHOUSE-KEY.GPG
yum-config-manager --add-repo https://repo.clickhouse.tech/rpm/stable/x86_64
yum install clickhouse-client-$1 -y
sleep 1
if [ ! -d "/etc/clickhouse-client" ]; then
    echo "Try to download from https://mirrors.tuna.tsinghua.edu.cn/clickhouse/"
    rpm --import https://mirrors.tuna.tsinghua.edu.cn/clickhouse/CLICKHOUSE-KEY.GPG
    yum-config-manager --add-repo https://mirrors.tuna.tsinghua.edu.cn/clickhouse/rpm/stable/x86_64
    yum install clickhouse-client-$1 -y
fi

cd /home/ec2-user/

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
mkdir -p /home/ec2-user/tools/install/
cd /home/ec2-user/tools/install/
mkdir /home/ec2-user/tools/install/grafana
wget https://dl.grafana.com/oss/release/grafana-$7.x86_64.rpm
yum install grafana-$7.x86_64.rpm -y
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

echo "systemctl start grafana-server" > /home/ec2-user/grafana-start.sh
chmod +x /home/ec2-user/grafana-start.sh
echo "/home/ec2-user/grafana-start.sh" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

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

mkdir -pv /home/ec2-user/tools/install/demodata
cd /home/ec2-user/tools/install/demodata
mv /home/ec2-user/downloaddata.sh .

sed -i "s|ontimefrom|$ontimefrom|" /home/ec2-user/tools/install/demodata/downloaddata.sh
sed -i "s|ontimeto|$ontimeto|" /home/ec2-user/tools/install/demodata/downloaddata.sh

chmod +x /home/ec2-user/tools/install/demodata/downloaddata.sh 
./downloaddata.sh 
sleep 1
# Retry to download the missing file
./downloaddata.sh

ls -1 *.zip | xargs -I{} -P $(nproc) bash -c "echo {}; unzip -cq {} '*.csv' | sed 's/\.00//g' | clickhouse-client --host ${node1} --password $2 --input_format_with_names_use_header=0 --query='INSERT INTO ontime FORMAT CSVWithNames'"
sleep 1
#echo 'INSERT INTO ontime FORMAT CSVWithNames' | curl 'http://localhost:9099/?user=$replica-write&password=$replicapassword' -d @-

# Clean
rm -rf /home/ec2-user/find-clickhouse-node.py
rm -rf /home/ec2-user/instancelist-1
rm -rf /home/ec2-user/result-1
rm -rf /home/ec2-user/instancelist-2
rm -rf /home/ec2-user/result-2
rm -rf /home/ec2-user/instancelist-3
rm -rf /home/ec2-user/result-3
rm -rf /home/ec2-user/instancelist-4
rm -rf /home/ec2-user/result-4
rm -rf /home/ec2-user/instancelist-5
rm -rf /home/ec2-user/result-5
rm -rf /home/ec2-user/instancelist-6
rm -rf /home/ec2-user/result-6
rm -rf /home/ec2-user/instancelist-7
rm -rf /home/ec2-user/result-7
rm -rf /home/ec2-user/instancelist-8
rm -rf /home/ec2-user/result-8
rm -rf /home/ec2-user/tools/install/grafana-$7.x86_64.rpm
rm -rf /home/ec2-user/tools/install/demodata/downloaddata.sh

echo " Done with installations"
