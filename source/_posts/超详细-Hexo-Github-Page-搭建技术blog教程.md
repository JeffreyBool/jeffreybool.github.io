---
title: 超详细 Hexo + Github Page 搭建技术blog教程
tags:
  - hexo
  - github
abbrlink: d2b1ed72
date: 2020-06-05 16:22:27
---


# 超详细 Hexo + Github Page 搭建技术blog教程

## 前言
博客有第三方平台，也可以自建，比较早的有博客园、CSDN，近几年新兴的也比较多诸如：WordPress、segmentFault、简书、掘金、知乎专栏、Github Page 等等。

这次我要说的就是 Github Page + Hexo 搭建个人博客的方式！Github Page 是 Github 提供的一种免费的静态网页托管服务（所以想想免费的空间不用也挺浪费的哈哈哈），可以用来托管博客、项目官网等静态网页。支持 Jekyll、Hugo、Hexo 编译静态资源，这次我们的主角就是 Hexo 了，具体的内容下面在文章内介绍。

下面就开始吧~

## 准备环境
准备 node 和 git 环境，
首先，安装 NodeJS，因为 Hexo 是基于 Node.js 驱动的一款博客框架，相比起前面提到过的 Jekyll 框架更快更简洁，因为天*朝网络被墙的原因尝试过安装 Jekyll 失败而放弃了。
然后，安装 git，一个分布式版本控制系统，用于项目的版本控制管理，作者是 Linux 之父。如果 Git 还不熟悉可以参考廖雪峰大神的 Git 教程。

两个工具不同的平台安装方法有所不一样，可自行了解按步骤安装，这里不详述了。安装成功后打开git bash（Windowns）或者终端（Mac），下方中将统一称为命令行。
在命令行中输入相应命令验证是否成功，如果成功会有相应的版本号。

```bash
git version
node -v
npm -v
```

![超详细 Hexo + Github Page 搭建技术blog教程](https://imgkr.cn-bj.ufileos.com/a8f34ad7-050d-4a98-8317-1cd5f257df5c.png)



## 安装 Hexo
如果以上环境准备好了就可以使用 npm 开始安装 Hexo 了。也可查看 [Hexo](https://hexo.io/zh-cn/docs/) 的详细文档。
在命令行输入执行以下命令：

```bash
npm install -g hexo-cli
```

## 初始化项目

安装 Hexo 完成后，再执行下列命令，Hexo 将会在指定文件夹中新建所需要的文件。

```bash
hexo init my-blog
cd my-blog
npm install
```

新建完成后，指定文件夹的目录如下：

```tree
.
├── _config.yml # 网站的配置信息，您可以在此配置大部分的参数。 
├── package.json
├── scaffolds # 模版文件夹
├── source  # 资源文件夹，除 _posts 文件，其他以下划线_开头的文件或者文件夹不会被编译打包到public文件夹
|   ├── _drafts # 草稿文件
|   └── _posts # 文章Markdowm文件 
└── themes  # 主题文件夹
```

好了，如果上面的命令都没报错的话，就恭喜了，运行 `hexo s` 命令，其中 `s` 是 `server` 的缩写，在浏览器中输入 [http://localhost:4000](http://localhost:4000) 回车就可以预览效果了。

```bash
hexo s
```

以下是我本地的预览效果，更换了 [hexo-theme-matery](https://github.com/blinkfox/hexo-theme-matery) 主题的，默认不是这个主题。


![hexo-theme-matery](https://imgkr.cn-bj.ufileos.com/1382a18c-2ef6-4a0d-adb7-bf8940bf83bc.png)

![hexo-theme-matery](https://imgkr.cn-bj.ufileos.com/9e42cd4c-06ed-49bc-86e8-8708d00ac16a.png)

![hexo-theme-matery](https://imgkr.cn-bj.ufileos.com/7f0efde2-8916-4f23-b40e-77703b5b0ddc.png)

![hexo-theme-matery](https://imgkr.cn-bj.ufileos.com/aa310852-2aae-4aa2-9feb-b6a4e3d687bb.png)




至此，你本地的博客就已经搭建成功，接下来就是部署到 Github Page 了。

## 创建 github page

- 第一步创建`repository`
![repository](https://imgkr.cn-bj.ufileos.com/c4ba3fe9-ba06-4e17-a95b-c16260a2a9d7.png)


- 第二步输入你要申请的 github.io 域名
![github.io](https://imgkr.cn-bj.ufileos.com/39927eab-27df-46a4-a5dd-48ca08b9778a.png)



> 注意点来了，Github 仅能使用一个同名仓库的代码托管一个静态站点，这个网上很多教程没说到的。

## 第三步配置 github page
在建好的仓库右侧有个settings按钮，点击它，向下拉到GitHub Pages，你会看到有个网址，访问它，你将会惊奇的发现该项目已经被部署到网络上，能够通过外网来访问它，当然里面还很空什么东西都没有。 该地址就是你的博客默认地址，你也可以购买域名，将其换成你喜欢的地址。

![github page](https://imgkr.cn-bj.ufileos.com/b3e27327-9839-4c2c-bc7f-ab55e3c2609a.png)


## 生成 github ssh 
[参考文章](https://jeffreybool.github.io/2020/06/05/linux-fu-wu-qi-sheng-cheng-github-ssh/)

## 上传到github
如果你一切都配置好了，发布上传很容易，一句hexo d就搞定，当然关键还是你要把所有东西配置好。
首先，ssh key肯定要配置好。
其次，配置_config.yml中 有关deploy的部分：
正确写法：
```yml
deploy:
  type: git
  repository: git@github.com:JeffreyBool/jeffreybool.github.io.git
  branch: master
```

## 常用hexo命令

```bash
hexo new "postName" #新建文章
hexo new page "pageName" #新建页面
hexo generate #生成静态页面至public目录
hexo server #开启预览访问端口（默认端口4000，'ctrl + c'关闭server）
hexo deploy #部署到GitHub
hexo help  # 查看帮助
hexo version  #查看Hexo的版本
```

#### 缩写：

```bash
hexo n ==> hexo new
hexo g ==> hexo generate
hexo s ==> hexo server
hexo d ==> hexo deploy
```

#### 组合命令

```bash
hexo s -g # 生成并本地预览
hexo d -g # 生成并上传
```

# 未完结，后续继续更新

## 参考文章
[超详细Hexo+Github Page搭建技术博客教程【持续更新】](https://segmentfault.com/a/1190000017986794)
[使用hexo+github搭建免费个人博客详细教程](https://www.cnblogs.com/liuxianan/p/build-blog-website-by-hexo-github.html)
[使用hexo搭建github博客](https://www.jianshu.com/p/1bcad7700c46)