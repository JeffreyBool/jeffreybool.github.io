---
title: golang 反射使用加实战 ini配置文件解析
tags:
  - golang
categories: golang
abbrlink: 2e6584bd
date: 2020-07-28 15:18:14
---

## 变量介绍

- 类型信息，这部分是元信息，是预先定义好的
- 值类型，这部分是程序运行过程中，动态改变的

![变量介绍](http://cdn.zhanggaoyuan.com/article/20200727/lVYqDR.png)

## 反射介绍

反射与空接口

- 空接口可以存储任何类型的变量
- 那么给你一个空接口，怎么获取里面存储的内容
- 在运行时动态的获取一个变量的类型信息和值信息，就叫反射

怎么类型和详细信息

- 内置包： `reflect`
- 获取类型信息： `reflectTypeOf`
- 获取值信息： `reflect.ValueOf`

基本数据类型分析

```go
package main

import (
	"fmt"
	"reflect"
)

func main() {
	var x float64 = 3.4
	reflectExample(x)
	reflectValue(x)
	reflectSetValue(&x)
	fmt.Printf("x value is %v\n", x)
	var b *int = new(int)
	*b = 100
	reflectSetValue(*b)
}

func reflectExample(a interface{}) {
	t := reflect.TypeOf(a)
	fmt.Printf("type of a is:%v\n", t)
	switch t.Kind() {
	case reflect.Int64:
		fmt.Printf("a is Int64\n")
	case reflect.Float64:
		fmt.Printf("a is Float64\n")
	case reflect.Ptr:
		fmt.Printf("a is Ptr\n")
	}
}

func reflectValue(a interface{}) {
	v := reflect.ValueOf(a)
	switch v.Kind() {
	case reflect.Int64:
		fmt.Printf("a is int64, store value is:%d\n", v.Int())
	case reflect.Float64:
		fmt.Printf("a is float64, store value is:%f\n", v.Float())
	}
}

func reflectSetValue(a interface{})  {
	v := reflect.ValueOf(a)
	switch v.Kind() {
	case reflect.Int64:
		v.SetInt(100)
		fmt.Printf("a is int64, store value is:%d\n", v.Int())
	case reflect.Float64:
		v.SetFloat(6.8)
		fmt.Printf("a is float64, store value is:%f\n", v.Float())
	case reflect.Ptr:
		fmt.Printf("set a to 6.8\n")
		v.Elem().SetFloat(6.8)
	default:
		fmt.Printf("default switch\n")
	}
}
```

`Type.Kind()`, 获取变量类型

```go
func reflectExample(a interface{}) {
	t := reflect.TypeOf(a)
	fmt.Printf("type of a is:%v\n", t)
	switch t.Kind() {
	case reflect.Int64:
		fmt.Printf("a is Int64\n")
	case reflect.Float64:
		fmt.Printf("a is Float64\n")
	case reflect.Ptr:
		fmt.Printf("a is Ptr\n")
	}
}
```

`Kind` 类型定义常量

```go
// A Kind represents the specific kind of type that a Type represents.
// The zero Kind is not a valid kind.
type Kind uint

const (
	Invalid Kind = iota
	Bool
	Int
	Int8
	Int16
	Int32
	Int64
	Uint
	Uint8
	Uint16
	Uint32
	Uint64
	Uintptr
	Float32
	Float64
	Complex64
	Complex128
	Array
	Chan
	Func
	Interface
	Map
	Ptr
	Slice
	String
	Struct
	UnsafePointer
)
```

`reflect.ValueOf`, 获取变量的值相关信息

```go
  var x float64 = 3.4
  v := reflect.ValueOf(x)
  
  // 和 reflect.TypeOf  功能是一样的
  fmt.Println("type:",v.Type())
  fmt.Println("kind is float64:",v.Kind() == reflect.Float64)
  fmt.Println("value:",v.Float())
```

通过反射设置变量的值

```go
func reflectSetValue(a interface{})  {
	v := reflect.ValueOf(a)
	switch v.Kind() {
	case reflect.Int64:
		v.SetInt(100)
		fmt.Printf("a is int64, store value is:%d\n", v.Int())
	case reflect.Float64:
		v.SetFloat(6.8)
		fmt.Printf("a is float64, store value is:%f\n", v.Float())
	case reflect.Ptr:
		fmt.Printf("set a to 6.8\n")
		v.Elem().SetFloat(6.8)
	default:
		fmt.Printf("default switch\n")
	}
}
```

> 这里需要传递地址进去才能修改值，不传地址的话，改变的是拷贝变量的值，所以在 reflect 包会发生 panic

## 结构体反射

获取结构体相关信息

```go
package main

import (
	"fmt"
	"reflect"
)

type Student struct {
	Name  string
	Sex   int
	Age   int
	Score float32
}

func main() {
	var s Student
	v := reflect.ValueOf(s)
	t := v.Type()

	switch t.Kind() {
	case reflect.Int64:
		fmt.Printf("s is int64\n")
	case reflect.Float32:
		fmt.Printf("s is int64\n")
	case reflect.Struct:
		fmt.Printf("s is struct\n")
		fmt.Printf("field num of s is %d\n", v.NumField())
		for i := 0; i < v.NumField(); i++ {
			field := v.Field(i)
			fmt.Printf("name:%s type:%v value:%v\n",
				t.Field(i).Name, field.Type().Kind(), field.Interface())
		}
	default:
		fmt.Printf("default\n")
	}
}
```

设置结构体相关字段的值

```go
package main

import (
	"reflect"

	"fmt"
)

type Student struct {
	Name  string
	Sex   int
	Age   int
	Score float32
}

func main() {
	var s Student
	v := reflect.ValueOf(&s)
	v.Elem().Field(0).SetString("张高元")
	v.Elem().FieldByName("Sex").SetInt(1)
	v.Elem().FieldByName("Age").SetInt(18)
	v.Elem().FieldByName("Score").SetFloat(99.2)

	fmt.Printf("s：%#v\n", s)
}
```

获取结构体的方法信息

```go
package main

import (
	"fmt"
	"reflect"
)

type Student struct {
	Name  string
	Sex   int
	Age   int
	Score float32
}

func (s *Student) SetName(name string) {
	s.Name = name
}

func (s *Student) Print() {
	fmt.Printf("通过反射进行调用:%#v\n", s)
}

func main() {
	var s Student
	s.SetName("xxxx")
	v := reflect.ValueOf(&s)
	t := v.Type()
	fmt.Printf("struct student have %d methods\n", t.NumMethod())
	for i := 0; i < t.NumMethod(); i++ {
		method := t.Method(i)
		fmt.Printf("struct %d method, name:%s type:%v\n", i, method.Name, method.Type)
	}
}
```

调用结构体中的方法

```go
package main

import (
	"fmt"
	"reflect"
)

type Student struct {
	Name  string
	Sex   int
	Age   int
	Score float32
}

func (s *Student) SetName(name string) {
	s.Name = name
}

func (s *Student) Print() {
	fmt.Printf("通过反射进行调用:%#v\n", s)
}

func main() {
	var s Student
	s.SetName("xxxx")
	v := reflect.ValueOf(&s)
	t := v.Type()
	fmt.Printf("struct student have %d methods\n", t.NumMethod())
	for i := 0; i < t.NumMethod(); i++ {
		method := t.Method(i)
		fmt.Printf("struct %d method, name:%s type:%v\n", i, method.Name, method.Type)
	}

	//通过reflect.Value获取对应的方法并调用
	m1 := v.MethodByName("Print")
	var args []reflect.Value
	m1.Call(args)

	m2 := v.MethodByName("SetName")
	var args2 []reflect.Value
	name := "stu01"
	nameVal := reflect.ValueOf(name)
	args2 = append(args2, nameVal)
	m2.Call(args2)
	m1.Call(args)
}
```

获取结构体中的 `tag` 信息

```go
package main

import (
	"fmt"
	"reflect"
)

type Student struct {
	Name  string `json:"name" db:"name"`
	Sex   int
	Age   int
	Score float32
}

func (s *Student) SetName(name string) {
	s.Name = name
}

func (s *Student) Print() {
	fmt.Printf("通过反射进行调用:%#v\n", s)
}

func main() {
	var s Student
	s.SetName("xxx")
	v := reflect.ValueOf(&s)
	t := v.Type()
	field0 := t.Elem().Field(0)
	fmt.Printf("tag json=%s\n", field0.Tag.Get("json"))
	fmt.Printf("tag db=%s\n", field0.Tag.Get("db"))
}
```

## 反射总结以及应用场景

在运行时动态的获取一个变量的类型信息和值信息

### 应用场景
  
- 序列化和反序列化，比如 json、protobuf  等各种数据协议
- 各种数据库的 ORM， 比如 gorm、sqlx 等数据库中间件
- 配置文件解析相关的库，比如yaml、ini

> 以上所有场景我们都不知道具体的类型，所以要用反射

[项目实战](https://github.com/JeffreyBool/go-practice/tree/master/golang%E4%BB%8E%E5%85%A5%E9%97%A8%E5%88%B0%E7%B2%BE%E9%80%9A/listen10)

