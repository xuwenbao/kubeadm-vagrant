BOX_IMAGE = "ubuntu/xenial64"
KUBERNETES_VERSION = "1.13.2"
CNI_VERSION="0.6.0"
ETCD_VERSION = "3.2.24"
IMAGE_REPOSITORY = "registry.cn-hangzhou.aliyuncs.com/xuwenbao"
SETUP_MASTER = true
SETUP_NODES = true
NODE_COUNT = 2
MASTER_IP = "192.168.26.10"
NODE_IP_NW = "192.168.26."
#NODE_IP_NW = "192.168.122."
POD_NW_CIDR = "10.244.0.0/16"

#Generate new using steps in README
KUBETOKEN = "b029ee.968a33e8d8e6bb0d"

$kubeadmconfscript=<<CONFSCRIPT

mkdir -p /etc/kubernetes
cat <<EOF > /etc/kubernetes/kubeadm.conf
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
bootstrapTokens:
- token: "#{KUBETOKEN}"
  description: "kubeadm bootstrap token"
  ttl: "2400h"
localAPIEndpoint:
  advertiseAddress: #{MASTER_IP}
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: "v#{KUBERNETES_VERSION}"
imageRepository: "#{IMAGE_REPOSITORY}"
useHyperKubeImage: false
etcd:
  local:
    imageRepository: "#{IMAGE_REPOSITORY}"
    imageTag: "#{ETCD_VERSION}"
networking:
  podSubnet: "#{POD_NW_CIDR}"
  dnsDomain: "cluster.local"
apiServer:
  extraArgs:
    insecure-port: "8080"
    insecure-bind-address: "0.0.0.0"
EOF

CONFSCRIPT

$kubeminionscript = <<MINIONSCRIPT

set -e

kubeadm reset --force
kubeadm join --token #{KUBETOKEN} #{MASTER_IP}:6443 --discovery-token-unsafe-skip-ca-verification

MINIONSCRIPT

$kubemasterscript = <<SCRIPT

set -e

kubeadm reset --force
# kubeadm init --apiserver-advertise-address=#{MASTER_IP} --pod-network-cidr=#{POD_NW_CIDR} --token #{KUBETOKEN} --token-ttl 0
kubeadm init --config=/etc/kubernetes/kubeadm.conf

mkdir -p $HOME/.kube
sudo cp -Rf /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install flannel
kubectl apply -f https://raw.githubusercontent.com/xuwenbao/kubeadm-vagrant/master/kube-flannel.yaml

# install kube-router, 见 https://github.com/cloudnativelabs/kube-router/blob/master/docs/kubeadm.md
# kubectl apply -f https://raw.githubusercontent.com/xuwenbao/kubeadm-vagrant/master/kube-router.yaml
# 由于kubeadm还未完全支持可选安装kube-proxy，需要手动执行如下清除命令
# kubectl delete ds kube-proxy -n kube-system
# docker run --privileged -v /lib/modules:/lib/modules --net=host k8s.gcr.io/kube-proxy-amd64:v1.10.2 kube-proxy --cleanup

# install helm
kubectl apply -f https://raw.githubusercontent.com/xuwenbao/kubeadm-vagrant/master/helm-rbac.yaml
sudo docker pull xuwenbao/charts && sudo docker run -d -p 8879:8879 --restart=always --name=charts xuwenbao/charts
# sudo docker cp charts:/usr/local/bin/helm /usr/local/bin/
# helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.0 --stable-repo-url http://127.0.0.1:8879 --local-repo-url http://127.0.0.1:8879 --service-account tiller

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.box_check_update = false

  config.vm.provider "virtualbox" do |l|
    l.cpus = 1
    l.memory = "1024"
  end

  config.vm.provision :shell, :path => "setup.sh", env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION, "CNI_VERSION" => CNI_VERSION}
  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  # config.vm.network "public_network"

  if SETUP_MASTER
    config.vm.define "master" do |subconfig|
      subconfig.vm.hostname = "master"
      subconfig.vm.network :private_network, ip: MASTER_IP
      subconfig.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ["modifyvm", :id, "--memory", "2048"]
      end
      subconfig.vm.synced_folder ".", "/vagrant"
      subconfig.vm.provision :shell, inline: $kubeadmconfscript
      subconfig.vm.provision :shell, inline: $kubemasterscript

      subconfig.vm.network "forwarded_port", guest: 2376, host: 2376
      subconfig.vm.network "forwarded_port", guest: 8080, host: 8080
      subconfig.vm.network "forwarded_port", guest: 8081, host: 8081
      subconfig.vm.network "forwarded_port", guest: 6443, host: 6443
      subconfig.vm.network "forwarded_port", guest: 8879, host: 8879
      subconfig.vm.network "forwarded_port", guest: 4194, host: 4194
      subconfig.vm.network "forwarded_port", guest: 10250, host: 10250
    end
  end

  if SETUP_NODES
    (1..NODE_COUNT).each do |i|
      config.vm.define "node#{i}" do |subconfig|
        subconfig.vm.hostname = "node#{i}"
        subconfig.vm.network :private_network, ip: NODE_IP_NW + "#{i + 10}"
        subconfig.vm.provision :shell, inline: $kubeminionscript
      end
    end
  end
end
