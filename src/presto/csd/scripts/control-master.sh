#!/bin/bash
# Time marker for both stderr and stdout
date 1>&2

PRESTO_PARCEL_PATH=/opt/cloudera/parcels/PRESTO

#init config.properties
cat $CONF_DIR/etc/config.properties > $PRESTO_PARCEL_PATH/etc/config.properties

#init node.properties
echo 'node.environment=presto_cluster' > $PRESTO_PARCEL_PATH/etc/node.properties
echo "node.id=$(hostname -s)" >> $PRESTO_PARCEL_PATH/etc/node.properties
cat $CONF_DIR/etc/node.properties.dummy >> $PRESTO_PARCEL_PATH/etc/node.properties

#init jvm.config
sed -i "s/jvm.config=//g" $CONF_DIR/etc/jvm.config
sed -i "s/;/\n/g" $CONF_DIR/etc/jvm.config
cat $CONF_DIR/etc/jvm.config > $PRESTO_PARCEL_PATH/etc/jvm.config

#init hive.properties
echo 'connector.name=hive-hadoop2' > $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
echo 'hive.parquet.fail-on-corrupted-statistics=false' >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
cat $CONF_DIR/etc/catalog/hive.properties >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
cp -f $CONF_DIR/presto.keytab $PRESTO_PARCEL_PATH/etc/
cp -f $CONF_DIR/hive-conf/hive-site.xml $PRESTO_PARCEL_PATH/etc/catalog/
cp -f $CONF_DIR/hive-conf/core-site.xml $PRESTO_PARCEL_PATH/etc/catalog/
cp -f $CONF_DIR/hive-conf/hdfs-site.xml $PRESTO_PARCEL_PATH/etc/catalog/
cp -f $CONF_DIR/etc/client_kerberos.config $PRESTO_PARCEL_PATH/etc/

#init hive_krb5_config
cp -f $CONF_DIR/etc/kerberos.config $PRESTO_PARCEL_PATH/etc/
if cat $PRESTO_PARCEL_PATH/etc/kerberos.config | grep "authentication"  | grep "true" > /dev/null
then
	realm=$(sed '/^kerberos_realm=/!d;s/.*=//' $PRESTO_PARCEL_PATH/etc/kerberos.config)
	metastore=$(sed '/^hive.metastore.host=/!d;s/.*=//' $PRESTO_PARCEL_PATH/etc/kerberos.config)

	echo 'hive.metastore.authentication.type=KERBEROS' >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo "hive.metastore.service.principal=hive/${metastore}@${realm}" >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo "hive.metastore.client.principal=presto/$(hostname)@${realm}" >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo "hive.metastore.client.keytab=$PRESTO_PARCEL_PATH/etc/presto.keytab" >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo 'hive.hdfs.authentication.type=KERBEROS' >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo 'hive.hdfs.impersonation.enabled=true' >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo "hive.hdfs.presto.principal=presto/$(hostname)@${realm}" >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo "hive.hdfs.presto.keytab=$PRESTO_PARCEL_PATH/etc/presto.keytab" >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties

fi

if cat $PRESTO_PARCEL_PATH/etc/kerberos.config | grep "client"  | grep "true" > /dev/null
then
	echo 'http-server.authentication.type=KERBEROS' >> $PRESTO_PARCEL_PATH/etc/config.properties
	echo 'http.server.authentication.krb5.service-name=presto' >> $PRESTO_PARCEL_PATH/etc/config.properties
	echo "http.server.authentication.krb5.keytab=$PRESTO_PARCEL_PATH/etc/presto.keytab" >> $PRESTO_PARCEL_PATH/etc/config.properties
	echo 'http.authentication.krb5.config=/etc/krb5.conf' >> $PRESTO_PARCEL_PATH/etc/config.properties
	cat $PRESTO_PARCEL_PATH/etc/client_kerberos.config >> $PRESTO_PARCEL_PATH/etc/config.properties
	echo 'access-control.name=file' > $PRESTO_PARCEL_PATH/etc/access-control.properties
	echo 'security.config-file=etc/rules.json' >> $PRESTO_PARCEL_PATH/etc/access-control.properties
else
	echo 'access-control.name=allow-all' > $PRESTO_PARCEL_PATH/etc/access-control.properties
fi

if cat $PRESTO_PARCEL_PATH/etc/kerberos.config | grep "hive_auth"  | grep "true" > /dev/null
then
	cp -f $CONF_DIR/etc/hive_auth.config $PRESTO_PARCEL_PATH/etc/
	echo 'security.refresh-period=15s' >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	echo 'hive.security=file' >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
	cat $PRESTO_PARCEL_PATH/etc/hive_auth.config >> $PRESTO_PARCEL_PATH/etc/catalog/hive.properties
fi

exec $PRESTO_PARCEL_PATH/bin/launcher run

exit 0
