#!/bin/bash

### Disable SELINUX ####
cat /etc/sysconfig/selinux | grep SELINUX=
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i --follow-symlinks 's/SELINUX=permissive/SELINUX=disabled/g' /etc/sysconfig/selinux
cat /etc/sysconfig/selinux | grep SELINUX=
setenforce 0

### Disable the Firewall ########
systemctl stop firewalld.service
systemctl disable firewalld
systemctl status firewalld

### Make DNS local entries ### Change it as per your requirement #####
cat <<-EOF >>  /etc/hosts

192.168.20.135 master
192.168.20.136  work

EOF

###### swap #########
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

### Preparation for Docker installation #########
modprobe br_netfilter
lsmod | grep br_netfilter

echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sysctl -a | grep net.bridge.bridge-nf-call-iptables
######################



### Docker installation steps #######
sudo yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine buildah
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl start docker
systemctl enable docker
docker run hello-world
######################




### Kubernetes installation steps #####
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet

sleep 5
echo  "Adding in the kubernetes master"