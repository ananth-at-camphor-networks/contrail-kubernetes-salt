#!/bin/bash

set -e

function master() {
    ssh -oStrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${KUBE_MASTER_IP}" sudo "$*"
}

function verify_contrail_listen_services() {
    master netstat -anp | \grep LISTEN | \grep -w 5672 # RabbitMQ
    master netstat -anp | \grep LISTEN | \grep -w 2181 # ZooKeeper
    master netstat -anp | \grep LISTEN | \grep -w 9160 # Cassandra
    master netstat -anp | \grep LISTEN | \grep -w 5269 # XMPP Server
    master netstat -anp | \grep LISTEN | \grep -w 8083 # Control-Node Introspect
    master netstat -anp | \grep LISTEN | \grep -w 8443 # IFMAP
    master netstat -anp | \grep LISTEN | \grep -w 8082 # API-Server
    master netstat -anp | \grep LISTEN | \grep -w 8087 # Schema
    master netstat -anp | \grep LISTEN | \grep -w 5998 # discovery
    master netstat -anp | \grep LISTEN | \grep -w 8086 # Collector
    master netstat -anp | \grep LISTEN | \grep -w 8081 # OpServer
    master netstat -anp | \grep LISTEN | \grep -w 8091 # query-engine
    master netstat -anp | \grep LISTEN | \grep -w 6379 # redis
    master netstat -anp | \grep LISTEN | \grep -w 8143 # WebUI
    master netstat -anp | \grep LISTEN | \grep -w 8070 # WebUI
    master netstat -anp | \grep LISTEN | \grep -w 3000 # WebUI
}

function provision_bgp() {
    master docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_control.py -o /tmp/provision_control.py"}' | sh
    master docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_bgp.py -o /tmp/provision_bgp.py"}' | sh
    master docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " python /tmp/provision_control.py  --router_asn 64512 --host_name `hostname` --host_ip `hostname --ip-address` --oper add --api_server_ip `hostname --ip-address` --api_server_port 8082"}' | sh
}

function provision_linklocal() {
    master docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " curl -s https://raw.githubusercontent.com/Juniper/contrail-controller/R2.20/src/config/utils/provision_linklocal.py -o /tmp/provision_linklocal.py"}' | sh
    master docker ps |\grep contrail-api |\grep -v pause | awk '{print "docker exec " $1 " python /tmp/provision_linklocal.py --api_server_ip `hostname --ip-address` --api_server_port 8082 --linklocal_service_name kubernetes --linklocal_service_ip 10.0.0.1 --linklocal_service_port 8080 --ipfabric_service_ip `hostname --ip-` --ipfabric_service_port 8080 --oper add"}' | sh
}

function setup_kube_dns_endpoints() {
    master kubectl --namespace=kube-system create -f /etc/kubernetes/addons/kube-ui/kube-ui-endpoint.yaml
    master kubectl --namespace=kube-system create -f /etc/kubernetes/addons/kube-ui/kube-ui-svc-address.yaml
}

function pull_docker_images() {
    cmd='grep source: /srv/salt/contrail-*/* | awk "{print $4}" | xargs -n 1 wget -qO - | grep \"image\": | cut -d "\"" -f 4 | xargs -n1 sudo docker pull'
    master $cmd
    master grep source: /srv/salt/contrail-*/* | awk '{print $4}' | xargs -n1 wget -q --directory-prefix=/etc/kubernetes/manifests
}

function setup_contrail_networking() {
    set -x

    SSH_KEY=$1
    SSH_USER=$2
    KUBE_MASTER_IP=$3

    # Pull all contrail images and copy the manifest files
    pull_docker_images

    # Wait for contrail-control to be ready.
    verify_contrail_listen_services

    # Provision bgp
    provision_bgp

    # Provision link-local service to connect to kube-api
    provision_linklocal

    # Setip kube-dns
    setup_kube_dns_endpoints

    # setup_minions
    exit
}
