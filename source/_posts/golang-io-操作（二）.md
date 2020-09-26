---
title: golang io 操作（二）
tags: golang
categories: golang
abbrlink: 2514146f
date: 2020-07-07 22:31:47
---

# golang io (二) 操作

## 目录
1. 文件打开和读写
2. 读取压缩文件
3. bufio 原理和 cat 命令实现
4. fefer 详解
5. 课后作业

## 文件读写

文件是存储在外部介质上的数据

- 文件分类：文本文件和二进制文件
- 文件存取方式：随机存取和顺序存放

### 文件打开

```go
package main
import (
  "bufio"
  "fmt"
  "io"
  "os"
)
func main() {
  //只读的方式打开
  inputFile, err := os.Open("input.dat")
  
  if err != nil {
    fmt.Printf("open file err:%v\n", err)
    return
  }
  defer inputFile.Close()
}
```

### 文件读取

> file.Read和file.ReadAt。读到文件末尾返回 `io.EOF`

```go
package main
import (
"bufio"
"fmt"
"io"
"os"
)
func main() {
//只读的方式打开
inputFile, err := os.Open("input.dat")
if err != nil {
fmt.Printf("open file err:%v\n", err)
return
} 
var buf[128]byte
inputFile.Read(buf[:])
defer inputFile.Close()
}
```

bufio 原理

