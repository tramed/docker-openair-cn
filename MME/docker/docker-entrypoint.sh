#!/bin/bash
set -euo pipefail

sleep 30

openssl rand -out $HOME/.rnd 128

cd /openair-cn/scripts

INSTANCE=1
PREFIX='/usr/local/etc/oai'
MY_REALM='home.lab'

mkdir -m 0777 -p $PREFIX
chmod 777 $PREFIX
mkdir -m 0777 -p $PREFIX/freeDiameter
# freeDiameter configuration file
cp ../etc/mme_fd.sprint.conf  $PREFIX/freeDiameter/mme_fd.conf
cp ../etc/mme.conf  $PREFIX


declare -A MME_CONF

MME_CONF[@MME_S6A_IP_ADDR@]="192.168.1.4"
MME_CONF[@INSTANCE@]=$INSTANCE
MME_CONF[@PREFIX@]=$PREFIX
MME_CONF[@REALM@]=$MY_REALM
MME_CONF[@PID_DIRECTORY@]='/var/run'
MME_CONF[@MME_FQDN@]="mme.${MME_CONF[@REALM@]}"
MME_CONF[@HSS_HOSTNAME@]='hss'
MME_CONF[@HSS_FQDN@]="${MME_CONF[@HSS_HOSTNAME@]}.${MME_CONF[@REALM@]}"
MME_CONF[@HSS_IP_ADDR@]="192.168.1.2"

# HERE I HAVE THE CORRECT MCC / NNC
MME_CONF[@MCC@]='208'
MME_CONF[@MNC@]='95'
MME_CONF[@MME_GID@]='32768'
MME_CONF[@MME_CODE@]='3'
MME_CONF[@TAC_0@]='600'
MME_CONF[@TAC_1@]='601'
MME_CONF[@TAC_2@]='602'

# ALL SUB NETWORK INTERFACES ARE ens19 BASED
# S1 will be the 1st interface to be reached by an eNB --> on ens19 and 192.168.3.17 is the IP address on ens19
MME_CONF[@MME_INTERFACE_NAME_FOR_S1_MME@]='eth1'
MME_CONF[@MME_IPV4_ADDRESS_FOR_S1_MME@]='192.168.2.4/24'
MME_CONF[@MME_INTERFACE_NAME_FOR_S11@]='eth0'
MME_CONF[@MME_IPV4_ADDRESS_FOR_S11@]='192.168.3.5/24'
MME_CONF[@MME_INTERFACE_NAME_FOR_S10@]='lo'
MME_CONF[@MME_IPV4_ADDRESS_FOR_S10@]='127.0.0.11/8'
MME_CONF[@OUTPUT@]='CONSOLE'
MME_CONF[@SGW_IPV4_ADDRESS_FOR_S11_TEST_0@]='192.168.3.5/24'
MME_CONF[@SGW_IPV4_ADDRESS_FOR_S11_0@]='192.168.3.5/24'
MME_CONF[@PEER_MME_IPV4_ADDRESS_FOR_S10_0@]='0.0.0.0/24'
MME_CONF[@PEER_MME_IPV4_ADDRESS_FOR_S10_1@]='0.0.0.0/24'
# the rest is the same in Lionel setup
TAC_SGW_TEST='7'
tmph=`echo "$TAC_SGW_TEST / 256" | bc`
tmpl=`echo "$TAC_SGW_TEST % 256" | bc`
MME_CONF[@TAC-LB_SGW_TEST_0@]=`printf "%02x\n" $tmpl`
MME_CONF[@TAC-HB_SGW_TEST_0@]=`printf "%02x\n" $tmph`
MME_CONF[@MCC_SGW_0@]=${MME_CONF[@MCC@]}
MME_CONF[@MNC3_SGW_0@]=`printf "%03d\n" $(echo ${MME_CONF[@MNC@]} | sed 's/^0*//')`
TAC_SGW_0='600'
tmph=`echo "$TAC_SGW_0 / 256" | bc`
tmpl=`echo "$TAC_SGW_0 % 256" | bc`
MME_CONF[@TAC-LB_SGW_0@]=`printf "%02x\n" $tmpl`
MME_CONF[@TAC-HB_SGW_0@]=`printf "%02x\n" $tmph`
MME_CONF[@MCC_MME_0@]=${MME_CONF[@MCC@]}
MME_CONF[@MNC3_MME_0@]=`printf "%03d\n" $(echo ${MME_CONF[@MNC@]} | sed 's/^0*//')`
TAC_MME_0='601'
tmph=`echo "$TAC_MME_0 / 256" | bc`
tmpl=`echo "$TAC_MME_0 % 256" | bc`
MME_CONF[@TAC-LB_MME_0@]=`printf "%02x\n" $tmpl`
MME_CONF[@TAC-HB_MME_0@]=`printf "%02x\n" $tmph`
MME_CONF[@MCC_MME_1@]=${MME_CONF[@MCC@]}
MME_CONF[@MNC3_MME_1@]=`printf "%03d\n" $(echo ${MME_CONF[@MNC@]} | sed 's/^0*//')`
TAC_MME_1='602'
tmph=`echo "$TAC_MME_1 / 256" | bc`
tmpl=`echo "$TAC_MME_1 % 256" | bc`
MME_CONF[@TAC-LB_MME_1@]=`printf "%02x\n" $tmpl`
MME_CONF[@TAC-HB_MME_1@]=`printf "%02x\n" $tmph`
for K in "${!MME_CONF[@]}"; do    egrep -lRZ "$K" $PREFIX | xargs -0 -l sed -i -e "s|$K|${MME_CONF[$K]}|g";   ret=$?;[[ ret -ne 0 ]] && echo "Tried to replace $K with ${MME_CONF[$K]}"; done
./check_mme_s6a_certificate $PREFIX/freeDiameter mme.${MME_CONF[@REALM@]}

cd /openair-cn/scripts
sleep 5
./run_mme --config-file /usr/local/etc/oai/mme.conf