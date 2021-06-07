####################


# ${ClickHouseVersion}   1
# ${DBPassword}   2
# ${RootStackName}   3
# ${AWS::Region}   4 
# ${DemoDataSize}   5
# ${PrometheusVersion}   6
# ${GrafanaVersion}   7  
# ${CHproxyCacheSize}   8
# ${CHproxyCacheExpire}   9 
# ${CHproxyReplicaUserPassword}   10
# ${CHproxyDistributedUserPassword}  11
# ${ClickHouseNodeCount} 12


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


sudo yum install yum-utils
sudo rpm --import https://repo.clickhouse.tech/CLICKHOUSE-KEY.GPG
sudo yum-config-manager --add-repo https://repo.clickhouse.tech/rpm/stable/x86_64

sudo yum install clickhouse-client-$1 -y

sleep 1



# install CHproxy 
sudo mkdir -pv /home/ec2-user/tools/install/
cd /home/ec2-user/tools/install/
wget -c https://github.com/Vertamedia/chproxy/releases/download/v1.14.0/chproxy-linux-amd64-v1.14.0.tar.gz
mkdir -pv /home/ec2-user/tools/chproxy
mkdir -pv /home/ec2-user/tools/chproxy/data

tar xf chproxy-linux-amd64-v1.14.0.tar.gz -C /home/ec2-user/tools/chproxy
sleep 1
sudo chmod -R 777 /home/ec2-user/tools/chproxy

cat << EOF > /home/ec2-user/tools/chproxy/config.yml

server:
  http:
      listen_addr: ":9099"
      allowed_networks: 
      read_timeout: 5m
      write_timeout: 20m
      idle_timeout: 30m

  metrics:
      allowed_networks: 

# user for chproxy
users:
  - name: "distributed"
    password: "$11"
    to_cluster: "distributed"
    to_user: "default"

  - name: "replica"
    password: "$10"
    to_cluster: "replica-write"
    to_user: "default"


clusters:
  - name: "replica-write"
    replicas:
      - name: "replica1"
        nodes: [Variable1]
      - name: "replica2"
        nodes: [Variable2]
    users:
      - name: "default"
        password: "$2"

  - name: "distributed"
    nodes: [Variable3]
    users:
      - name: "default"
        password: "$2"


caches:
  - name: "shortterm"
    dir: "/data/chproxy/cache/shortterm"
    max_size: $8
    expire: $9

hack_me_please: true

EOF

cd /home/ec2-user/

flag=600
while((flag > 0))
do
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard01-replica01 --region $4` > instancelist-1
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-1`
    echo `aws ec2 describe-tags --filters Name=key,Values=$3-clickhouse-shard01-replica02 --region $4` > instancelist-2
    count=`awk -v RS="@#$j" '{print gsub(/instance/,"&")}' instancelist-2`
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

if (( $12 >= 4))
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

if (( $12 >= 6))
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

if (( $12 >= 8))
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

find /home/ec2-user/tools/chproxy/ -name 'config.yml' | xargs perl -pi -e  "s|Variable1|"$node1:8123", "$node3:8123", "$node5:8123", "$node7:8123"|g"
find /home/ec2-user/tools/chproxy/ -name 'config.yml' | xargs perl -pi -e  "s|Variable2|"$node2:8123", "$node4:8123", "$node6:8123", "$node8:8123"|g"
find /home/ec2-user/tools/chproxy/ -name 'config.yml' | xargs perl -pi -e  "s|Variable3|"$node1:8123", "$node3:8123", "$node5:8123", "$node7:8123"|g"

#   it's OK if 2node cluster //   nodes: ["1.1.1.1:8123", "2.2.2.2:8123", "", "", "", ""]


nohup ./chproxy -config=/home/ec2-user/tools/chproxy/config.yml >nohup.log 2>&1 &
sleep 1

echo 'select * from system.clusters' | curl 'http://localhost:9099/?user=distributed&password=$11' -d @-



# install prometheus 

cd /home/ec2-user/tools/install/

sudo useradd --no-create-home prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus


