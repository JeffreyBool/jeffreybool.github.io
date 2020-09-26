---
title: golang map 类型
tags: golang
categories: golang
abbrlink: cf91f0fa
date: 2020-06-27 17:46:59
---

## code

1. map 循环

```go
package main

import (
	"fmt"
	"math/rand"
	"time"
)

func main() {
	rand.Seed(time.Now().UnixNano())

	var a map[string]int = make(map[string]int, 1024)

	for i := 0; i < 128; i++ {
		key := fmt.Sprintf("stu%d", i)
		value := rand.Intn(1000)
		a[key] = value
	}

	for key, value := range a {
		fmt.Printf("map[%s]=%d\n", key, value)
	}
}

```

2. map拷贝

```go
package main

import (
	"fmt"
)

func modify(a map[string]int) {
	a["modify001"] = 1000
}

func main() {
	var a map[string]int
	fmt.Printf("a:%v\n", a)
	// a["stu01"] = 100 # map 没有进行初始化，会发生 panic

	a = make(map[string]int, 16)
	a["stu01"] = 1000
	a["stu02"] = 1000
	a["stu02"] = 1000
	a["stu03"] = 1000
	fmt.Printf("a=%#v\n", a)

	b := a
	b["stu03"] = 2000
	fmt.Printf("after modify a:%v\n", a)
	modify(a)
	fmt.Printf("after modify a:%v\n", a)
}
```

3. map 删除

```go
package main

import (
	"fmt"
)

func main() {
	var a map[string]int
	fmt.Printf("a:%v\n", a)
	//a["stu01"] = 100
	a = make(map[string]int, 16)
	fmt.Printf("a=%v\n", a)
	a["stu01"] = 1000
	a["stu02"] = 1000
	a["stu03"] = 1000
	fmt.Printf("a=%#v\n", a)
	delete(a, "stu02")
	fmt.Printf("a=%#v\n", a)

	for key, _ := range a {
		delete(a, key)
	}
	fmt.Printf("after delete a=%#v\n", a)
}
```

4. 判断 map 是否存在

```go
package main

import (
	"fmt"
)

func main() {
	var a map[string]int

	a = make(map[string]int, 16)
	a["stu01"] = 1000
	a["stu02"] = 1000
	a["stu03"] = 1000
	fmt.Printf("a=%#v\n", a)

	var (
		result int
		ok     bool
	)
	result, ok = a["stu03"]
	if !ok {
		fmt.Printf("key %s is not exist\n", "stu03")
	} else {
		fmt.Printf("key %s is %d\n", "stu03", result)
	}
}
```

5. map 初始化

```go
package main

import (
	"fmt"
)

func main() {
	var a map[string]int = map[string]int{
		"stu01": 100,
		"stu02": 2000,
		"stu03": 300,
	}

	fmt.Println(a)
	a["stu01"] = 88888
	a["stu04"] = 38333
	fmt.Println(a)

	var key string = "stu04"
	fmt.Printf("the value of  key[%s] is :%d\n", key, a[key])
}
```

6. nil map

```go
package main

import (
	"fmt"
)

func main() {
	var a map[string]int
	fmt.Printf("a:%v\n",a)

	a = make(map[string]int,16)
	a["stu01"] = 1000
	a["stu02"] = 2000
	a["stu03"] = 3000
	fmt.Printf("a=%#v\n",a)
}
```

7. map slice

```go
package main

import (
	"fmt"
	"math/rand"
	"time"
)

func mapSlice() {
	rand.Seed(time.Now().UnixNano())
	var s map[string][]int
	s = make(map[string][]int, 16)
	key := "stu01"
	value, ok := s[key]
	if !ok {
		s[key] = make([]int, 0, 16)
		value = s[key]
	}
	value = append(value, 100)
	value = append(value, 200)
	value = append(value, 300)
	s[key] = value
	fmt.Printf("map:%v\n", s)
}

func sliceMap() {
	rand.Seed(time.Now().UnixNano())
	var s []map[string]int
	s = make([]map[string]int, 5, 16)
	for index, val := range s {
		fmt.Printf("slice[%d]=%v\n", index, val)
	}

	fmt.Println()
	s[0] = make(map[string]int, 16)
	s[0]["stu01"] = 1000
	s[0]["stu02"] = 1000
	s[0]["stu03"] = 1000
}

func main() {
	mapSlice()
	sliceMap()
}

```

8. map sort

```go
package main

import (
	"fmt"
	"math/rand"
	"sort"
	"time"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	var a map[string]int = make(map[string]int,1024)

	for i := 0; i < 128; i++ {
		key := fmt.Sprintf("stu%d", i)
		value := rand.Intn(1000)
		a[key] = value
	}

	var keys []string = make([]string, 0, 128)
	for key,_ := range a {
		//fmt.Printf("map[%s]=%d\n",key,value)
		keys = append(keys,key)
	}
	sort.Strings(keys)
	for _,value := range keys {
		fmt.Printf("key:%s val:%d\n", value, a[value])
	}
}
```

## 课后练习

1. 写一个程序，统计一个字符串每个单词出现的次数。比如： s = "how do you do", 输出 how = 1 do = 2 you = 1

```go
package main

import (
	"fmt"
	"strings"
)

func statWordCount(str string) (result map[string]int) {
	words := strings.Split(str, " ")
	result = make(map[string]int, len(words))
	for _, v := range words {
		count, ok := result[v]
		if !ok {
			result[v] = 1
		} else {
			result[v] = count + 1
		}
	}
	return result
}

func main() {
	var str = "how do you do ? do you like me ?"
	result := statWordCount(str)
	fmt.Printf("result:%#v\n", result)
}
```

2. 写一个，实现学生信息的存储，学生有 ID 、年龄、分数等信息。需要非常方便的用过 ID 查找到对应的学生的信息。

```go
package main

import (
	"fmt"
	"math/rand"
)

func testInterface() {
	var a interface{}
	var b int = 100
	var c float32 = 1.2
	var d string = "hello"

	a = b
	fmt.Printf("a=%v\n", a)

	a = c
	fmt.Printf("a=%v\n", a)

	a = d
	fmt.Printf("a=%v\n", a)
}

func studentStore() {
	var stuMap map[int]map[string]interface{}
	stuMap = make(map[int]map[string]interface{}, 16)
	//插入学生id=1，姓名=stu01, 分数=78.2, 年龄= 18
	var id = 1
	var name = "stu01"
	var score = 78.2
	var age = 18

	value, ok := stuMap[id]
	if !ok {
		value = make(map[string]interface{}, 8)
	}

	value["name"] = name
	value["id"] = id
	value["score"] = score
	value["age"] = age
	stuMap[id] = value

	fmt.Printf("stuMap:%#v\n", stuMap)

	for i := 0; i < 10; i++ {
		value, ok := stuMap[i]
		if !ok {
			value = make(map[string]interface{}, 8)
		}

		value["name"] = fmt.Sprintf("stu%d", i)
		value["id"] = i
		value["score"] = rand.Float32() * 100.0
		value["age"] = rand.Intn(100)
		stuMap[i] = value
	}

	fmt.Println()
	for k, v := range stuMap {
		fmt.Printf("id=%d stu info=%#v\n", k, v)
	}
}

func main() {
	//testInterface()
	studentStore()
}

```
