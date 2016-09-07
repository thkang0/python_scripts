#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Usage: move-lb.sh <neutron_node>"
  echo "Example: move-lb.sh neutron01"
  exit 1
fi

#ROUTER=`neutron router-list | grep $1`
LBAAS_AGENT_NEUTRON01=`neutron agent-list | grep Loadbalancer | grep neutron01 | awk '{print $2}'`
LBAAS_AGENT_NEUTRON02=`neutron agent-list | grep Loadbalancer | grep neutron02 | awk '{print $2}'`

#update database
if [ "$1" == "neutron01" ]
  then 
    TARGET=`mysql -u root -h 192.168.2.224 -popenstack -D neutron -e "SELECT * FROM neutron.poolloadbalanceragentbindings;" | grep $LBAAS_AGENT_NEUTRON01 | awk '{print $1}'`
    if [ -z "$TARGET" ]
      then
      echo "There is no running Loadbalancer on Neutron01"
      exit 1
    fi
    for i in $TARGET
    do
      echo "Update load balancers on Neutron01 to Neutron02"
      AGENT_ID="'${LBAAS_AGENT_NEUTRON02}'"
      POOL_ID="'$i'"
      QUERY='UPDATE `neutron`.`poolloadbalanceragentbindings` SET `agent_id`='"${AGENT_ID}"' WHERE `pool_id`='"$POOL_ID"';'
      echo $QUERY | mysql -u root -h 192.168.2.224 -popenstack -D neutron 
      mysql -u root -h 192.168.2.224 -popenstack -D neutron -e "SELECT * FROM neutron.poolloadbalanceragentbindings;"
    done
elif [ "$1" == "neutron02" ] 
  then
    TARGET=`mysql -u root -h 192.168.2.224 -popenstack -D neutron -e "SELECT * FROM neutron.poolloadbalanceragentbindings;" | grep $LBAAS_AGENT_NEUTRON02 | awk '{print $1}'`
    if [ -z "$TARGET" ]
      then
      echo "There is no running Loadbalancer on Neutron02"
      exit 1
    fi
    for i in $TARGET
    do
      echo "Update load balancers on Neutron02 to Neutron01"
      AGENT_ID="'${LBAAS_AGENT_NEUTRON01}'"
      POOL_ID="'$i'"
      QUERY='UPDATE `neutron`.`poolloadbalanceragentbindings` SET `agent_id`='"${AGENT_ID}"' WHERE `pool_id`='"$POOL_ID"';'
      echo $QUERY | mysql -u root -h 192.168.2.224 -popenstack -D neutron 
      mysql -u root -h 192.168.2.224 -popenstack -D neutron -e "SELECT * FROM neutron.poolloadbalanceragentbindings;"
      AGENT_ID=""
    done
fi

if [ "$1" == "neutron01" ]
  then
    TARGET=`mysql -u root -h 192.168.2.224 -popenstack -D neutron -e "SELECT * FROM neutron.poolloadbalanceragentbindings;" | grep $LBAAS_AGENT_NEUTRON01 | awk '{print $1}'`
    if [ -z "$TARGET" ]
      then
      juju run --unit neutron-gateway/0 'sudo restart neutron-lbaas-agent'
    fi
elif [ "$1" == "neutron02" ]
  then
    TARGET=`mysql -u root -h 192.168.2.224 -popenstack -D neutron -e "SELECT * FROM neutron.poolloadbalanceragentbindings;" | grep $LBAAS_AGENT_NEUTRON02 | awk '{print $1}'`
    if [ -z "$TARGET" ]
      then
      juju run --unit neutron-gateway/1 'sudo restart neutron-lbaas-agent'
    fi
fi
