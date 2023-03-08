#!/bin/bash

# ${ZookeeperVersion} 1

#wget -P ./ -T 60 https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/8/jdk/x64/linux/OpenJDK8U-jdk_x64_linux_hotspot_8u292b10.tar.gz
wget -P ./ -T 60 https://repo.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
tar -xvf /home/ec2-user/jdk-8u202-linux-x64.tar.gz
sudo ln -s /home/ec2-user/jdk1.8.0_202/bin/java /usr/local/bin/java
sudo ln -s /home/ec2-user/jdk1.8.0_202/bin/java /usr/bin/java
if [ ! -d "/home/ec2-user/jdk1.8.0_202" ]; then
  rm -rf /usr/local/bin/java
  rm -rf /usr/bin/java
  wget -P ./ -T 60 https://download.java.net/openjdk/jdk8u41/ri/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz
  tar -xvf /home/ec2-user/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz
  sudo ln -s /home/ec2-user/java-se-8u41-ri/bin/java /usr/local/bin/java
  sudo ln -s /home/ec2-user/java-se-8u41-ri/bin/java /usr/bin/java
fi

# Avoid deployment issues caused by the version of Zookeeper's frequent changes.
wget -P ./ -T 60 http://archive.apache.org/dist/zookeeper/zookeeper-${1}/apache-zookeeper-${1}-bin.tar.gz
tar -xvf /home/ec2-user/apache-zookeeper-${1}-bin.tar.gz -C /usr/local/
if [ ! -d "/usr/local/apache-zookeeper-${1}-bin" ]; then
  wget -P ./  -T 60 http://archive.apache.org/dist/zookeeper/zookeeper-${1}/apache-zookeeper-${1}-bin.tar.gz
  tar -xvf /home/ec2-user/apache-zookeeper-${1}-bin.tar.gz -C /usr/local/
fi

echo "export JAVA_HOME=/usr/local/java" >> ~/.bashrc
echo "export JRE_HOME=${JAVA_HOME}/jre" >> ~/.bashrc
echo "export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib" >> ~/.bashrc
echo "export PATH=${JAVA_HOME}/bin:$PATH" >> ~/.bashrc
echo "export ZOOKEEPER_HOME=/usr/local/apache-zookeeper-${1}-bin" >> ~/.bashrc
echo "export PATH=$PATH:$ZOOKEEPER_HOME/bin" >> ~/.bashrc
echo "source /etc/profile" >> ~/.bashrc

echo "tickTime=2000" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "initLimit=30000" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "syncLimit=10" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "maxClientCnxns=2000" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "maxSessionTimeout=60000000" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "dataDir=/data/zookeeper/data" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "dataLogDir=/data/zookeeper/logs" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "autopurge.snapRetainCount=10" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "autopurge.purgeInterval=1" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "preAllocSize=131072" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "snapCount=3000000" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg
echo "clientPort=2181" >> /usr/local/apache-zookeeper-${1}-bin/conf/zoo.cfg

echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 131072" >> /etc/security/limits.conf
echo "* hard nproc 131072" >> /etc/security/limits.conf