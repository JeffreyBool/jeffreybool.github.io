---
title: golang 接口深入浅出
tags:
  - golang
categories: golang
abbrlink: 285d17fb
date: 2020-07-28 15:17:26
---

## 目录

1. 接口介绍与定义
2. 空接口和类型断言
3. 指针接收和值接收区别
4. 接口嵌套
5. 课后作业

## 接口介绍和定义

接口定义了一个对象的行为规范

- 只定义规范，不实现
- 具体的对象需要实现规范的细节

### Go中接口定义

- type 接口名字 interface
- 接口里面是一组方法签名的集合

```go

type Animal interface { 
  Talk()
  Eat() int
  Run() 
}
```

### Go中接口的实现

- 一个对象只要包含接口中的所有方法，那么就实现了这个接口
- 接口类型的变量可以保存具体类型的实例

```go
package main

import (
	"fmt"
)

type Animal interface {
	Eat()
	Talk()
	Name() string
}

type Describle interface {
	Describle() string
}

type AdvanceAnimal interface {
	Animal
	Describle
}

type Dog struct {
}

func (d Dog) Eat() {
	fmt.Println("dog is eating")
}

func (d Dog) Talk() {
	fmt.Println("dog is talking")
}

func (d Dog) Name() string {
	fmt.Println("my name is dog")
	return "dog"
}

func (d Dog) Describle() string {
	fmt.Println("dog is a dog")
	return "dog is a dog"
}

func main() {
	var d Dog
	var a AdvanceAnimal

	a = d
	a.Describle()
	a.Eat()
	a.Talk()
	a.Name()
}
```

### 接口示例

一个公司需要计算所有职员的薪水，每个职员的薪水计算方式不同

```go
package main

import (
	"fmt"
)

type Employer interface {
	CalcSalary() float32
}

type Programer struct {
	name  string
	base  float32
	extra float32
}

func NewProgramer(name string, base float32, extra float32) *Programer {
	return &Programer{name: name, base: base, extra: extra}
}

func (p Programer) CalcSalary() float32 {
	return p.base
}

type Sale struct {
	name  string
	base  float32
	extra float32
}

func NewSale(name string, base float32, extra float32) *Sale {
	return &Sale{name: name, base: base, extra: extra}
}

func (s Sale) CalcSalary() float32 {
	return s.base + s.extra*s.base*0.5
}

func calcAll(e []Employer) float32 {
	var cost float32
	for _, v := range e {
		cost = cost + v.CalcSalary()
	}
	return cost
}

func main() {
	p1 := NewProgramer("搬砖1", 1500.0, 0)
	p2 := NewProgramer("搬砖1", 1500.0, 0)
	p3 := NewProgramer("搬砖1", 1500.0, 0)

	s1 := NewSale("销售1", 800.0, 2.5)
	s2 := NewSale("销售2", 800.0, 2.5)
	s3 := NewSale("销售3", 800.0, 2.5)

	var employList []Employer
	employList = append(employList, p1)
	employList = append(employList, p2)
	employList = append(employList, p3)

	employList = append(employList, s1)
	employList = append(employList, s2)
	employList = append(employList, s3)

	cost := calcAll(employList)
	fmt.Printf("这个月人力成本:%f\n", cost)
}
```

### 接口类型变量
`var a Animal`;那么a能够存储所有实现Animal接口的对象实例

### 空接口

- 空接口没有定义任何方法
- 所以任何类型都实现了空接口

```go
interface {}
```

## 空接口和类型断言

### 空接口

```go
package main

import (
	"fmt"
)

func describe(i interface{}) {
	fmt.Printf("Type = %T, value = %v\n", i, i)
}

func main() {
	s := "hello world"
	describe(s)

	i := 55
	describe(i)

	strt := struct {
		name string
	}{
		name: "JeffreyBool",
	}
	describe(strt)
}
```

### 类型断言

如何获取接口类型里面存储的具体的值？

```go
package main

import (
	"fmt"
)

func main() {
	var s interface{} = 56
	assert(s)
}

func assert(i interface{})  {
	s := i.(int)
	fmt.Println(s)
}
```

类型断言的坑

```go
package main

import (
	"fmt"
)

func main() {
	var s interface{} = "JeffreyBool"
	assert(s)
}

func assert(i interface{})  {
	s := i.(int) // 这里传递进来的如果不是 int 就会发生 panic
	fmt.Println(s)
}
```

