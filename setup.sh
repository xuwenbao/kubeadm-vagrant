#!/bin/sh

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
# apt-get update

curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
apt-get install -y kubelet kubeadm kubectl --allow-unauthenticated

# use my aliyun docker image mirror
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://5xtzb6tv.mirror.aliyuncs.com"]
}
EOF

systemctl enable docker && systemctl start docker
systemctl enable kubelet && systemctl start kubelet

CGROUP_DRIVER=$(sudo docker info | grep "Cgroup Driver" | awk '{print $3}')

sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--cgroup-driver=$CGROUP_DRIVER --pod-infra-container-image=xuwenbao/pause-amd64:3.0 |g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# sed -i 's/10.96.0.10/10.3.3.10/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload
systemctl stop kubelet && systemctl start kubelet