wget https://github.com/prometheus/prometheus/releases/download/v$6/prometheus-$6.linux-amd64.tar.gz
sudo tar xvfz prometheus-$6.linux-amd64.tar.gz

sudo cp prometheus-$6.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-$6.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-$6.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-$6.linux-amd64/console_libraries /etc/prometheus

sudo cp prometheus-$6.linux-amd64/promtool /usr/local/bin/
rm -rf prometheus-$6.linux-amd64.tar.gz prometheus-$6.linux-amd64



sudo cat << EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  external_labels:
      monitor: 'codelab-monitor'
rule_files:
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'chproxy'
    static_configs:
      - targets: ['localhost:9099']
  - job_name: 'CH_1_exporter'
    static_configs:
      - targets: ['$node1:9116']
  - job_name: 'CH_1_node_exporter'
    static_configs:
      - targets: ['$node1:9100']
  - job_name: 'CH_2_exporter'
    static_configs:
      - targets: ['$node2:9116']
  - job_name: 'CH_2_node_exporter'
    static_configs:
      - targets: ['$node2:9100']
  - job_name: 'CH_3_exporter'
    static_configs:
      - targets: ['$node3:9116']
  - job_name: 'CH_3_node_exporter'
    static_configs:
      - targets: ['$node3:9100']
  - job_name: 'CH_4_exporter'
    static_configs:
      - targets: ['$node4:9116']
  - job_name: 'CH_4_node_exporter'
    static_configs:
      - targets: ['$node4:9100']
  - job_name: 'CH_5_exporter'
    static_configs:
      - targets: ['$node5:9116']
  - job_name: 'CH_5_node_exporter'
    static_configs:
      - targets: ['$node5:9100']
  - job_name: 'CH_6_exporter'
    static_configs:
      - targets: ['$node6:9116']
  - job_name: 'CH_6_node_exporter'
    static_configs:
      - targets: ['$node6:9100']
  - job_name: 'CH_7_exporter'
    static_configs:
      - targets: ['$node7:9116']
  - job_name: 'CH_7_node_exporter'
    static_configs:
      - targets: ['$node7:9100']
  - job_name: 'CH_8_exporter'
    static_configs:
      - targets: ['$node8:9116']
  - job_name: 'CH_8_node_exporter'
    static_configs:
      - targets: ['$node8:9100']

EOF
sleep 1


sudo cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
      
EOF
sleep 1



sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus
sleep 1

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus


# install grafana 
cd /home/ec2-user/tools/install/
sudo mkdir /home/ec2-user/tools/grafana

wget https://dl.grafana.com/oss/release/grafana-$7.x86_64.rpm
sudo yum install grafana-$7.x86_64.rpm -y
sleep 1

sudo grafana-cli plugins install vertamedia-clickhouse-datasource
sudo systemctl stop grafana-server
sudo systemctl start grafana-server
sleep 1
sudo systemctl status grafana-server


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
elif [ $5 = no ]; then
    ontimefrom=0
    ontimeto=0
else
    echo "Parameters not found or inaccessible."
fi




sudo mkdir -pv /home/ec2-user/tools/install/demodata
cd /home/ec2-user/tools/install/demodata

wget https://awspsa-quickstart.s3.amazonaws.com/clickhouse/scripts/downloaddata.sh
sleep 1

sudo sed -i "s|ontimefrom|$ontimefrom|" /home/ec2-user/tools/install/demodata/downloaddata.sh
sudo sed -i "s|ontimeto|$ontimeto|" /home/ec2-user/tools/install/demodata/downloaddata.sh

sudo chmod +x /home/ec2-user/tools/install/demodata/downloaddata.sh 
sudo ./downloaddata.sh 
sleep 1

sudo ls -1 *.zip | xargs -I{} -P $(nproc) bash -c "echo {}; unzip -cq {} '*.csv' | sed 's/\.00//g' | clickhouse-client --host $node1 --password $2 --input_format_with_names_use_header=0 --query='INSERT INTO ontime FORMAT CSVWithNames'"
sleep 1
#echo 'INSERT INTO ontime FORMAT CSVWithNames' | curl 'http://localhost:9099/?user=$replica-write&password=$replicapassword' -d @-

echo " Done with installations"
