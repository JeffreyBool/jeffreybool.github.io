---
title: 阿里云搭建shadowsocks
abbrlink: 4f7e349a
date: 2020-09-26 11:13:31
tags:
---

## 安装 shadowsocks

下载 shadowsocks.sh shell

> wget https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks.sh

赋予 shadowsocks.sh 执行权限

> chmod +x shadowsocks.sh

运行安装脚本

> ./shadowsocks.sh>&1 | tee shadowsocks.log

*这里会提示输入密码，需记下shadowsocks的登录密码，后面PC、手机登录用*

![](http://cdn.zhanggaoyuan.com/article/20200926/sCPSpK.jpg)

端口可以默认，也可以自己设置（需记住端口号，阿里云配置规则及PC、手机登录需用到）

![](http://cdn.zhanggaoyuan.com/article/20200926/hron8m.jpg)

输入： 7，选择 `aes-256-cfb`

然后等待自动配置，可能要小等上几分钟。完成后会提示按Enter键继续，敲下Enter完成。

到这里shadowsocks部署在云服务器配置完成。

如果需要配置, 请打开 `/etc/shadowsocks.json` 文件

> vi /etc/shadowsocks.json

>（特别提醒：阿里云可能过一个月或者更长一段时间会禁用你的端口，导致不能连接网络，不要怕，只要修改下端口及下面“（2）阿里ECS安全组列表添加规则”步骤的相同的端口，就可以了）

如果有需要重启下Shadowsock，服务启动命令：

```bash
启动：systemctl start shadowsocks.service
停止：systemctl stop shadowsocks.service
重启：systemctl restart shadowsocks.service
状态：systemctl status shadowsocks.service
```

## 阿里ECS安全组列表添加规则

- 配置规则

![配置规则](http://cdn.zhanggaoyuan.com/article/20200926/BZjzqc.png)

- 访问规则

首先配置入方向 -> 手动添加

![WlWafI](http://cdn.zhanggaoyuan.com/article/20200926/WlWafI.png)

![iCFrK4](http://cdn.zhanggaoyuan.com/article/20200926/iCFrK4.png)

然后 `出方向` 和上面入方向配置是一样的步骤

## 配置 Shadowsocks连接阿里云ECS

- 地址要服务器的外网地址

- 端口是刚刚安装的时候选择的端口比如我的是 `16471`

- 加密方法 `aes-256-cfb`

- 默认是你自己填的

![R45dsI](http://cdn.zhanggaoyuan.com/article/20200926/R45dsI.png)

![v32wIj](http://cdn.zhanggaoyuan.com/article/20200926/v32wIj.png)


- 手动更新订阅

![39lLS8](http://cdn.zhanggaoyuan.com/article/20200926/39lLS8.png)

- 服务器测试 

![yluM9s](http://cdn.zhanggaoyuan.com/article/20200926/yluM9s.png)

## 参考文档

1. [阿里云服务器搭建Shadowsocks Server及使用SwitchyOmega切换代理设置实战教程](https://blog.sbot.io/articles/36/%E9%98%BF%E9%87%8C%E4%BA%91%E6%9C%8D%E5%8A%A1%E5%99%A8%E6%90%AD%E5%BB%BAShadowsocks-Server%E5%8F%8A%E4%BD%BF%E7%94%A8SwitchyOmega%E5%88%87%E6%8D%A2%E4%BB%A3%E7%90%86%E8%AE%BE%E7%BD%AE%E5%AE%9E%E6%88%98%E6%95%99%E7%A8%8B)
2. [CentOS搭建Shadowsocks服务端](https://medium.com/@WordlessEcho/centos%E6%90%AD%E5%BB%BAshadowsocks%E6%9C%8D%E5%8A%A1%E7%AB%AF-9e305444942e)
3. [阿里云+shadowsocks （最完整版）](https://www.pianshen.com/article/6948261235/)