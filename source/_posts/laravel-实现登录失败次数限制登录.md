---
title: laravel 实现登录失败次数限制登录
top: true
categories: laravel
tags: laravel
abbrlink: 36a45cef
date: 2020-06-05 12:37:29
---

在默认的 auth 的 `LoginControoler` usr的trait `AuthenticatesUsers`
`Illuminate\Foundation\Auth\ThrottlesLogins`这个trait有如下方法

```php
limiter();
// limiter方法，从服务容器获取 RateLimiter 实例，专门连接缓存记录用户登录次数；

throttleKey(Request $request);
// 该方法的内部代码为 return Str::lower($request->input($this->username())).'|'.$request->ip();
// 返回的值为 缓存数据库中的Key; 
// 比如 张三从 192.168.1.11 登录系统，5次尝试登录失败，那么此处的返回值是 张三 | 192.168.1.11
// 缓存数据库中有一条记录是 键名为 '张三 | 192.168.1.11'， 键值为 '5'

hasTooManyLoginAttempts(Request $request);
// 判断是否用户失败登录频率超过门槛值(1分钟内失败5次)；

incrementLoginAttempts(Request $request);
// 用户在缓存数据库中的登录次数值，如果存在则加1；不存在，则新增，同时设置过期时间（默认是1分钟）

sendLockoutResponse(Request $request);
// 这方法被调用意味着用户已经超过登录上限，此时方法会 back 到登录页，并携带'登录超过上限，请于58秒后再次登录'这样的提示； 

clearLoginAttempts(Request $request);
// 清除指定用户在缓存数据库中的登录次数记录，包括Lock记录；

fireLockoutEvent(Request $request);
// 方法内部就一句话，event(new Lockout($request)); 触发 lockout 事件
```

Laravel 本身已实现了登录失败次数限制的功能。在使用 Laravel 的登录验证时，登录失败次数限制预设是：「失败5次，1分钟后才可再次登录。」但如果要求的功能是：「失败3次，1分钟后才可登录；再失败3次，3分钟后才可登录；再失败3次，5分钟后才可登录。」要如何实现？下面将实际示范此登录失败次数限制的功能。

## 版本
Laravel 5.5 以上

## 改写登录类别设定

*app\Http\Controllers\Auth\LoginController.php*
```php
<?php

...
use Illuminate\Foundation\Auth\AuthenticatesUsers;
use App\Cache\AdvancedRateLimiter

class LoginController extends Controller
{
    use AuthenticatesUsers;

    ...

    /**
     * Get the rate limiter instance.
     *
     * @return \App\Cache\AdvancedRateLimiter
     */
    protected function limiter()
    {
        return app(AdvancedRateLimiter::class);
    }

    /**
     * The maximum number of attempts to allow.
     *
     * @var integer
     */
    protected $maxAttempts = 3;

    /**
     * The number of minutes to throttle for.
     *
     * @var integer|array
     */
    protected $decayMinutes = [1, 3, 5];
}
```

在 `LoginController` 类中，增加自订方法复盖掉 `AuthenticatesUsers` 类原本的方法：
- `limiter` 方法是返回登录失败次数限制的类，原本是返回 `RateLimiter` 类(实现登录失败次数限制的类)，但本例要扩充新方法，因此返回了我们下面创建的子类别 `AdvancedRateLimiter` 。
- `$maxAttempts` 属性是设定登录失败次数。
- `$decayMinutes` 属性是登录失败达上限后，须等待的分钟数。但我们要实现的功能是每次都等待不一样的时间，因此传入一个数组，输入每次的等待分钟数。

如果只是要修改 Laravel 原本的次数设定，新增 `$maxAttempts` 属性及 `$decayMinutes` 属性并设定值即可完成。

## 擴充登录失败次数限制功能

新增类别 `AdvancedRateLimiter`：

*app\Cache\AdvancedRateLimiter.php*
```php
<?php

namespace App\Cache;

use Illuminate\Cache\RateLimiter;

class AdvancedRateLimiter extends RateLimiter
{
    /**
     * Increment the counter for a given key for a given decay time.
     *
     * @param  string  $key
     * @param  float|int|array  $decayMinutes
     * @return int
     */
    public function hit($key, $decayMinutes = 1)
    {
        if (is_array($decayMinutes)) {
            if (! $this->cache->has($key.':timer')) {
                if (! $this->cache->has($key.':step')) {
                    $this->cache->add($key.':step', 0, 1440);
                } else {
                    $this->cache->increment($key.':step');
                }
            }
            $step = $this->cache->get($key.':step', 0);
            $step = $step < count($decayMinutes) ? $step : count($decayMinutes) - 1;
            $decayMinutes = $decayMinutes[$step];
        }

        return parent::hit($key, now()->addMinutes($decayMinutes));
    }

    /**
     * Clear the hits and lockout timer for the given key.
     *
     * @param  string  $key
     * @return void
     */
    public function clear($key)
    {
        $this->cache->forget($key.':step');

        parent::clear($key);
    }
}
```

- `hit` 方法是在登錄錯誤後，執行登錄錯誤次數記錄遞增的方法。為了實現每次登錄錯誤等待的時間可以不一樣，我們讓傳入的變數 `$decayMinutes` 可以接受傳入数组，第一次登錄錯誤等待時間為 `数组[0]` 的分鐘數(本例為1分鐘)，第二次為 `数组[1]` 的分鐘數(例：3分鐘)，而第三次為 `数组[2]` 的分鐘數(例：5分鐘)，之後的登錄錯誤等待時間皆為数组的最後的元素的分鐘數。
- `clear` 是成功登入後，將時間、次數重設，下一次再登入錯誤後，將從頭開始計數。

此時登录失败次数限制的功能已改寫完成，再次登入並輸入錯誤的帳號或密碼，重複數次即可看到結果。


原文链接：[https://www.zhanggaoyuan.com/article/55](https://www.zhanggaoyuan.com/article/55)