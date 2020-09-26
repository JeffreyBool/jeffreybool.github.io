---
title: Uber Go 语言编码规范中文版
top: true
categories: golang
tags: golang
abbrlink: 4a54ccfa
date: 2020-06-05 12:56:59
---

## **介绍**

英文原文标题是 [**Uber Go Style Guide**](https://github.com/uber-go/guide)，这里的 Style 是指在编码时遵从的一些约定。

这篇编程指南的初衷是更好的管理我们的代码，包括去编写什么样的代码，以及不要编写什么样的代码。我们希望通过这份编程指南，代码可以具有更好的维护性，同时能够让我们的开发同学更高效地编写 Go 语言代码。

这份编程指南最初由 [Prashant Varanasi](https://github.com/prashantv) 和 [Simon Newton](https://github.com/nomis52) 编写，旨在让其他同事快速地熟悉和编写 Go 程序。经过多年发展，现在的版本经过了多番修改和改进了。这是我们在 Uber 遵从的编程范式，但是很多都是可以通用的，如下是其他可以参考的链接：

-   [Effective Go](https://learnku.com/docs/effective-go)
-   [The Go common mistakes guide](https://github.com/golang/go/wiki/CodeReviewComments)

所有的提交代码都应该通过 `golint` 和 `go vet` 检测，建议在代码编辑器上面做如下设置：

-   保存的时候运行 `goimports`
-   使用 `golint` 和 `go vet` 去做错误检测。

你可以通过下面链接发现更多的 Go 编辑器的插件: [https://github.com/golang/go/wiki/IDEsAndTextEditorPlugins](https://github.com/golang/go/wiki/IDEsAndTextEditorPlugins)

## **编程指南**

### 指向 Interface 的指针

在我们日常使用中，基本上不会需要使用指向 interface 的指针。当我们将 interface 作为值传递的时候，底层数据就是指针。Interface 包括两方面：

-   一个包含 type 信息的指针
-   一个指向数据的指针

如果你想要修改底层的数据，那么你只能使用 pointer。

### 接收器 (receiver) 与接口

使用值接收器的方法既可以通过值调用，也可以通过指针调用。

```go
type S struct {
  data string
}

func (s S) Read() string {
  return s.data
}

func (s *S) Write(str string) {
  s.data = str
}

sVals := map[int]S{1: {"A"}}

// 你只能通过值调用 Read
sVals[1].Read()

// 这不能编译通过：
//  sVals[1].Write("test")

sPtrs := map[int]*S{1: {"A"}}

// 通过指针既可以调用 Read，也可以调用 Write 方法
sPtrs[1].Read()
sPtrs[1].Write("test")
```

同样，即使该方法具有值接收器，也可以通过指针来满足接口。

```go
type F interface {
  f()
}

type S1 struct{}

func (s S1) f() {}

type S2 struct{}

func (s *S2) f() {}

s1Val := S1{}
s1Ptr := &S1{}
s2Val := S2{}
s2Ptr := &S2{}

var i F
i = s1Val
i = s1Ptr
i = s2Ptr

//  下面代码无法通过编译。因为 s2Val 是一个值，而 S2 的 f 方法中没有使用值接收器
//   i = s2Val
```

Effective Go 中有一段关于 [pointers vs. values](https://learnku.com/docs/effective-go/method/6245#20ffd5) 的精彩讲解。

### 零值 Mutex 是有效的

零值 `sync.Mutex` 和 `sync.RWMutex` 是有效的。所以指向 mutex 的指针基本是不必要的。

**Bad**

```go
mu := new(sync.Mutex)
mu.Lock()
```

**Good**

```go
var mu sync.Mutex
mu.Lock()
```

如果你使用结构体（struct）指针，mutex 可以非指针形式作为结构体的组成字段，或者更好的方式是直接嵌入到结构体中。 如果是私有结构体类型或是要实现 Mutex 接口的类型，我们可以使用嵌入 mutex 的方法：

为私有类型或需要实现互斥接口的类型嵌入：

```go
type smap struct {
  sync.Mutex // 仅适用于非导出类型

  data map[string]string
}

func newSMap() *smap {
  return &smap{
    data: make(map[string]string),
  }
}

func (m *smap) Get(k string) string {
  m.Lock()
  defer m.Unlock()

  return m.data[k]
}
```

对于导出的类型，请使用专用字段：

```go
type SMap struct {
  mu sync.Mutex

  data map[string]string
}

func NewSMap() *SMap {
  return &SMap{
    data: make(map[string]string),
  }
}

func (m *SMap) Get(k string) string {
  m.mu.Lock()
  defer m.mu.Unlock()

  return m.data[k]
}
```

### 在边界处拷贝 Slices 和 Maps

slices 和 maps 包含了指向底层数据的指针，因此在需要复制它们时要特别注意。

#### 接收 Slices 和 Maps

请记住，当 map 或 slice 作为函数参数传入时，如果您存储了对它们的引用，则用户可以对其进行修改。

**Bad**

```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = trips
}

trips := ...
d1.SetTrips(trips)

// Did you mean to modify d1.trips?
trips[0] = ...
```

**Good**

```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}

trips := ...
d1.SetTrips(trips)

// We can now modify trips[0] without affecting d1.trips.
trips[0] = ...
```

#### slice 和 map 作为返回值

同样，请注意用户对暴露内部状态的 map 或 slice 的修改。

**Bad**

```go
type Stats struct {
  sync.Mutex

  counters map[string]int
}

// Snapshot 返回当前状态。
func (s *Stats) Snapshot() map[string]int {
  s.Lock()
  defer s.Unlock()

  return s.counters
}

// snapshot is no longer protected by the lock!
snapshot := stats.Snapshot()
```

**Good**

```go
type Stats struct {
  sync.Mutex

  counters map[string]int
}

func (s *Stats) Snapshot() map[string]int {
  s.Lock()
  defer s.Unlock()

  result := make(map[string]int, len(s.counters))
  for k, v := range s.counters {
    result[k] = v
  }
  return result
}

// snapshot 现在是一个拷贝
snapshot := stats.Snapshot()
```

### 使用 defer 做资源清理

使用 defer 释放资源，诸如文件和锁。

**Bad**

```go
p.Lock()
if p.count < 10 {
  p.Unlock()
  return p.count
}

p.count++
newCount := p.count
p.Unlock()

return newCount

// 当有多个 return 分支时，很容易遗忘 unlock
```

**Good**

```go
p.Lock()
defer p.Unlock()

if p.count < 10 {
  return p.count
}

p.count++
return p.count

// 可读性越佳
```

尽管使用 defer 会导致一定的性能开销，但是大部分情况下这个开销在你的整个链路上所占的比重往往是微乎其微，除非说真的是有非常高的性能需求。另外使用 defer 从可读性改进以及代码错误减少上来看，都是值得的。

### channel 的 size 最好是 1 或者是 unbuffered

在使用 channel 的时候，最好将 size 设置为 1 或者使用 unbuffered channel。其他 size 的 channel 往往都会引入更多的复杂度，需要更多考虑上下游的设计。

**Bad**

```go
// 应该足以满足任何情况！
c := make(chan int, 64)
```

**Good**

```go
// 大小：1
c := make(chan int, 1) // 或者
// 无缓冲 channel，大小为 0
c := make(chan int)
```

### 枚举变量应该从 1 开始

在 Go 语言中枚举值的声明典型方式是通过 `const` 和 `iota` 来声明。由于 0 是默认值，所以枚举值最好从一个非 0 值开始，比如 1。

**Bad**

```go
type Operation int

const (
  Add Operation = iota
  Subtract
  Multiply
)

// Add=0, Subtract=1, Multiply=2
```

**Good**

```go
type Operation int

const (
  Add Operation = iota + 1
  Subtract
  Multiply
)

// Add=1, Subtract=2, Multiply=3
```

有一种例外情况：0 值是预期的默认行为的时候，枚举值可以从 0 开始。

```go
type LogOutput int

const (
  LogToStdout LogOutput = iota
  LogToFile
  LogToRemote
)

// LogToStdout=0, LogToFile=1, LogToRemote=2
```

### 错误类型

Go 中有多种声明错误（Error) 的选项：

-   [`errors.New`](https://golang.org/pkg/errors/#New) 对于简单静态字符串的错误
-   [`fmt.Errorf`](https://golang.org/pkg/fmt/#Errorf) 用于格式化的错误字符串
-   实现 `Error()` 方法的自定义类型
-   用 [`"pkg/errors".Wrap`](https://godoc.org/github.com/pkg/errors#Wrap) 的 Wrapped errors

返回错误时，请考虑以下因素以确定最佳选择：

-   这是一个不需要额外信息的简单错误吗？如果是这样，[`errors.New`](https://golang.org/pkg/errors/#New) 足够了。
-   客户需要检测并处理此错误吗？如果是这样，则应使用自定义类型并实现该 `Error()` 方法。
-   您是否正在传播下游函数返回的错误？如果是这样，请查看本文后面有关错误包装 [section on error wrapping](https://github.com/xxjwxc/uber_go_guide_cn#%E9%94%99%E8%AF%AF%E5%8C%85%E8%A3%85 "Error-Wrapping") 部分的内容。
-   否则 [`fmt.Errorf`](https://golang.org/pkg/fmt/#Errorf) 就可以了。

如果客户端需要检测错误，并且您已使用创建了一个简单的错误 [`errors.New`](https://golang.org/pkg/errors/#New)，请使用一个错误变量。

**Bad**

```go
// package foo

func Open() error {
  return errors.New("could not open")
}

// package bar

func use() {
  if err := foo.Open(); err != nil {
    if err.Error() == "could not open" {
      // handle
    } else {
      panic("unknown error")
    }
  }
}
```

**Good**

```go
// package foo

var ErrCouldNotOpen = errors.New("could not open")

func Open() error {
  return ErrCouldNotOpen
}

// package bar

if err := foo.Open(); err != nil {
  if err == foo.ErrCouldNotOpen {
    // handle
  } else {
    panic("unknown error")
  }
}
```

如果您有可能需要客户端检测的错误，并且想向其中添加更多信息（例如，它不是静态字符串），则应使用自定义类型。

**Bad**

```go
func open(file string) error {
  return fmt.Errorf("file %q not found", file)
}

func use() {
  if err := open(); err != nil {
    if strings.Contains(err.Error(), "not found") {
      // handle
    } else {
      panic("unknown error")
    }
  }
}
```

**Good**

```go
type errNotFound struct {
  file string
}

func (e errNotFound) Error() string {
  return fmt.Sprintf("file %q not found", e.file)
}

func open(file string) error {
  return errNotFound{file: file}
}

func use() {
  if err := open(); err != nil {
    if _, ok := err.(errNotFound); ok {
      // handle
    } else {
      panic("unknown error")
    }
  }
}
```

直接导出自定义错误类型时要小心，因为它们已成为程序包公共 API 的一部分。最好公开匹配器功能以检查错误。

```go
// package foo

type errNotFound struct {
  file string
}

func (e errNotFound) Error() string {
  return fmt.Sprintf("file %q not found", e.file)
}

func IsNotFoundError(err error) bool {
  _, ok := err.(errNotFound)
  return ok
}

func Open(file string) error {
  return errNotFound{file: file}
}

// package bar

if err := foo.Open("foo"); err != nil {
  if foo.IsNotFoundError(err) {
    // handle
  } else {
    panic("unknown error")
  }
}
```

### 错误包装 (Error Wrapping)

一个（函数/方法）调用失败时，有三种主要的错误传播方式：

-   如果没有要添加的其他上下文，并且您想要维护原始错误类型，则返回原始错误。

-   添加上下文，使用 [`"pkg/errors".Wrap`](https://godoc.org/github.com/pkg/errors#Wrap) 以便错误消息提供更多上下文 ,[`"pkg/errors".Cause`](https://godoc.org/github.com/pkg/errors#Cause) 可用于提取原始错误。 Use fmt.Errorf if the callers do not need to detect or handle that specific error case.

-   如果调用者不需要检测或处理的特定错误情况，使用 [`fmt.Errorf`](https://golang.org/pkg/fmt/#Errorf)。

建议在可能的地方添加上下文，以使您获得诸如“调用服务 foo：连接被拒绝”之类的更有用的错误，而不是诸如“连接被拒绝”之类的模糊错误。

在将上下文添加到返回的错误时，请避免使用“failed to”之类的短语来保持上下文简洁，这些短语会陈述明显的内容，并随着错误在堆栈中的渗透而逐渐堆积：

**Bad**

```go
s, err := store.New()
if err != nil {
    return fmt.Errorf(
        "failed to create new store: %s", err)
}
```

**Good**

```go
s, err := store.New()
if err != nil {
    return fmt.Errorf(
        "new store: %s", err)
}
```

但是，一旦将错误发送到另一个系统，就应该明确消息是错误消息（例如使用`err`标记，或在日志中以”Failed”为前缀）。

另请参见 [Don't just check errors, handle them gracefully](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully). 不要只是检查错误，要优雅地处理错误。

### 类型转换失败处理

类型转换失败会导致进程 panic，所以对于类型转换，一定要使用 `!ok` 的范式来处理。

**Bad**

```go
t := i.(string)
```

**Good**

```go
t, ok := i.(string)
if !ok {
  // 优雅地处理错误
}
```

### 不要 panic

在生产环境中运行的代码必须避免出现 panic。panic 是 [cascading failures](https://en.wikipedia.org/wiki/Cascading_failure) 级联失败的主要根源 。如果发生错误，该函数必须返回错误，并允许调用方决定如何处理它。

**Bad**

```go
func foo(bar string) {
  if len(bar) == 0 {
    panic("bar must not be empty")
  }
  // ...
}

func main() {
  if len(os.Args) != 2 {
    fmt.Println("USAGE: foo <bar>")
    os.Exit(1)
  }
  foo(os.Args[1])
}
```

**Good**

```go
func foo(bar string) error {
  if len(bar) == 0
    return errors.New("bar must not be empty")
  }
  // ...
  return nil
}

func main() {
  if len(os.Args) != 2 {
    fmt.Println("USAGE: foo <bar>")
    os.Exit(1)
  }
  if err := foo(os.Args[1]); err != nil {
    panic(err)
  }
}
```

Panic/Recover 并不是一种 error 处理策略。仅当发生不可恢复的事情（例如：nil 引用）时，程序才必须 panic。程序初始化是一个例外：程序启动时应使程序中止的不良情况可能会引起 panic。

```go
var _statusTemplate = template.Must(template.New("name").Parse("_statusHTML"))
```

即使在测试代码中，也优先使用`t.Fatal`或者`t.FailNow`而不是 panic 来确保失败被标记。

**Bad**

```go
// func TestFoo(t *testing.T)

f, err := ioutil.TempFile("", "test")
if err != nil {
  panic("failed to set up test")
}
```

**Good**

```go
// func TestFoo(t *testing.T)

f, err := ioutil.TempFile("", "test")
if err != nil {
  t.Fatal("failed to set up test")
}
```

### 使用 [http://go.uber.org/atomic](http://go.uber.org/atomic)

使用 [sync/atomic](https://golang.org/pkg/sync/atomic/) 包的原子操作对原始类型 (`int32`, `int64`等）进行操作，因为很容易忘记使用原子操作来读取或修改变量。

[go.uber.org/atomic](https://godoc.org/go.uber.org/atomic) 通过隐藏基础类型为这些操作增加了类型安全性。此外，它包括一个方便的`atomic.Bool`类型。

这个是 Uber 内部对原生包 `sync/atomic` 的一种封装，隐藏了底层数据类型。

**Bad**

```go
type foo struct {
  running int32  // atomic
}

func (f* foo) start() {
  if atomic.SwapInt32(&f.running, 1) == 1 {
     // already running…
     return
  }
  // start the Foo
}

func (f *foo) isRunning() bool {
  return f.running == 1  // race!
}
```

**Good**

```go
type foo struct {
  running atomic.Bool
}

func (f *foo) start() {
  if f.running.Swap(true) {
     // already running…
     return
  }
  // start the Foo
}

func (f *foo) isRunning() bool {
  return f.running.Load()
}
```

### 避免可变全局变量

使用选择依赖注入方式避免改变全局变量。 既适用于函数指针又适用于其他值类型。

**Bad**

```go
// sign.go
var _timeNow = time.Now
func sign(msg string) string {
  now := _timeNow()
  return signWithTime(msg, now)
}
```

**Good**

```go
// sign.go
type signer struct {
  now func() time.Time
}
func newSigner() *signer {
  return &signer{
    now: time.Now,
  }
}
func (s *signer) Sign(msg string) string {
  now := s.now()
  return signWithTime(msg, now)
}
```

## **性能相关**

性能方面的特定准则只适用于高频场景。

### 类型转换时，使用 strconv 替换 fmt

当基本类型和 string 互转的时候，`strconv` 要比 `fmt` 快。

**Bad**

```go
for i := 0; i < b.N; i++ {
  s := fmt.Sprint(rand.Int())
}

// BenchmarkFmtSprint-4    143 ns/op    2 allocs/op
```

**Good**

```go
for i := 0; i < b.N; i++ {
  s := strconv.Itoa(rand.Int())
}

// BenchmarkStrconv-4    64.2 ns/op    1 allocs/op
```

### 避免字符串到字节的转换

不要反复从固定字符串创建字节 slice。相反，请执行一次转换并捕获结果。

**Bad**

```go
for i := 0; i < b.N; i++ {
  w.Write([]byte("Hello world"))
}

// BenchmarkBad-4   50000000   22.2 ns/op
```

**Good**

```go
data := []byte("Hello world")
for i := 0; i < b.N; i++ {
  w.Write(data)
}

// BenchmarkGood-4  500000000   3.25 ns/op
```

### 尽量初始化时指定 Map 容量

在尽可能的情况下，在使用 `make()` 初始化的时候提供容量信息

```source-go
make(map[T1]T2, hint)
```

为 `make()` 提供容量信息（hint）尝试在初始化时调整 map 大小， 这减少了在将元素添加到 map 时增长和分配的开销。 注意，map 不能保证分配 hint 个容量。因此，即使提供了容量，添加元素仍然可以进行分配。


**Bad**

`m` 是在没有大小提示的情况下创建的； 在运行时可能会有更多分配。

```go
m := make(map[string]os.FileInfo)

files, _ := ioutil.ReadDir("./files")
for _, f := range files {
    m[f.Name()] = f
}
```

**Good**

`m` 是有大小提示创建的；在运行时可能会有更少的分配。

```go
files, _ := ioutil.ReadDir("./files")

m := make(map[string]os.FileInfo, len(files))
for _, f := range files {
    m[f.Name()] = f
}
```

## **编程风格**

### 一致性

本文中概述的一些标准都是客观性的评估，是根据场景、上下文、或者主观性的判断；

但是最重要的是，**保持一致**.

一致性的代码更容易维护、是更合理的、需要更少的学习成本、并且随着新的约定出现或者出现错误后更容易迁移、更新、修复 bug

相反，一个单一的代码库会导致维护成本开销、不确定性和认知偏差。所有这些都会直接导致速度降低、 代码审查痛苦、而且增加 bug 数量

将这些标准应用于代码库时，建议在 package（或更大）级别进行更改，子包级别的应用程序通过将多个样式引入到同一代码中，违反了上述关注点。

### 相似的声明放在一组

Go 语言支持将相似的声明放在一个组内。

**Bad**

```go
import "a"
import "b"
```

**Good**

```go
import (
  "a"
  "b"
)
```

这同样适用于常量、变量和类型声明：

**Bad**

```go
const a = 1
const b = 2

var a = 1
var b = 2

type Area float64
type Volume float64
```

**Good**

```go
const (
  a = 1
  b = 2
)

var (
  a = 1
  b = 2
)

type (
  Area float64
  Volume float64
)
```

仅将相关的声明放在一组。不要将不相关的声明放在一组。

**Bad**

```go
type Operation int

const (
  Add Operation = iota + 1
  Subtract
  Multiply
  ENV_VAR = "MY_ENV"
)
```

**Good**

```go
type Operation int

const (
  Add Operation = iota + 1
  Subtract
  Multiply
)

const ENV_VAR = "MY_ENV"
```

分组使用的位置没有限制，例如：你可以在函数内部使用它们：

**Bad**

```go
func f() string {
  var red = color.New(0xff0000)
  var green = color.New(0x00ff00)
  var blue = color.New(0x0000ff)

  ...
}
```

**Good**

```go
func f() string {
  var (
    red   = color.New(0xff0000)
    green = color.New(0x00ff00)
    blue  = color.New(0x0000ff)
  )

  ...
}
```

### import 分组

导入应该分为两组：

-   标准库
-   其他库

默认情况下，这是 goimports 应用的分组。

**Bad**

```go
import (
  "fmt"
  "os"
  "go.uber.org/atomic"
  "golang.org/x/sync/errgroup"
)
```

**Good**

```go
import (
  "fmt"
  "os"

  "go.uber.org/atomic"
  "golang.org/x/sync/errgroup"
)
```

### 包名

当命名包时，请按下面规则选择一个名称：

-   全部小写。没有大写或下划线。
-   大多数使用命名导入的情况下，不需要重命名。
-   简短而简洁。请记住，在每个使用的地方都完整标识了该名称。
-   不用复数。例如`net/url`，而不是`net/urls`。
-   不要用“common”，“util”，“shared”或“lib”。这些是不好的，信息量不足的名称。

另请参阅 [Package Names](https://blog.golang.org/package-names) 和 [Go 包样式指南](https://rakyll.org/style-packages/).

### 函数名

我们遵循 Go 社区关于使用 [MixedCaps 作为函数名](https://learnku.com/docs/effective-go/naming-rules/6239#5b02ab) 的约定。有一个例外，为了对相关的测试用例进行分组，函数名可能包含下划线，如：`TestMyFunction_WhatIsBeingTested`。

### 导入别名

如果程序包名称与导入路径的最后一个元素不匹配，则必须使用导入别名。

```source-go
import (
  "net/http"

  client "example.com/client-go"
  trace "example.com/trace/v2"
)
```

在所有其他情况下，除非导入之间有直接冲突，否则应避免导入别名。

**Bad**

```go
import (
  "fmt"
  "os"

  nettrace "golang.net/x/trace"
)
```

**Good**

```go
import (
  "fmt"
  "os"
  "runtime/trace"

  nettrace "golang.net/x/trace"
)
```

### 函数分组与顺序

-   函数应按粗略的调用顺序排序。
-   同一文件中的函数应按接收者分组。

因此，导出的函数应先出现在文件中，放在`struct`, `const`, `var`定义的后面。

在定义类型之后，但在接收者的其余方法之前，可能会出现一个 `newXYZ()`/`NewXYZ()`

由于函数是按接收者分组的，因此普通工具函数应在文件末尾出现。

**Bad**

```go
func (s *something) Cost() {
  return calcCost(s.weights)
}

type something struct{ ... }

func calcCost(n int[]) int {...}

func (s *something) Stop() {...}

func newSomething() *something {
    return &something{}
}
```

**Good**

```go
type something struct{ ... }

func newSomething() *something {
    return &something{}
}

func (s *something) Cost() {
  return calcCost(s.weights)
}

func (s *something) Stop() {...}

func calcCost(n int[]) int {...}
```

### 减少嵌套

代码应通过尽可能先处理错误情况/特殊情况并尽早返回或继续循环来减少嵌套。减少嵌套多个级别的代码的代码量。

**Bad**

```go
for _, v := range data {
  if v.F1 == 1 {
    v = process(v)
    if err := v.Call(); err == nil {
      v.Send()
    } else {
      return err
    }
  } else {
    log.Printf("Invalid v: %v", v)
  }
}
```

**Good**

```go
for _, v := range data {
  if v.F1 != 1 {
    log.Printf("Invalid v: %v", v)
    continue
  }

  v = process(v)
  if err := v.Call(); err != nil {
    return err
  }
  v.Send()
}
```

### 不必要的 else

如果在 if 的两个分支中都设置了变量，则可以将其替换为单个 if。

**Bad**

```go
var a int
if b {
  a = 100
} else {
  a = 10
}
```

**Good**

```go
a := 10
if b {
  a = 100
}
```

### 顶层变量声明

在顶层，使用标准`var`关键字。请勿指定类型，除非它与表达式的类型不同。

**Bad**

```go
var _s string = F()

func F() string { return "A" }
```

**Good**

```go
var _s = F()
// 由于 F 已经明确了返回一个字符串类型，因此我们没有必要显式指定_s 的类型
// 还是那种类型

func F() string { return "A" }
```

如果表达式的类型与所需的类型不完全匹配，请指定类型。

```go
type myError struct{}

func (myError) Error() string { return "error" }

func F() myError { return myError{} }

var _e error = F()
// F 返回一个 myError 类型的实例，但是我们要 error 类型
```

### 对于未导出的顶层常量和变量，使用_作为前缀

在未导出的顶级`vars`和`consts`， 前面加上前缀_，以使它们在使用时明确表示它们是全局符号。

例外：未导出的错误值，应以`err`开头。

基本依据：顶级变量和常量具有包范围作用域。使用通用名称可能很容易在其他文件中意外使用错误的值。

**Bad**

```go
// foo.go

const (
  defaultPort = 8080
  defaultUser = "user"
)

// bar.go

func Bar() {
  defaultPort := 9090
  ...
  fmt.Println("Default port", defaultPort)

  // We will not see a compile error if the first line of
  // Bar() is deleted.
}
```

**Good**

```go
// foo.go

const (
  _defaultPort = 8080
  _defaultUser = "user"
)
```

### 结构体中的嵌入

嵌入式类型（例如 mutex）应位于结构体内的字段列表的顶部，并且必须有一个空行将嵌入式字段与常规字段分隔开。

**Bad**

```go
type Client struct {
  version int
  http.Client
}
```

**Good**

```go
type Client struct {
  http.Client

  version int
}
```

### 使用字段名初始化结构体

初始化结构体时，几乎始终应该指定字段名称。现在由 [`go vet`](https://golang.org/cmd/vet/) 强制执行。

**Bad**

```go
k := User{"John", "Doe", true}
```

**Good**

```go
k := User{
    FirstName: "John",
    LastName: "Doe",
    Admin: true,
}
```

例外：如果有 3 个或更少的字段，则可以在测试表中省略字段名称。

```source-go
tests := []struct{
  op Operation
  want string
}{
  {Add, "add"},
  {Subtract, "subtract"},
}
```

### 本地变量声明

如果将变量明确设置为某个值，则应使用短变量声明形式 (`:=`)。

**Bad**

```go
var s = "foo"
```

**Good**

```go
s := "foo"
```

但是，在某些情况下，var 使用关键字时默认值会更清晰。例如，声明空切片。

**Bad**

```go
func f(list []int) {
  filtered := []int{}
  for _, v := range list {
    if v > 10 {
      filtered = append(filtered, v)
    }
  }
}
```

**Good**

```go
func f(list []int) {
  var filtered []int
  for _, v := range list {
    if v > 10 {
      filtered = append(filtered, v)
    }
  }
}
```

### nil 是一个有效的 slice

`nil` 是一个有效的长度为 0 的 slice，这意味着，

-   您不应明确返回长度为零的切片。应该返回`nil` 来代替。

**Bad**

```go
if x == "" {
  return []int{}
}
```

**Good**

```go
if x == "" {
  return nil
}
```

- 要检查切片是否为空，请始终使用`len(s) == 0`。而非 `nil`。

**Bad**

```go
func isEmpty(s []string) bool {
  return s == nil
}
```

**Good**

```go
func isEmpty(s []string) bool {
  return len(s) == 0
}
```

- 零值切片（用`var`声明的切片）可立即使用，无需调用`make()`创建。

**Bad**

```go
nums := []int{}
// or, nums := make([]int)

if add1 {
  nums = append(nums, 1)
}

if add2 {
  nums = append(nums, 2)
}
```

**Good**

```go
var nums []int

if add1 {
  nums = append(nums, 1)
}

if add2 {
  nums = append(nums, 2)
}
```

### 小变量作用域

如果有可能，尽量缩小变量作用范围。除非它与减少嵌套的规则冲突。

**Bad**

```go
err := ioutil.WriteFile(name, data, 0644)
if err != nil {
 return err
}
```

**Good**

```go
if err := ioutil.WriteFile(name, data, 0644); err != nil {
 return err
}
```

如果需要在 if 之外使用函数调用的结果，则不应尝试缩小范围。

**Bad**

```go
if data, err := ioutil.ReadFile(name); err == nil {
  err = cfg.Decode(data)
  if err != nil {
    return err
  }

  fmt.Println(cfg)
  return nil
} else {
  return err
}
```

**Good**

```go
data, err := ioutil.ReadFile(name)
if err != nil {
   return err
}

if err := cfg.Decode(data); err != nil {
  return err
}

fmt.Println(cfg)
return nil
```

### 避免参数语义不明确(Avoid Naked Parameters)

函数调用中的`意义不明确的参数`可能会损害可读性。当参数名称的含义不明显时，请为参数添加 C 样式注释 (`/* ... */`)

**Bad**

```go
// func printInfo(name string, isLocal, done bool)

printInfo("foo", true, true)
```

**Good**

```go
// func printInfo(name string, isLocal, done bool)

printInfo("foo", true /* isLocal */, true /* done */)
```

对于上面的示例代码，还有一种更好的处理方式是将上面的 `bool` 类型换成自定义类型。将来，该参数可以支持不仅仅局限于两个状态（true/false）。

```go
type Region int

const (
  UnknownRegion Region = iota
  Local
)

type Status int

const (
  StatusReady = iota + 1
  StatusDone
  // Maybe we will have a StatusInProgress in the future.
)

func printInfo(name string, region Region, status Status)
```

### 使用原始字符串字面值，避免转义

Go 支持使用 [原始字符串字面值](https://golang.org/ref/spec#raw_string_lit)，也就是 <code>`</code> 来表示原生字符串，在需要转义的场景下，我们应该尽量使用这种方案来替换。

可以跨越多行并包含引号。使用这些字符串可以避免更难阅读的手工转义的字符串。

**Bad**

```go
wantError := "unknown name:.test."
```

**Good**

```go
wantError := `unknown error:"test"`
```

### 初始化 Struct 引用

在初始化结构引用时，请使用`&T{}`代替`new(T)`，以使其与结构体初始化一致。

**Bad**

```go
sval := T{Name: "foo"}

// inconsistent
sptr := new(T)
sptr.Name = "bar"
```

**Good**

```go
sval := T{Name: "foo"}

sptr := &T{Name: "bar"}
```

### 初始化 Maps

对于空 map 请使用 `make(..)` 初始化， 并且 map 是通过编程方式填充的。 这使得 map 初始化在表现上不同于声明，并且它还可以方便地在 make 后添加大小提示。

**Bad**

声明和初始化看起来非常相似的。

```go
var (
  // m1 读写安全;
  // m2 在写入时会 panic
  m1 = map[T1]T2{}
  m2 map[T1]T2
)
```

**Good**

声明和初始化看起来差别非常大。 

```go
var (
  // m1 读写安全;
  // m2 在写入时会 panic
  m1 = make(map[T1]T2)
  m2 map[T1]T2
)
```

### 字符串 string format

如果你为`Printf`-style 函数声明格式字符串，请将格式化字符串放在外面，并将其设置为`const`常量。

这有助于`go vet`对格式字符串执行静态分析。

**Bad**

```go
msg := "unexpected values %v, %v."
fmt.Printf(msg, 1, 2)
```

**Good**

```go
const msg = "unexpected values %v, %v."
fmt.Printf(msg, 1, 2)
```

### 命名 Printf 样式的函数

声明`Printf`-style 函数时，请确保`go vet`可以检测到它并检查格式字符串。

这意味着您应尽可能使用预定义的`Printf`-style 函数名称。`go vet`将默认检查这些。有关更多信息，请参见 [Printf 系列](https://golang.org/cmd/vet/#hdr-Printf_family)。

如果不能使用预定义的名称，请以 f 结束选择的名称：`Wrapf`，而不是`Wrap`。`go vet`可以要求检查特定的 Printf 样式名称，但名称必须以`f`结尾。

```go
$ go vet -printfuncs=wrapf,statusf
```

更多参考: [go vet: Printf family check](https://kuzminva.wordpress.com/2017/11/07/go-vet-printf-family-check/).

## **编程模式（Patterns）**

### 表驱动测试

当测试逻辑是重复的时候，通过 [subtests](https://blog.golang.org/subtests) 使用 table 驱动的方式编写 case 代码看上去会更简洁。

**Bad**

```go
// func TestSplitHostPort(t *testing.T)

host, port, err := net.SplitHostPort("192.0.2.0:8000")
require.NoError(t, err)
assert.Equal(t, "192.0.2.0", host)
assert.Equal(t, "8000", port)

host, port, err = net.SplitHostPort("192.0.2.0:http")
require.NoError(t, err)
assert.Equal(t, "192.0.2.0", host)
assert.Equal(t, "http", port)

host, port, err = net.SplitHostPort(":8000")
require.NoError(t, err)
assert.Equal(t, "", host)
assert.Equal(t, "8000", port)

host, port, err = net.SplitHostPort("1:8")
require.NoError(t, err)
assert.Equal(t, "1", host)
assert.Equal(t, "8", port)
```

**Good**

```go
// func TestSplitHostPort(t *testing.T)

tests := []struct{
  give     string
  wantHost string
  wantPort string
}{
  {
    give:     "192.0.2.0:8000",
    wantHost: "192.0.2.0",
    wantPort: "8000",
  },
  {
    give:     "192.0.2.0:http",
    wantHost: "192.0.2.0",
    wantPort: "http",
  },
  {
    give:     ":8000",
    wantHost: "",
    wantPort: "8000",
  },
  {
    give:     "1:8",
    wantHost: "1",
    wantPort: "8",
  },
}

for _, tt := range tests {
  t.Run(tt.give, func(t *testing.T) {
    host, port, err := net.SplitHostPort(tt.give)
    require.NoError(t, err)
    assert.Equal(t, tt.wantHost, host)
    assert.Equal(t, tt.wantPort, port)
  })
}
```

很明显，使用 test table 的方式在代码逻辑扩展的时候，比如新增 test case，都会显得更加的清晰。

我们遵循这样的约定：将结构体切片称为`tests`。 每个测试用例称为`tt`。此外，我们鼓励使用`give`和`want`前缀说明每个测试用例的输入和输出值。

```go
tests := []struct{
  give     string
  wantHost string
  wantPort string
}{
  // ...
}

for _, tt := range tests {
  // ...
}
```

### 功能选项

功能选项是一种模式，您可以在其中声明一个不透明 Option 类型，该类型在某些内部结构中记录信息。您接受这些选项的可变编号，并根据内部结构上的选项记录的全部信息采取行动。

将此模式用于您需要扩展的构造函数和其他公共 API 中的可选参数，尤其是在这些功能上已经具有三个或更多参数的情况下。

**Bad**

```go
// package db

func Connect(
  addr string,
  timeout time.Duration,
  caching bool,
) (*Connection, error) {
  // ...
}
```

必须始终提供缓存和记录器参数，即使用户希望使用默认值。

```go
db.Connect(addr, db.DefaultTimeout, db.DefaultCaching)
db.Connect(addr, newTimeout, db.DefaultCaching)
db.Connect(addr, db.DefaultTimeout, false /* caching */)
db.Connect(addr, newTimeout, false /* caching */)
```

**Good**

```go
// package db

type Option interface {
  // ...
}

func WithCache(c bool) Option {
  // ...
}

func WithLogger(log *zap.Logger) Option {
  // ...
}

// Open creates a connection.
func Open(
  addr string,
  opts ...Option,
) (*Connection, error) {
  // ...
}
```

只有在需要时才提供选项。

```source-go
db.Open(addr)
db.Open(addr, db.WithLogger(log))
db.Open(addr, db.WithCache(false))
db.Open(
  addr,
  db.WithCache(false),
  db.WithLogger(log),
)
```

我们建议实现此模式的方法是使用一个 `Option` 接口，该接口保存一个未导出的方法，在一个未导出的 `options` 结构上记录选项。

```go
type options struct {
  cache  bool
  logger *zap.Logger
}

type Option interface {
  apply(*options)
}

type cacheOption bool

func (c cacheOption) apply(opts *options) {
  opts.cache = bool(c)
}

func WithCache(c bool) Option {
  return cacheOption(c)
}

type loggerOption struct {
  Log *zap.Logger
}

func (l loggerOption) apply(opts *options) {
  opts.Logger = l.Log
}

func WithLogger(log *zap.Logger) Option {
  return loggerOption{Log: log}
}

// Open creates a connection.
func Open(
  addr string,
  opts ...Option,
) (*Connection, error) {
  options := options{
    cache:  defaultCache,
    logger: zap.NewNop(),
  }

  for _, o := range opts {
    o.apply(&options)
  }

  // ...
}
```

注意: 还有一种使用闭包实现这个模式的方法，但是我们相信上面的模式为作者提供了更多的灵活性，并且更容易对用户进行调试和测试。特别是，在不可能进行比较的情况下它允许在测试和模拟中对选项进行比较。此外，它还允许选项实现其他接口，包括 `fmt.Stringer`，允许用户读取选项的字符串表示形式。

还可以参考下面资料：

-   [Self-referential functions and the design of options](https://commandcenter.blogspot.com/2014/01/self-referential-functions-and-design.html)
-   [Functional options for friendly APIs](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis)

## **译者注**

> Uber 开源的这个文档给我印象最深的就是：保持代码简洁，并具有良好可读性。不得不说，相比于国内很多『代码能跑就完事了』这种写代码的态度，这篇文章或许可以给我们更多的启示和参考。

译文参考：

- https://github.com/xxjwxc/uber_go_guide_cn
- https://zhuanlan.zhihu.com/p/86410535


原文链接：[https://www.zhanggaoyuan.com/article/48](https://www.zhanggaoyuan.com/article/48)

