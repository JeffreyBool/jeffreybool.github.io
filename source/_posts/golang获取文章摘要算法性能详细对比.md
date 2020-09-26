---
title: golang获取文章摘要算法性能详细对比
summary: >-
  现在我们开发网站基本摆脱不了上传文件的功能，但是上传文件的可能有几百M 或者几个G,
  如果不做秒传的话会带来很多的功能。例如：用户体验不好，同一个文件还要多次上传到服务器。浪费服务器带宽和资源。如果我们做了秒传就会解决上面带来的问题，可以在客户端计算文件的摘要，和服务器算法保持一致就可以做到秒传了，客户端拿着算好的摘要去服务端判断这个文件是否已经上传，如果上传了直接返回文件信息，没有上传就调用上传接口
top: true
categories: golang
tags: golang
abbrlink: 3f02e521
date: 2020-06-05 11:54:37
---

为了测试 golang `ioutil.ReadAll` 、`io.Copy`、`bufio.NewReader` 性能 我写了三个函数，函数代码如下:

## golang 读取文件性能对比

### `ioutil.ReadAll` 

```go
func ReadAll(path string) (fileMD5 string, err error) {
	f, err := os.Open(path)
	if err != nil {
		return fileMD5, err
	}
	defer f.Close()

	body, err := ioutil.ReadAll(f)
	if err != nil {
		return fileMD5, err
	}
	hash := sha1.New()
	hash.Write(body)
	fileMD5 = hex.EncodeToString(hash.Sum(nil))
	return fileMD5, nil
}
```


### `io.copy`

```go
func Copy(path string) (fileMD5 string, err error) {
	f, err := os.Open(path)
	if err != nil {
		return fileMD5, err
	}
	defer f.Close()

	md5hash := sha1.New()
	if _, err := io.Copy(md5hash, f); err != nil {
		return fileMD5, err
	}

	fileMD5 = hex.EncodeToString(md5hash.Sum(nil))
	return fileMD5, nil
}
```

### `bufio.NewReader`

```go
func ReadBuf(path string) (fileMD5 string, err error) {
	f, err := os.Open(path)
	if err != nil {
		return fileMD5, err
	}
	defer f.Close()

	buf := make([]byte, 1024)
	reader := bufio.NewReader(f)
	md5hash := sha1.New()
	for {
		n, err := reader.Read(buf)
		if err != nil { // 遇到任何错误立即返回，并忽略 EOF 错误信息
			if err == io.EOF {
				goto stop
			}
			return fileMD5, err
		}
		md5hash.Write(buf[:n])
	}
stop:
	fileMD5 = hex.EncodeToString(md5hash.Sum(nil))
	return fileMD5, nil
}
```

### 单元测试

```go
package file_test

import (
	"testing"

	"filestore/test/file"
)

var (
	minPath = "~/6d827d1edddea7c73fb7d6efbb467167839ff2f6.jpg"
	maxPath = "/Users/zhanggaoyuan/学习/2004.mkv"
)

func BenchmarkReadAll(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, err := file.ReadAll(minPath)
		if err != nil {
			b.Error(err)
			return
		}
	}
}

func BenchmarkCopy(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, err := file.Copy(minPath)
		if err != nil {
			b.Error(err)
			return
		}
	}
}

func BenchmarkReadBuf(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, err := file.ReadBuf(minPath)
		if err != nil {
			b.Error(err)
			return
		}
	}
}
```

## 文件大小耗时情况
###  小于等于 `10MB` 的文件耗时情况
准备 6d827d1edddea7c73fb7d6efbb467167839ff2f6.jpg 9.7M 的文件，

