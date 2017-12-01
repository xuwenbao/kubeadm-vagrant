# kubeadm-vagrant

> **无需翻墙**

使用kubeadm和vagrnat部署可用于研发、测试、学习等用途的非生产环境Kubernetes集群, 支持Windows和Linux系统.

## 环境要求

启动时, 会创建3个虚拟机. 1个Master节点, 2个node节点. 最低配置消耗(可调整):

* 内存3G
* 硬盘30G

## 安装步骤

### Step 1, 安装virtualbox与vagrant

略

### Step 2, 启动虚拟机

>此步骤因需要连接网络下载容器镜像等, 不同网络条件下, 过程可能持续30分钟及以上

在项目根目录执行命令 `vagrant up` , 等待执行完成.

### Step3, 查看安装结果

在项目根目录执行命令 `vagrant ssh master` , 登录至master节点

输入命令查看集群是否正常

```
sudo su -
kubectl get nodes
kubectl get pods --all-namespaces
```
