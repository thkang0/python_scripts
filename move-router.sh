#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Usage: move-route.sh <router-id>"
  exit 1
fi

#ROUTER=`neutron router-list | grep $1`
ROUTER=$1
neutron l3-agent-list-hosting-router $ROUTER
TARGET=`neutron l3-agent-list-hosting-router $ROUTER | grep active | awk '{print $4}'`

if [ "$TARGET" == "neutron01" ]
  then
    HA_INTERFACE=`juju run --unit neutron-gateway/0 "sudo ip netns exec qrouter-${ROUTER} ip a" | grep ha | grep UP | awk '{print $2}' | cut -d ':' -f1`
    if [ -z "$HA_INTERFACE" ]
      then
        echo "There is no HA Interface up"
        exit 1
    else
        juju run --unit neutron-gateway/0 "sudo ip netns exec qrouter-${ROUTER} ip link set ${HA_INTERFACE} down"
        #juju run --unit neutron-gateway/1 "sudo ip netns exec qrouter-${ROUTER} ip a"
        MONITOR="standby"
        while :
        do 
          if [ "$MONITOR" == "standby" ]
            then
              MONITOR=`neutron l3-agent-list-hosting-router $ROUTER | grep neutron02 | awk '{print $10}'`
              echo "Router status on neutron02 : ${MONITOR}"
              sleep 5 
          else
            break
          fi
        done
        if [ "$MONITOR" == "active" ]
          then
            echo "HA Interface(already down) on neutron01 is going up now"
            juju run --unit neutron-gateway/0 "sudo ip netns exec qrouter-${ROUTER} ip link set ${HA_INTERFACE} up"
            juju run --unit neutron-gateway/0 "sudo ip netns exec qrouter-${ROUTER} ip a s ${HA_INTERFACE}"
        fi
    fi
elif [ "$TARGET" == "neutron02" ]
  then
    HA_INTERFACE=`juju run --unit neutron-gateway/1 "sudo ip netns exec qrouter-${ROUTER} ip a" | grep ha | grep UP | awk '{print $2}' | cut -d ':' -f1`
    if [ -z "$HA_INTERFACE" ]
      then
        echo "There is no HA Interface up"
        exit 1
    else
        juju run --unit neutron-gateway/1 "sudo ip netns exec qrouter-${ROUTER} ip link set ${HA_INTERFACE} down"
        #juju run --unit neutron-gateway/1 "sudo ip netns exec qrouter-${ROUTER} ip a"
        MONITOR="standby"
        while :
        do 
          if [ "$MONITOR" == "standby" ]
            then
              MONITOR=`neutron l3-agent-list-hosting-router $ROUTER | grep neutron01 | awk '{print $10}'`
              echo "Router status on neutron01 : ${MONITOR}"
              sleep 5 
          else
            break
          fi
        done
        if [ "$MONITOR" == "active" ]
          then
            echo "HA Interface(already down) on neutron02 is going up now"
            juju run --unit neutron-gateway/1 "sudo ip netns exec qrouter-${ROUTER} ip link set ${HA_INTERFACE} up"
            juju run --unit neutron-gateway/1 "sudo ip netns exec qrouter-${ROUTER} ip a s ${HA_INTERFACE}"
        fi
    fi
fi

neutron l3-agent-list-hosting-router $ROUTER
