BOX_IMAGE = "ubuntu/xenial64"
SETUP_MASTER = true
SETUP_NODES = true
NODE_COUNT = 2
MASTER_IP = "192.168.26.10"
NODE_IP_NW = "192.168.26."
#NODE_IP_NW = "192.168.122."
POD_NW_CIDR = "10.244.0.0/16"

#Generate new using steps in README
KUBETOKEN = "b029ee.968a33e8d8e6bb0d"

$kubeminionscript = <<MINIONSCRIPT

kubeadm reset
kubeadm join --token #{KUBETOKEN} #{MASTER_IP}:6443

MINIONSCRIPT

$kubemasterscript = <<SCRIPT

kubeadm reset
kubeadm init --apiserver-advertise-address=#{MASTER_IP} --pod-network-cidr=#{POD_NW_CIDR} --token #{KUBETOKEN} --token-ttl 0 --config=/srv/kubeadm/kubeadm-master.yml

mkdir -p $HOME/.kube
sudo cp -Rf /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/xuwenbao/kubernetes-beginner-course/master/examples/chapter-2/kube-flannel.yaml

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.box_check_update = false

  config.vm.provider "virtualbox" do |l|
    l.cpus = 1
    l.memory = "1024"
  end

  config.vm.synced_folder ".", "/srv/kubeadm"
  config.vm.provision :shell, :path => "setup.sh"

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
      subconfig.vm.provision :shell, inline: $kubemasterscript
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
