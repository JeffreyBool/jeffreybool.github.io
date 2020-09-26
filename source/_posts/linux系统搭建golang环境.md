---
title: linux系统搭建golang环境
categories: golang
tags:
  - linux
  - golang
abbrlink: fdc92cde
date: 2020-06-05 12:49:00
---

## 第一步打开 `golang` 官方找到安装版本列表

> 安装地址[https://golang.google.cn/dl/](https://golang.google.cn/dl/)


我们找到 `linux`系统版本，复制这个链接

> wget https://dl.google.com/go/go1.13.6.linux-amd64.tar.gz

![image.png](https://api.zhanggaoyuan.com/uploads/images/articles/202001/10/1_1578646097_Lsyt7j1IMP.png)

## 第二部解压
 > tar -C /usr/local -xzf go1.13.6.linux-amd64.tar.gz

![linux系统搭建golang环境](https://api.zhanggaoyuan.com/uploads/images/articles/202001/10/1_1578646131_uKxBOtfAut.png)

## 第三步添加环境变量到 `/etc/profile`
- 打开 `/etc/profile ` 文件
- 添加 export PATH=$PATH:/usr/local/go/bin
- 重新加载 `source /etc/profile`

## 查看是否安装成功

```bash
go --version
```

![linux系统搭建golang环境](https://api.zhanggaoyuan.com/uploads/images/articles/202001/10/1_1578646097_Lsyt7j1IMP.png)


## 参考
[golang官方文档](https://golang.google.cn/doc/install?download=go1.13.6.linux-amd64.tar.gz)

原文链接：[https://www.zhanggaoyuan.com/article/51](https://www.zhanggaoyuan.com/article/51)
