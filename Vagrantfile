BOX_IMAGE = "ubuntu/xenial64"
# DOCKER_APT_VERSION = "17.03.2-0ubuntu2~16.04.1"
KUBERNETES_VERSION = "1.10.2"
KUBERNETES_APT_VERSION = "1.10.2-00"
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
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: #{MASTER_IP}
  etcd:
  image: registry.cn-beijing.aliyuncs.com/k8s_images/etcd-amd64:3.1.13
networking:
  podSubnet: #{POD_NW_CIDR}
kubernetesVersion: v#{KUBERNETES_VERSION}
token: #{KUBETOKEN}
tokenTTL: 2400h
imageRepository: registry.cn-beijing.aliyuncs.com/k8s_images
apiServerExtraArgs:
  insecure-port: "8080"
  insecure-bind-address: "0.0.0.0"
EOF

CONFSCRIPT

$kubeminionscript = <<MINIONSCRIPT

kubeadm reset
kubeadm join --token #{KUBETOKEN} #{MASTER_IP}:6443 --discovery-token-unsafe-skip-ca-verification

MINIONSCRIPT

$kubemasterscript = <<SCRIPT

kubeadm reset
# kubeadm init --apiserver-advertise-address=#{MASTER_IP} --pod-network-cidr=#{POD_NW_CIDR} --token #{KUBETOKEN} --token-ttl 0
kubeadm init --config=/etc/kubernetes/kubeadm.conf

mkdir -p $HOME/.kube
sudo cp -Rf /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/xuwenbao/kubeadm-vagrant/master/kube-flannel.yaml

# install helm
kubectl apply -f https://raw.githubusercontent.com/xuwenbao/kubeadm-vagrant/master/helm-rbac.yaml

sudo curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
sudo docker pull xuwenbao/charts && sudo docker run -d -p 80:80 --restart=always xuwenbao/charts
helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.0 --stable-repo-url http://127.0.0.1/charts --local-repo-url http://127.0.0.1/charts --service-account tiller

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.box_check_update = false

  config.vm.provider "virtualbox" do |l|
    l.cpus = 1
    l.memory = "1024"
  end

  # config.vm.synced_folder ".", "/srv/kubeadm"
  # config.vm.provision :shell, :path => "setup.sh", env: {"DOCKER_VERSION" => DOCKER_APT_VERSION, "KUBERNETES_VERSION" => KUBERNETES_APT_VERSION }
  config.vm.provision :shell, :path => "setup.sh", env: {"KUBERNETES_VERSION" => KUBERNETES_APT_VERSION }

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
      subconfig.vm.provision :shell, inline: $kubeadmconfscript
      subconfig.vm.provision :shell, inline: $kubemasterscript

      subconfig.vm.network "forwarded_port", guest: 8080, host: 8080
      subconfig.vm.network "forwarded_port", guest: 8081, host: 8081
      subconfig.vm.network "forwarded_port", guest: 6443, host: 6443
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
