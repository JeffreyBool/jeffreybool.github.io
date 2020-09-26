---
title: golang 锁请小心使用
top: true
categories: golang
tags: golang
abbrlink: '9e862485'
date: 2020-06-05 11:17:11
---

## 关于锁使用
 减少读写锁粒度和范围大小，尽可能尽早释放，锁和 `defer` 配合使用容易踩坑，因为会出现死锁，意思就是，这段代码可能会重复加锁，这种问题可能是偶发引起的，所以很难排查。

1. 提前 `unlock`
![golang 锁请小心使用](https://api.zhanggaoyuan.com/uploads/images/articles/202005/29/1_1590744022_k7ZtwmAx9H.png)

2. 不能提前 `unlock` 怎么办？如何处理???
![golang 锁请小心使用](https://api.zhanggaoyuan.com/uploads/images/articles/202005/29/1_1590744031_4Ay8Ub0Ntd.png)
![golang 锁请小心使用](https://api.zhanggaoyuan.com/uploads/images/articles/202005/29/1_1590744040_vMvix7i2KO.png)
![golang 锁请小心使用](https://api.zhanggaoyuan.com/uploads/images/articles/202005/29/1_1590744050_ewlAjsdhpx.png)
![golang 锁请小心使用](https://api.zhanggaoyuan.com/uploads/images/articles/202005/29/1_1590744056_VlDn6KYxy9.png)

以上就是处理锁提前返回防止坑，能够知道锁什么时间释放很重要，往往很多坑就是这个函数已经 `lock` 锁了，然后再调用另外一个函数 `a->b->c->d`， 如此调用链；你不会知道这些函数是否也调用了这个函数的锁实例，导致死锁的发生。而且还有一点，像上图的 `SendMessage` 可能是一个耗时调用，那么这个锁就会一直阻塞在这里得不到释放。像我遇到的一个坑就是调用 `SendMessage` 函数，然后这个函数给客户端发送消息，然后由于客户端种种原因导致消息发送失败触发我的 close 函数，然后 close 内部处理资源清理导致再调用这个锁实例的函数导致重复加锁，这个 😭😭`BUG` 隐藏的很深，一般看不出来。

原文链接：[https://www.zhanggaoyuan.com/article/61](https://www.zhanggaoyuan.com/article/61)