---
title: golang 面向对象编程
tags: golang
categories: golang
abbrlink: 804ed534
date: 2020-06-27 23:41:37
---

# golang 面向对象编程

## 目录
1. struct 声明和定义
2. struct 的内存布局以及构造函数
3. 匿名字段和 struct 嵌套
4. struct 与 tag 应用
5. 课后作业

## struct 声明和定义

go 中面向对象是通过 struct 来实现的，struct 是用户自定义的类型

```go
type User struct {
    Useraneme string
    Sex       string
    Age       int 
    Avatar    string
}
```
> 注意：`type` 是用来定义一种类型 

struct 初始化方法

```go
var user User
user.Age = 18
user.Username = "user01"
user.Sex = "男"
user.avatar = "https://www.zhanggaoyuan.com"
```
> 注意: 使用变量名 + "." + 字段名访问结构体中的字段

struct 初始化方法

```go
var user User = User{
 Username:"user01",
 Age:18,
 Sex:"男",
 Aratar:"https://www.zhanggaoyuan.com"
}
```

更简单的写法

```go
user := User {
 Username:"user01",
 Age:18,
 Sex:"男",
 Aratar:"https://www.zhanggaoyuan.com"
}
```

struct 初始化的默认值

```go
var user User
fmt.Printf("%#v\n",user)
```

struct 类型的指针

```go
var user *User = &User{}
fmt.Printf("%p %#v\n",user)
```

```go
var user *User = &User {
Username: "user01",
Age: 18,
Sex: “男”,
Avatar: “http://my.com/xxx.jpg",
}
```

```go
var user User = new(User)
user.Age = 18
user.Username = "user01"
user.Sex = "男"
user.Avatar = "http://my.com/xxx.jpg"
```

> 注意:&User{}和new(User) 本质上是⼀一样的，都是返回⼀一个
结构体的地址

## struct 内存布局

结构图的内存布局：占用一段连续的内存空间

