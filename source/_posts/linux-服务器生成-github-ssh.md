---
title: linux 服务器生成 github ssh
categories: linux
tags:
  - linux
  - github
  - ssh
abbrlink: a0bb4ed9
date: 2020-06-05 12:41:50
---

## 服务器生成 git ssh 步骤详细记录：

### 1. 首先检查自己之前是否有生成
>$ ls -al ~/.ssh  

### 2. 检查自己是否有配置过git 全局配置
> git config user.name 
> git config user.email

以上两个命令可以检查是否已经有配置过 github 全局配置信息，配置过是如下显示
```
[root@VM_0_13_centos wwwroot]# git config user.name
JeffreyBool
```

如果没有配置，可以通过以下命令设置
> git config --global user.name '你的github名称'
> git config user.email '你的 github 邮箱'

### 3. 生成秘钥
> ssh-keygen -t rsa -C '你的 github 邮箱'

步骤如下:

```
[root@VM_0_13_centos .ssh]# ssh-keygen -t rsa -C '1402992668@qq.com'
Generating public/private rsa key pair.

▽
Enter file in which to save the key (/root/.ssh/id_rsa): github
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in github.
Your public key has been saved in github.pub.
The key fingerprint is:
SHA256:rCizfSAB6nxdIUNCrKclfsm+xXnCjoAMv+WNMmVhnPg 1402992668@qq.com
The key's randomart image is:
+---[RSA 2048]----+
|  oo..           |
|.  ..o .         |
|...o .o .        |
|.ooo=  o         |
|= *+o.. S        |
|+*.=Eo..         |
|.oB+oB..         |
|  +X+o+          |
|  o==o.          |
+----[SHA256]-----+
```


- 查看生成的文件
 

> ll 
 
 ```
 -rw------- 1 root root  794 10月 16 20:37 authorized_keys
-rw------- 1 root root 1679 12月 30 20:40 github
-rw-r--r-- 1 root root  399 12月 30 20:40 github.pub
 ```
 
这时候我们已经生成完毕。

### 3. 如果想登陆远端，则需要将rsa.pub里的秘钥添加到远端。

-  首先，去.ssh目录下找到`github.pub`这个文件夹打开复制全部内容。
- 登录GitHub，进入你的Settings

![image.png](https://api.zhanggaoyuan.com/uploads/images/articles/202003/03/1_1583215014_qyWInUvrFV.png)![](media/15777098619113/15777104858355.jpg)

- 会看到左边这些目录，点击SSH and GPG keys

![image.png](https://api.zhanggaoyuan.com/uploads/images/articles/202003/03/1_1583215030_UbsjRj6wha.png)![](media/15777098619113/15777105819556.jpg)

-  创建New SSH key

 ![image.png](https://api.zhanggaoyuan.com/uploads/images/articles/202003/03/1_1583215050_zfgeuNftkf.png)![](media/15777098619113/15777106443651.jpg)

-  点击Add SSH key
-  再弹出窗口，输入你的GitHub密码，点击确认按钮。
-  到此，就大功告成了。

### 4.测试。
> ssh -T git@github.com

```
[root@VM_0_13_centos ~]# ssh-add ~/.ssh/github
Could not open a connection to your authentication agent.
```
发现出现以上报错信息

> ssh-agent bash

我百度了解决方案使用以下命令可以解决以上的问题。

>ssh -T git@github.com
按回车键，如看到以下信息，那么就完美了。

```
[root@VM_0_13_centos ~]# ssh -T git@github.com
Hi JeffreyBool! You've successfully authenticated, but GitHub does not provide shell access.
```


原文链接：[https://www.zhanggaoyuan.com/article/54](https://www.zhanggaoyuan.com/article/54)