执行 `go test -bench=. -benchmem` 就可以看到详细的信息啦
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkReadAll-8   	      64	  17963784 ns/op	33552812 B/op	      22 allocs/op
BenchmarkCopy-8      	      80	  12910267 ns/op	   33192 B/op	       8 allocs/op
BenchmarkReadBuf-8   	      66	  15641888 ns/op	    5544 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	3.994s
```

我们可以看出 `BenchmarkCopy` 性能最高，执行 84 次平均时间 12910267 纳秒，也就是 1.2 秒左右的样子啦。

###  小于等于 `40MB` 的文件耗时情况

准备文件 niushop_b2c_mf2.3.zip 37M

执行 `go test -bench=. -benchmem` 就可以看到详细的信息啦

```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkReadAll-8   	      16	  63298080 ns/op	134216088 B/op	      24 allocs/op
BenchmarkCopy-8      	      24	  48085580 ns/op	   33176 B/op	       8 allocs/op
BenchmarkReadBuf-8   	      19	  58120592 ns/op	    5528 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	4.206s
```

我们还是可以看到 `BenchmarkCopy` 函数性能最高

### 大于等于 `1G` 小于等于 `6G`的文件耗时情况

注意一点的就是当我们测试大文件读取不能直接使用 `ioutil.ReadAll`, 因为这个函数会直接把文件的全部内容加载到内存中，这样会导致内存直接崩溃。我们只使用 `io.copy` 和 bufio.NewReader 函数，太大了刚不住，我也很无奈啊~~😆😆😆😆
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkCopy-8      	       1	8612443012 ns/op	   33176 B/op	      10 allocs/op
BenchmarkReadBuf-8   	       1	8924705447 ns/op	    5512 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	17.554s
```

我们比较这两个函数的性能发现具体差别不是太大。 单还是 `BenchmarkCopy` 性能更快。。。，好啦没得话说选 `io.copy` 啦


## 接下来分析 `md5` 和 `sha1` 哪个算法计算更快

我们还是用不同的文件做比较，因为有时候很多函数的时间和空间复杂度和大小，数量有关系

### 小于等于`10MB` 的文件耗时情况
`sha1`
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkReadAll-8   	      64	  17963784 ns/op	33552812 B/op	      22 allocs/op
BenchmarkCopy-8      	      80	  12910267 ns/op	   33192 B/op	       8 allocs/op
BenchmarkReadBuf-8   	      66	  15641888 ns/op	    5544 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	3.994s
```
`md5`
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkReadAll-8   	      56	  20431688 ns/op	33552750 B/op	      22 allocs/op
BenchmarkCopy-8      	      70	  16554352 ns/op	   33128 B/op	       8 allocs/op
BenchmarkReadBuf-8   	      57	  19220965 ns/op	    5480 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	4.202s
```
### 小于等于 `40MB` 的文件耗时情况
`sha1`
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkReadAll-8   	      16	  63298080 ns/op	134216088 B/op	      24 allocs/op
BenchmarkCopy-8      	      24	  48085580 ns/op	   33176 B/op	       8 allocs/op
BenchmarkReadBuf-8   	      19	  58120592 ns/op	    5528 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	4.206s
```
`md5`
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkReadAll-8   	      14	  75987790 ns/op	134216024 B/op	      24 allocs/op
BenchmarkCopy-8      	      19	  61600369 ns/op	   33112 B/op	       8 allocs/op
BenchmarkReadBuf-8   	      15	  72338837 ns/op	    5464 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	4.339s
```
### 大于等于 `1G` 小于等于 `6G`的文件耗时情况

`sha1`
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkCopy-8      	       1	8612443012 ns/op	   33176 B/op	      10 allocs/op
BenchmarkReadBuf-8   	       1	8924705447 ns/op	    5512 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	17.554s
```
`md5`
```
goos: darwin
goarch: amd64
pkg: filestore/test/file
BenchmarkCopy-8      	       1	8714197367 ns/op	   33112 B/op	      10 allocs/op
BenchmarkReadBuf-8   	       1	10077543682 ns/op	    5448 B/op	       9 allocs/op
PASS
ok  	filestore/test/file	18.804s
```

> 最终我们可以看到 `sha1` 算法不管是大文件还是小文件都优于 `md5` 文件的性能。至此还用比吗？傻子才不选 `sha1` 算法呢~, 最终选 `io.copy` 和 `sha1`


原文链接：[https://www.zhanggaoyuan.com/article/58](https://www.zhanggaoyuan.com/article/58)
