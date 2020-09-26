---
title: 跳表实现原理
categories: redis
tags:
  - redis
  - 数据结构
abbrlink: a7938bd1
date: 2020-06-05 13:17:11
---

是一种动态的数据结构,它可以支持快速的插入、查找、查询操作.写起来并不复杂,甚至可以替代红黑树.

对于一个单链表来讲,即使链表中的储存数据是有序的.如果我们想要在其中查找某个数据,也只能从头到尾遍历链表.这样的效率会很低,时间复杂度也很高  `O(n)`.

![跳表实现原理](https://api.zhanggaoyuan.com/uploads/images/articles/201904/15/1_1555264459_hwwzRqoAyX.png)

>如何提升链表的查询效率呢? 我们对链表建立一级索引层.每两个节点提取一个节点到上一级.图中的 down 表示 down 指针，指向下一级结点。

![跳表实现原理](https://api.zhanggaoyuan.com/uploads/images/articles/201904/15/1_1555264467_VmnwgITZSJ.png)
![跳表实现原理](https://api.zhanggaoyuan.com/uploads/images/articles/201904/15/1_1555264476_85UkzmWwjz.png)

![跳表实现原理](https://api.zhanggaoyuan.com/uploads/images/articles/201904/15/1_1555264488_ZCNI85qG89.png)


>这种链表加多级索引的结构，就是`跳表`

![跳表实现原理](https://api.zhanggaoyuan.com/uploads/images/articles/201904/15/1_1555264496_WX4kM3HP9K.png)

### 小结:
跳表采用空间换时间的设计思路,通过构建多级索引来提高查询的效率,实现了基于链表的`二分查找`.跳表是一种动态的数据结构,支持快速的插入.

原文链接：[https://www.zhanggaoyuan.com/article/4](https://www.zhanggaoyuan.com/article/4)