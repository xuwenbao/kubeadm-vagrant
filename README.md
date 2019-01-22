# kubeadm-vagrant

使用kubeadm与vagrant自动化搭建学习、开发用Kubernetes集群（无需科学上网）, Windows、Linux、OSX系统均可支持。

## 前言

虽然Kubernetes社区提供了很多部署工具来降低部署一套Kubernetes集群的学习成本，如：minikube、kops、ansible和本项目使用的kubeadm等等，但完整部署出一套Kubernetes集群仍不是一个简单的过程，何况在国内还有GFW的存在。
我们应该将更多精力用在学习Kubernetes核心理念和寻找最佳实践上，而不是一次次安装、更新与升级。重复的工作应该自动化完成 ：）

## 资源需求

启动时, 会默认创建3个虚拟机. 1个Master节点, 2个node节点。

> 节点数量与虚拟机规格均可调整，参见“常见问题”一节。

最低资源需求:

* 虚拟CPU：4核（主节点2核，2个Node节点各1核）
* 内存：4G（主节点2G，2个Node节点各1G）
* 磁盘空间：约30G

## 安装步骤

### Step 1, 安装virtualbox与vagrant

1. 安装vagrant

    下载地址：[https://www.vagrantup.com/downloads.html](https://www.vagrantup.com/downloads.html)，下载操作系统对应的最新版本，根据引导安装即可。

2. 安装virtualbox

    下载地址：[https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)，下载操作系统对应的最新版本，根据引导安装即可。

### Step 2, 启动虚拟机

> 此步骤因需要连接网络下载容器镜像等资源, 不同网络条件下, 过程可能持续30分钟及以上。

在项目根目录执行命令 `vagrant up` , 耐心等待执行完成。

### Step3, 查看安装结果

在项目根目录执行命令 `vagrant ssh master` , 登录至master节点。

输入 `kubectl get nodes`，查看返回结果中node是否都为**ready**状态。

> VERSION列可能根据安装时的版本，会有不同。

```console
NAME     STATUS   ROLES    AGE     VERSION
master   Ready    master   2d20h   v1.13.2
node1    Ready    <none>   2d20h   v1.13.2
node2    Ready    <none>   2d20h   v1.13.2
```

输入 `kubectl get pods --all-namespaces`，查看集群组件Pod是否正常运行。

```console
NAMESPACE          NAME                                                READY   STATUS    RESTARTS   AGE
kube-system        coredns-5f6c4796d6-86r5n                            1/1     Running   5          2d20h
kube-system        coredns-5f6c4796d6-h2462                            1/1     Running   5          2d20h
kube-system        etcd-master                                         1/1     Running   5          2d20h
kube-system        kube-apiserver-master                               1/1     Running   5          2d20h
kube-system        kube-controller-manager-master                      1/1     Running   5          2d20h
kube-system        kube-flannel-ds-6pkzw                               1/1     Running   8          2d20h
kube-system        kube-flannel-ds-fhmj4                               1/1     Running   5          2d
kube-system        kube-flannel-ds-w7fwj                               1/1     Running   6          2d20h
kube-system        kube-proxy-h489s                                    1/1     Running   5          2d20h
kube-system        kube-proxy-jlplq                                    1/1     Running   5          2d20h
kube-system        kube-proxy-kwkb9                                    1/1     Running   5          2d20h
kube-system        kube-scheduler-master                               1/1     Running   5          2d20h
```

## 映射到宿主机上的端口

为了方便开发调试，默认映射了几个端口到宿主机上。

### Docker Remote Port（端口：2376）

暴露此端口的目的是，可以在宿主机上设置环境变量 `export DOCKER_HOST=tcp://127.0.0.1:2376` 后，直接在宿主机命令行执行docker相关命令操作Master节点中的Docker服务进程。

### Kubernetes APIServer Port（端口：8080与6443）

> 8080为非加密访问端口，6443为加密访问端口。一般学习、开发目的使用8080端口即可。

暴露此端口的目的是可以在宿主机上执行 `kubectl` 命令，省去每次ssh登录到master节点的步骤，而且可以使用`kubectl port-forward`命令将集群内部Pod的访问端口暴露至宿主机，直接在宿主机访问。强烈推荐！

各操作系统安装kubectl请参见官方文档：[https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Helm Charts Server Port（端口：8879）

**划重点**，当度过了学习Kubernetes核心概念阶段之后，你可能需要在集群中安装稍微大规模的系统，如Prometheus、ROOK、Mysql Cluster等等，使用Helm安装是再方便不过的了。

集群中默认预置了Helm的Charts Server，并初始化了Helm的RBAC配置，但并没有安装Helm。原因同kubectl，推荐在宿主机中安装Helm命令行，并进行初始化操作，省去来回登录虚拟机的繁琐。

在宿主机中安装Helm命令行后，执行如下命令。

```shell
helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.0 --stable-repo-url http://127.0.0.1:8879 --local-repo-url http://127.0.0.1:8879 --service-account tiller
```

如果要在虚拟机中安装Helm，执行如下命令：

```shell
sudo docker cp charts:/usr/local/bin/helm /usr/local/bin/
helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.0 --stable-repo-url http://127.0.0.1:8879 --local-repo-url http://127.0.0.1:8879 --service-account tiller

```

二者选其一，即可。

## 常见问题

待续。

## 后续计划添加的功能

1. 支持可选配置Docker Registry Mirror，例如：可以配置阿里云镜像加速器加速从Docker Hub下载镜像。
2. 支持可选安装Helm、Rook等其他Kubernetes社区工具。

## 还有其他问题？

待续。
