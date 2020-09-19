#!/bin/bash

tee -a /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
EOF

apt-get update && apt-get upgrade -y
curl -fsSL http://get.docker.com | bash

apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl