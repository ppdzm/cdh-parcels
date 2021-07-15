```shell script
HADOOP_USER_NAME=flink
HADOOP_CONF_DIR=/etc/hadoop/conf
HADOOP_HOME=/opt/cloudera/parcels/CDH
HADOOP_CLASSPATH=/opt/cloudera/parcels/CDH/jars/*
```

```shell script

```

curl -u admin:wwj-dc-cluster -X POST http://localhost:7180/api/v16/clusters/WWJ-DC-Cluster/parcels/products/FLINK/versions/1.13.1-BIN-SCALA_2.11/commands/deactivate