上面的值如果不是 int 类型就会发生 panic 错误，如果要解决只需加上 `ok,v := 值.(类型)` 即可

```go
package main

import (
	"fmt"
)

func main() {
	var s interface{} = "JeffreyBool"
	assert(s)
}

func assert(i interface{})  {
	s,ok := i.(int) // 这里传递进来的如果不是 int 就会发生 panic
	fmt.Println(s,ok)
}
```

### type switch

```go
package main

import (
	"fmt"
)

func main() {
	findType("hello")
	findType(77)
	findType(89.88)
	findType(struct {
		name string
	}{
		name: "JeffreyBool",
	})
}

func findType(i interface{}) {
	switch v := i.(type) {
	case string:
		fmt.Printf("值为字符串类型，值:%s\n", v)
	case int:
		fmt.Printf("值为整数类型，值:%d\n", v)
	default:
		fmt.Printf("未知类型: %T, %v\n", v, v)
	}
}
```

### 指针接受

```go
package main

import (
	"fmt"
)

type Animal interface {
	Talk()
	Eat()
	Name() string
}

type Dog struct {
}

func (d *Dog) Talk() {
	fmt.Println("汪汪汪")
}

func (d *Dog) Eat() {
	fmt.Println("我在吃骨头")
}

func (d *Dog) Name() string {
	fmt.Println("我的名字叫旺财")
	return "旺财"
}

func main() {
	var a Animal
	var d Dog
	//a存的是一个值类型的Dog，那么调用a.Eat()，&Dog->Eat()
	//如果一个变量存储在接口类型的变量中之后，那么不能获取这个变量的地址
	a = d
	a.Eat()

	fmt.Printf("%T %v\n", a, a)
	var d1 *Dog = &Dog{}
	a = d1
	//*(&Dog).Eat()
	a.Eat()
	fmt.Printf("*Dog %T %v\n", a, a)
}
```

> 如果想要修改值，请使用指针类型接收

## 实现多接口

同一个类型实现多个接口

```go
type Animal interface {
	Talk()
	Eat()
	Name() string
}

type PuruDongWu interface {
	TaiSheng()
}

type Dog struct {
}

func (d Dog) Talk() {
	fmt.Println("汪汪汪")
}

func (d Dog) Eat() {
	fmt.Println("我在吃骨头")
}

func (d Dog) Name() string {
	fmt.Println("我的名字叫旺财")
	return "旺财"
}

func (d Dog) TaiSheng() {
	fmt.Println("狗是胎生的")
}
```

接口嵌套，和结构体嵌套类似

```go
type Animal interface {
	Eat()
	Talk()
	Name() string
}

type Describle interface {
	Describle() string
}

type AdvanceAnimal interface {
	Animal
	Describle
}
```

## 项目实战

1. 日志库需求分析 
2. 日志库接口设计 
3. 文件日志库开发 
4. Console日志开发 
5. 网络日志库开发 
6. 日志使用以及测试

### 日志库需求分析

- 日志库产生的背景
   * 程序运行是个黑盒
   * 而日志是程序运行的外在表现
   * 通过日志，可以知道程序的健康状态
- 日志打印级别设置
   * Debug级别:用来调试程序，日志最详细。对程序性能影响比较大。
   * Trace级别:用来追踪问题。
   * Info级别:打印程序运行过程中比较重要的信息，比如访问日志
   * Warn级别:警告日志，说明程序运行出现了潜在的问题
   * Error级别:错误日志，程序运行发生错误，但不影响程序运行。
   * Fatal级别:严重错误日志，发生的错误会导致程序退出
   
- 日志存储的位置
   * 直接输出到控制台
   * 打印到文件里
   * 直接打印到网络中，比如kafka
 
### 日志库接口设计 
 
- 为什么使用接口
   * 定义日志库的规范或者标准
   * 易于可扩展性
   * 利于程序的可维护性，不用关心内部实现
   * 数据输出切换方便
   
- 日志库设计
   * 打印各个level的日志
   * 设置级别
   * 构造函数
   
### 文件日志库实现
 
[项目代码](https://github.com/JeffreyBool/go-practice/tree/master/golang%E4%BB%8E%E5%85%A5%E9%97%A8%E5%88%B0%E7%B2%BE%E9%80%9A/listen9)