![bufio 原理](http://cdn.zhanggaoyuan.com/article/20200706/vJHigh.png)

bufio 读取文件

```go
package main
import (
"bufio"
"fmt"
"io"
"os"
)
func main() {
inputFile, err := os.Open("input.dat")
if err != nil {
fmt.Printf("open file err:%v\n", err)
return
}
defer inputFile.Close()
inputReader := bufio.NewReader(inputFile)
for {
inputString, readerError := inputReader.ReadString('\n')
if readerError == io.EOF {
return
}
fmt.Printf("The input was: %s", inputString)
}
}
```

读取整个文件实例

```go
package main
import (
"fmt"
"io/ioutil"
"os"
)
func main() {
inputFile := "products.txt"
outputFile := "products_copy.txt"
buf, err := ioutil.ReadFile(inputFile)
if err != nil {
fmt.Fprintf(os.Stderr, "File Error: %s\n", err)
return
}
fmt.Printf("%s\n", string(buf))
}
```

读取压缩文件示例

```go
package main
import (
"bufio"
"compress/gzip"
"fmt"
"os"
)
func main() {
fName := "MyFile.gz"
var r *bufio.Reader
fi, err := os.Open(fName)
if err != nil {
fmt.Fprintf(os.Stderr, "%v, Can’t open %s: error: %s\n", os.Args[0], fName, err)
os.Exit(1)
}
fz, err := gzip.NewReader(fi)
if err != nil {
fmt.Fprintf(os.Stderr, "open gzip failed, err: %v\n", err)
return
}
r = bufio.NewReader(fz)
for {
line, err := r.ReadString('\n')
if err != nil {
fmt.Println("Done reading file")
os.Exit(0)
}
fmt.Println(line)
}
}
```

### 文件写入
`os.OpenFile("output.dat", os.O_WRONLY|os.O_CREATE, 0666)`

// 第二个参数：文件打开模式,第三个参数：权限控制

|  打开模式   | 权限控制  |
| ---------- |  -------|
| `os.O_WRONLY` 只写  | `r` 004 |
| `os.O_CREATE` 创建文件 | `w` 002 |
| `os.O_RDONLY` 只读 | `x` 001 |
| `os.O_RDWR` 读写 |  |
| `os.O_TRUNC` 清空 |  |
| `os.O_APPEND` 追加 |  |

文件写入示例

- `file.Write()`
- `file.WriteAt`
- `file.WriteString()`

```go
package main
import (
  "bufio"
  "fmt"
  "os"
)
func main() {
  outputFile, outputError := os.OpenFile("output.dat", 
  os.O_WRONLY|os.O_CREATE, 0666)
  if outputError != nil {
    fmt.Printf("An error occurred with file creation\n")
    return
  }
  str := “hello world”
  outputFile.Write([]byte(str))
  defer outputFile.Close()
}
```

```go
package main
import (
  "bufio"
  "fmt"
  "os"
)
func main() {
  outputFile, outputError := os.OpenFile("output.dat", os.O_WRONLY|os.O_CREATE, 0666)
  if outputError != nil {
    fmt.Printf("An error occurred with file creation\n")
    return
  }
  defer outputFile.Close()
  outputWriter := bufio.NewWriter(outputFile)
  outputString := "hello world!\n"
  
  for i := 0; i < 10; i++ {
    outputWriter.WriteString(outputString)
  }
  outputWriter.Flush()
}
```

写入整个文件示例

```go
package main
import (
  "fmt"
  "io/ioutil"
  "os"
)
func main() {
  inputFile := "products.txt"
  outputFile := "products_copy.txt"
  buf, err := ioutil.ReadFile(inputFile)
  if err != nil {
    fmt.Fprintf(os.Stderr, "File Error: %s\n", err)
    return
  }
  
  fmt.Printf("%s\n", string(buf))
  err = ioutil.WriteFile(outputFile, buf, 0x644)
  if err != nil {
    panic(err.Error())
  }
}
```

拷贝文件

```go
package main
import (
  "fmt"
  "io"
  "os"
)

func main() {
  CopyFile("target.txt", "source.txt")
  fmt.Println("Copy done!")
}

func CopyFile(dstName, srcName string) (written int64, err error) {
  src, err := os.Open(srcName)
  if err != nil {
    return
  }
  
  defer src.Close()
  dst, err := os.OpenFile(dstName, os.O_WRONLY|os.O_CREATE, 0644)
  if err != nil {
    return
  }
  
  defer dst.Close()
  return io.Copy(dst, src)
}
```

cat 命令实现

```go
package main
import (
  "bufio"
  "flag"
  "fmt"
  "io"
  "os"
)

func cat(r *bufio.Reader) {
  for {
    buf, err := r.ReadBytes('\n')
    if err == io.EOF {
      break
    }
    fmt.Fprintf(os.Stdout, "%s", buf)
    return
  }
}

func main() {
  flag.Parse()
  if flag.NArg() == 0 {
    cat(bufio.NewReader(os.Stdin))
  }
  
  for i := 0; i < flag.NArg(); i++ {
    f, err := os.Open(flag.Arg(i))
    if err != nil {
      fmt.Fprintf(os.Stderr, "%s:error reading from %s: %s\n",
      os.Args[0], flag.Arg(i), err.Error())
      continue
  }
  cat(bufio.NewReader(f))
  }
}
```

defer原理分析

![rWIOa3](http://cdn.zhanggaoyuan.com/article/20200707/rWIOa3.png)
![DpfY43](http://cdn.zhanggaoyuan.com/article/20200707/DpfY43.png)

defer案例

```go
package main

import (
	"fmt"
)

func testA() int  {
	x := 5
	defer func() {
		x += 1
	}()
	return x
}

func testB() (x int) {
	defer func() {
		x += 1
	}()
	return 5
}

func testC() (y int) {
	x := 5
	defer func() {
		x += 1
	}()
	return x
}

func testD() (x int) {
	defer func(x int) {
		x += 1
	}(x)
	return 5
}

func main() {
	fmt.Println(testA())
	fmt.Println(testB())
	fmt.Println(testC())
	fmt.Println(testD())
}
```

## 课后练习

实现一个类似 linux的tree 命令，输入tree.exe能够以树状的形式当前目录下所有文件.

```go
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/urfave/cli"
)

/*
!---listen16
|    |----employee
|    |    |----employee.exe
|    |    |----main.go
|    |----empty_interface
|    |    |----empty_interface.exe
|    |    |----main.go
|    |----homework
|    |    |----tree
|    |    |    |----main.go
|    |    |    |----tree.exe
|    |----interface_nest
|    |    |----interface_nest.exe
|    |    |----main.go
|    |----interface_test
|    |    |----interface_test.exe
|    |    |----main.go
|    |----multi_interface
|    |    |----main.go
|    |    |----multi_interface.exe
|    |----pointer_interface
|    |    |----main.go
|    |    |----pointer_interface.exe
|    |----type_assert
|    |    |----main.go
|    |    |----type_assert.exe
*/

func main() {
	app := cli.NewApp()
	app.Name = "golang to tree"

	app.Usage = "list all file"
	app.Action = func(c *cli.Context) error {
		var dir string = "."
		if c.NArg() > 0 {
			dir = c.Args()[0]
		}
		if err := ListDir(dir, 1); err != nil {
			panic(err)
		}
		return nil
	}
	app.Run(os.Args)
}

func ListDir(dirPath string, deep int) (err error) {
	dir, err := ioutil.ReadDir(dirPath)
	if err != nil {
		return err
	}
	if deep == 1 {
		fmt.Printf("!---%s\n", filepath.Base(dirPath))
	}

	// window的目录分隔符是 \
	// linux 的目录分隔符是 /
	sep := string(os.PathSeparator)
	for _, fi := range dir {
		// 如果是目录，继续调用ListDir进行遍历
		if fi.IsDir() {
			fmt.Printf("|")
			for i := 0; i < deep; i++ {
				fmt.Printf("    |")
			}
			fmt.Printf("----%s\n", fi.Name())
			if err = ListDir(dirPath+sep+fi.Name(), deep+1); err != nil {
				fmt.Printf("err:%s\n", err)
			}
			continue
		}

		fmt.Printf("|")
		for i := 0; i < deep; i++ {
			fmt.Printf("    |")
		}
		fmt.Printf("----%s\n", fi.Name())
	}
	return nil
}
```