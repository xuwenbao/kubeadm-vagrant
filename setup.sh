#!/bin/sh

set -e

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm/
cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted universe multiverse > /etc/apt/sources.list
echo deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse >> /etc/apt/sources.list
echo deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse >> /etc/apt/sources.list
echo deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted universe multiverse >> /etc/apt/sources.list

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 6A030B21BA07F4FB
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://mirrors.ustc.edu.cn/kubernetes/apt/ kubernetes-xenial main
EOF

curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
apt-get install -y kubernetes-cni=${CNI_VERSION}-00 kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00 --allow-unauthenticated

mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/override.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:// -H tcp://0.0.0.0:2376 --registry-mirror=https://5xtzb6tv.mirror.aliyuncs.com
EOF

# CGROUP_DRIVER=$(sudo docker info | grep "Cgroup Driver" | awk '{print $3}')
# sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--cgroup-driver=$CGROUP_DRIVER --pod-infra-container-image=xuwenbao/pause-amd64:3.0 |g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# sed -i 's/10.96.0.10/10.3.3.10/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
echo "KUBELET_EXTRA_ARGS=--read-only-port=10255" > /etc/default/kubelet

systemctl daemon-reload
systemctl enable docker kubelet
systemctl restart docker kubelet
