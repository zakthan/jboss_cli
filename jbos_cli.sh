#!/bin/bash
##Author:      Zakopoulos Athanasios
##Description: Monitor jboss using cli. Using default host/port. If it is differnet just change JBOSS_HOST/PORT parameters


##script envs
SCRIPT_HOME="/root/scripts/middleware/zabbix_metrics/jboss_cli"
##script envs

##jboss envs
JBOSS_HOST=localhost
PORT=9990
DATASOURCES=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "ls /subsystem=datasources/data-source,exit")
DATASOURCE_METRICS="ActiveCount AvailableCount CreatedCount DestroyedCount IdleCount InUseCount MaxUsedCount MaxWaitCount TimedOut"
DEPLOYMENTS=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "ls /deployment,exit")
##jboss envs

##zabbix envs
ZABBIX=pvzabbix01.cosmote.gr
HOST=$(hostname)
##zabbix envs

##wildfly status
##cat /dev/null > server-state.txt
STATUS=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT ":read-attribute(name=server-state),exit")
STATUS_KEY_RESULT=$(echo $STATUS|awk '{print $7}'|sed 's/"//g')
#!/bin/bash
##Author:      Zakopoulos Athanasios
##Description: Monitor jboss using cli. Using default host/port. If it is differnet just change JBOSS_HOST/PORT parameters


##script envs
SCRIPT_HOME="/root/scripts/middleware/zabbix_metrics/jboss_cli"
##script envs

##jboss envs
JBOSS_HOST=localhost
PORT=9990
DATASOURCES=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "ls /subsystem=datasources/data-source,exit")
DATASOURCE_METRICS="ActiveCount AvailableCount CreatedCount DestroyedCount IdleCount InUseCount MaxUsedCount MaxWaitCount TimedOut"
DEPLOYMENTS=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "ls /deployment,exit")
##jboss envs

##zabbix envs
ZABBIX=pvzabbix01.cosmote.gr
HOST=$(hostname)
##zabbix envs

##wildfly status
##cat /dev/null > server-state.txt
STATUS=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT ":read-attribute(name=server-state),exit")
STATUS_KEY_RESULT=$(echo $STATUS|awk '{print $7}'|sed 's/"//g')
/usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k jboss_status -o "$STATUS_KEY_RESULT"
echo $(date) $STATUS_KEY_RESULT >> $SCRIPT_HOME/logs/server-state.txt

##wildfly heap memory usage
HEAP=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "/core-service=platform-mbean/type=memory:read-attribute(name=heap-memory-usage),exit")
HEAP_MEM_USAGE=$(echo $HEAP |awk '{print $13}'|sed "s/L,//g")
/usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k jboss_heap_memory_usage -o "$HEAP_MEM_USAGE"

##wildfly old heap gc count
CG_COUNT=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "/core-service=platform-mbean/type=garbage-collector/name=G1_Old_Generation:read-attribute(name=collection-count),exit")
OLD_GC_COUNT=$(echo $CG_COUNT |awk '{print $7}'|sed "s/L//g")
/usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k jboss_old_gc_count -o $OLD_GC_COUNT

##wildfly old heap gc time
CG_TIME=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "/core-service=platform-mbean/type=garbage-collector/name=G1_Old_Generation:read-attribute(name=collection-time),exit")
OLD_GC_TIME=$(echo $CG_TIME |awk '{print $7}'|sed "s/L//g")
/usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k jboss_old_gc_time -o $OLD_GC_TIME

##wildfly threads
TH=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "/core-service=platform-mbean/type=threading:read-attribute(name=thread-count),exit")
THREADS=$(echo $TH |awk '{print $7}'|sed "s/L//g")
/usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k jboss_threads -o $THREADS

## wildfly datasources metrics
for DATASOURCE in $DATASOURCES
do
cat /dev/null > $DATASOURCE.txt
/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c --controller=$JBOSS_HOST:$PORT "ls /subsystem=datasources/data-source=$DATASOURCE/statistics=pool:read-attribute,exit"|tr ' ' '\n' > $DATASOURCE.txt
        for DATASOURCE_METRIC_NAME in $DATASOURCE_METRICS
        do
                DATASOURCE_METRIC_VALUE=$(grep $DATASOURCE_METRIC_NAME  $DATASOURCE.txt|sed "s/=/ /g"|awk '{print $2}')
                /usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k "$DATASOURCE"_"$DATASOURCE_METRIC_NAME" -o $DATASOURCE_METRIC_VALUE
        done
done

##wildfly deployment metrics
COUNTER=1
for DEPLOYMENT in $DEPLOYMENTS
        do
                DEPLOYMENT_STATUS=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c "/deployment=$DEPLOYMENT:read-attribute(name=status),exit"|grep result|awk '{print $3}')
                ACTIVE_SESSIONS=$(/u01/app/liferay/liferay-dxp-digital-enterprise-7.0-sp8/wildfly-10.0.0/bin/jboss-cli.sh -c "/deployment=$DEPLOYMENT/subsystem=undertow:read-attribute(name=active-sessions),exit"|grep result|awk '{print $3}')
                STRING="$(hostname -s) $DEPLOYMENT $DEPLOYMENT_STATUS"
                echo $STRING
                /usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k "$COUNTER"_deploymnent_status -o "$STRING"
                /usr/bin/zabbix_sender  -z $ZABBIX -s $HOST -k "$COUNTER"_deploymnent_active_sessions -o "$ACTIVE_SESSIONS"
                COUNTER=$((COUNTER+1))

       done