![结构图的内存布局](http://cdn.zhanggaoyuan.com/article/20200629/H9EgcJ.png)

结构体没有构造函数，必要时需要自己实现

```
func NewUser(username,sex,aratar string,age int) *User {
  return &User{
    Username : username,
    Age: age,
    Sex: sex,
    Avatar: aratar,
  }
}
```

## 匿名字段和嵌套

匿名字段：即没有名字的字段

```go
type User struct{
   Username   string
   Sex        string
   Age        int 
   Avarar     string
}
```

```go
type User struct {
    Username  string
    Sex       string
    Age       int
    Avatar    string
    int 
    string
}
```

> 注意：匿名字段默认采用类型名作为字段名

结构体嵌套

```go
type Address struct {
    City           string
    Province       string
}
```


```go
type User struct {
   Username  string
   Sex       string
   Age       int
   Avatar    string
   address   Address
}
```

匿名结构体

```go
type Address struct {
   City      string
   Province  string
}
```

```go
type User struct {
   Username  string
   Sex       string
   Age       int
   AvatarUrl string
   Address
}
```

匿名结构体与继承

```go
type Animal struct {
   City           string
   Province       string
}
```


```go
type User struct {
   Username  string
   Sex       string
   Age       int
   AvatarUrl string
   Address
}
```

冲突解决

```go
type Address struct {
	City       string
	Province   string
	CreateTime string
}
```

```go
type Email struct {
	Account    string
	CreateTime string
}
```

```go
type User struct {
	Username string
	Sex      string
	Age      int
	Avatar   string
	Address
	Email
	CreateTime string
}
```

## 结构体与 `tag` 应用

字段可见性，大写表达可公开访问，小写表示私有

```go
type User struct {
	Username string
	Sex      string
	Age      int
	avatar   string
	CreateTime string
}
```

`tag` 是结构体的元信息，可以在运行的时候通过反射的机制读取出来

```go
type User struct {
	Username   string `json:"username"`
	Sex        string `json:"sex"`
	Age        int    `json:"age"`
	avatar     string
	CreateTime string `json:"create_time"`
}
```

> 字段类型后面，以反括号起来的 key-value 结构图的字符串，多个 `tag` 以逗号隔开

## 结构体的方法定义
和其他语⾔言不一样，Go的⽅法采⽤用另外一种方式实现

Go的方法是在函数前⾯面加上一个接受者，这样编译器器就知道这个⽅法属于哪个类型了

```go
type A struct {
}

func (a A) Test(s string) {

}
```
![结构体接受者](http://cdn.zhanggaoyuan.com/article/20200629/BIrD0c.png)


可以为当前包内定义的任何类型增加⽅方法

```go
type int Integer //Integer是int的别名

func (a Integer) Test(s string) {}
```

![结构体别名方法](http://cdn.zhanggaoyuan.com/article/20200629/Qe5Alf.png)

## 函数和⽅方法的区别

函数不不属于任何类型，⽅方法属于特定的类型


## 课后练习

1. 实现⼀一个简单的学⽣生管理理系统，每个学⽣生有分数、年年级、性别、名字等 字段，⽤用户可以在控制台添加学⽣生、修改学⽣生信息、打印所有学⽣生列列表
的功能。

```go
package main

type Student struct {
	Username string
	Sex      int
	Score    float32
	Grade    string
}

func NewStudent(username string, sex int, score float32, grade string) (stu *Student) {
	stu = &Student{
		Username: username,
		Sex:      sex,
		Score:    score,
		Grade:    grade,
	}
	return
}
```

```go
package main

import (
	"fmt"
)

func main() {
	var a, b, c int
	var d string
	fmt.Scan(&a)
	fmt.Scan(&b)
	fmt.Scan(&d)
	fmt.Scan(&c)
	fmt.Println(a, b, c, d)
}
```

```go
package main

import (
	"fmt"
	"os"
)

var (
	AllStudents []*Student
)

func showMenu() {
	fmt.Println("1. add student")
	fmt.Println("2. modify student")
	fmt.Println("3. show all student")
	fmt.Println("4. exited\n\n")
}

func inputStudent() *Student {

	var (
		username string
		sex      int
		grade    string
		score    float32
	)
	fmt.Println("please input username:")
	fmt.Scanf("%s\n", &username)
	fmt.Println("please input sex:[0|1]")
	fmt.Scanf("%d\n", &sex)
	fmt.Println("please input grade:[0-6]")
	fmt.Scanf("%s\n", &grade)
	fmt.Println("please input score:[0-100]")
	fmt.Scanf("%f\n", &score)

	stu := NewStudent(username, sex, score, grade)
	return stu
}

func AddStudent() {
	stu := inputStudent()
	for index, v := range AllStudents {
		if v.Username == stu.Username {
			fmt.Println("user %s success update\n\n", stu.Username)
			AllStudents[index] = stu
			return
		}
	}

	AllStudents = append(AllStudents, stu)
	fmt.Printf("user %s success insert\n\n", stu.Username)
}

func ModifyStudent() {

	stu := inputStudent()
	for index, v := range AllStudents {
		if v.Username == stu.Username {
			AllStudents[index] = stu
			fmt.Printf("user %s success update\n\n", stu.Username)
			return
		}
	}
	fmt.Printf("user %s is not found\n", stu.Username)
}

func ShowAllStudent() {

	for _, v := range AllStudents {
		fmt.Printf("user:%s info:%#v\n", v.Username, v)
	}
	fmt.Println()
}

func main() {
	for {
		showMenu()
		var sel int
		fmt.Scanf("%d\n", &sel)
		switch sel {
		case 1:
			AddStudent()
		case 2:
			ModifyStudent()
		case 3:
			ShowAllStudent()
		case 4:
			os.Exit(0)
		}
	}
}
```


对应的 github [地址](https://github.com/JeffreyBool/go-practice/tree/master/golang%E4%BB%8E%E5%85%A5%E9%97%A8%E5%88%B0%E7%B2%BE%E9%80%9A/listen6)
