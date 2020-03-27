#!/bin/bash
set -euo pipefail

sleep 25

openssl rand -out $HOME/.rnd 128

cd /openair-cn/scripts

PREFIX='/usr/local/etc/oai'
MY_REALM='home.lab'


./data_provisioning_users --apn oai.ipv4 --apn2 internet --key 8baf473f2f8fd09487cccbd7097c6862 --imsi-first 208950000000002 --msisdn-first 001011234561000 --mme-identity mme.$MY_REALM --no-of-users 40 --realm $MY_REALM --truncate True  --verbose True --cassandra-cluster $Cassandra_Server_IP
./data_provisioning_mme --id 3 --mme-identity mme.$MY_REALM --realm $MY_REALM --ue-reachability 1 --truncate True  --verbose True -C $Cassandra_Server_IP


sudo mkdir -m 0777 -p $PREFIX
sudo chmod 777 $PREFIX
sudo mkdir -m 0777 -p $PREFIX/freeDiameter
sudo mkdir -m 0777 -p $PREFIX/logs
sudo mkdir -m 0777 -p logs
cp ../etc/acl.conf ../etc/hss_rel14_fd.conf $PREFIX/freeDiameter
cp ../etc/hss_rel14.conf ../etc/hss_rel14.json $PREFIX
cp ../etc/oss.json $PREFIX

declare -A HSS_CONF
HSS_CONF[@PREFIX@]=$PREFIX
HSS_CONF[@REALM@]=$MY_REALM
HSS_CONF[@HSS_FQDN@]="hss.${HSS_CONF[@REALM@]}"
HSS_CONF[@cassandra_Server_IP@]=$Cassandra_Server_IP
HSS_CONF[@OP_KEY@]='11111111111111111111111111111111'
HSS_CONF[@ROAMING_ALLOWED@]='true'
for K in "${!HSS_CONF[@]}"; do    egrep -lRZ "$K" $PREFIX | xargs -0 -l sed -i -e "s|$K|${HSS_CONF[$K]}|g"; done
sed -i -e 's/#ListenOn/ListenOn/g' $PREFIX/freeDiameter/hss_rel14_fd.conf
../src/hss_rel14/bin/make_certs.sh hss ${HSS_CONF[@REALM@]} $PREFIX

oai_hss -j $PREFIX/hss_rel14.json
