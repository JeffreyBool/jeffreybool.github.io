---
title: 基于 laravel auth 接口实现自定义接口API用户认证详细步骤
categories: laravel
tags:
  - laravel
  - auth
abbrlink: e8066d9a
date: 2020-06-05 13:02:01
---

## 基于 laravel 默认的 `auth` 实现 api 认证
现在微服务越来越流行了. 很多东西都拆分成独立的系统,各个系统之间没有直接的关系. 这样我们如果做用户认证肯定是统一的做一个独立的 `用户认证` 系统,而不是每个业务系统都要重新去写一遍用户认证相关的东西. 但是又遇到一个问题了. `laravel` 默认的`auth  认证` 是基于数据库做的,如果要微服务架构可怎么做呢?

## 实现代码如下:

### UserProvider 接口:
```php
// 通过唯一标示符获取认证模型
public function retrieveById($identifier);
// 通过唯一标示符和 remember token 获取模型
public function retrieveByToken($identifier, $token);
// 通过给定的认证模型更新 remember token
public function updateRememberToken(Authenticatable $user, $token);
// 通过给定的凭证获取用户，比如 email 或用户名等等
public function retrieveByCredentials(array $credentials);
// 认证给定的用户和给定的凭证是否符合
public function validateCredentials(Authenticatable $user, array $credentials);
```

`Laravel` 中默认有两个 **user provider** : `DatabaseUserProvider` & `EloquentUserProvider`.
**DatabaseUserProvider**
`Illuminate\Auth\DatabaseUserProvider`

直接通过数据库表来获取认证模型.

**EloquentUserProvider**
`Illuminate\Auth\EloquentUserProvider`

通过 eloquent 模型来获取认证模型

-----------------------
根据上面的知识，可以知道要自定义一个认证很简单。

## 自定义 `Provider`
创建一个自定义的认证模型，实现 Authenticatable 接口；

`App\Auth\UserProvider.php`

```php
<?php

namespace App\Auth;

use App\Models\User;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Contracts\Auth\UserProvider as Provider;

class UserProvider implements Provider
{

    /**
     * Retrieve a user by their unique identifier.
     * @param  mixed $identifier
     * @return \Illuminate\Contracts\Auth\Authenticatable|null
     */
    public function retrieveById($identifier)
    {
        return app(User::class)::getUserByGuId($identifier);
    }

    /**
     * Retrieve a user by their unique identifier and "remember me" token.
     * @param  mixed  $identifier
     * @param  string $token
     * @return \Illuminate\Contracts\Auth\Authenticatable|null
     */
    public function retrieveByToken($identifier, $token)
    {
        return null;
    }

    /**
     * Update the "remember me" token for the given user in storage.
     * @param  \Illuminate\Contracts\Auth\Authenticatable $user
     * @param  string                                     $token
     * @return bool
     */
    public function updateRememberToken(Authenticatable $user, $token)
    {
        return true;
    }

    /**
     * Retrieve a user by the given credentials.
     * @param  array $credentials
     * @return \Illuminate\Contracts\Auth\Authenticatable|null
     */
    public function retrieveByCredentials(array $credentials)
    {
        if ( !isset($credentials['api_token'])) {
            return null;
        }

        return app(User::class)::getUserByToken($credentials['api_token']);
    }

    /**
     * Rules a user against the given credentials.
     * @param  \Illuminate\Contracts\Auth\Authenticatable $user
     * @param  array                                      $credentials
     * @return bool
     */
    public function validateCredentials(Authenticatable $user, array $credentials)
    {
        if ( !isset($credentials['api_token'])) {
            return false;
        }

        return true;
    }
}

```

### Authenticatable 接口:
`Illuminate\Contracts\Auth\Authenticatable`
Authenticatable 定义了一个可以被用来认证的模型或类需要实现的接口，也就是说，如果需要用一个自定义的类来做认证，需要实现这个接口定义的方法。

```php
<?php
.
.
.
// 获取唯一标识的，可以用来认证的字段名，比如 id，uuid
public function getAuthIdentifierName();
// 获取该标示符对应的值
public function getAuthIdentifier();
// 获取认证的密码
public function getAuthPassword();
// 获取remember token
public function getRememberToken();
// 设置 remember token
public function setRememberToken($value);
// 获取 remember token 对应的字段名，比如默认的 'remember_token'
public function getRememberTokenName();
.
.
.
```

Laravel 中定义的 `Authenticatable trait`，也是 Laravel auth 默认的 `User` 模型使用的 trait，这个 trait 定义了 `User` 模型默认认证标示符为 'id'，密码字段为`password`，`remember token` 对应的字段为 `remember_token` 等等。
​
通过重写 `User` 模型的这些方法可以修改一些设置。

### 实现自定义认证模型

`App\Models\User.php`
```php
<?php

namespace App\Models;

use App\Exceptions\RestApiException;
use App\Models\Abstracts\RestApiModel;
use Illuminate\Contracts\Auth\Authenticatable;

class User extends RestApiModel implements Authenticatable
{

    protected $primaryKey = 'guid';

    public $incrementing = false;

    protected $keyType = 'string';

    /**
     * 获取唯一标识的，可以用来认证的字段名，比如 id，guid
     * @return string
     */
    public function getAuthIdentifierName()
    {
        return $this->primaryKey;
    }

    /**
     * 获取主键的值
     * @return mixed
     */
    public function getAuthIdentifier()
    {
        $id = $this->{$this->getAuthIdentifierName()};
        return $id;
    }


    public function getAuthPassword()
    {
        return '';
    }

    public function getRememberToken()
    {
        return '';
    }

    public function setRememberToken($value)
    {
        return true;
    }

    public function getRememberTokenName()
    {
        return '';
    }

    protected static function getBaseUri()
    {
        return config('api-host.user');
    }

    public static $apiMap = [
        'getUserByToken' => ['method' => 'GET', 'path' => 'login/user/token'],
        'getUserByGuId'  => ['method' => 'GET', 'path' => 'user/guid/:guid'],
    ];


    /**
     * 获取用户信息 (by guid)
     * @param string $guid
     * @return User|null
     */
    public static function getUserByGuId(string $guid)
    {
        try {
            $response = self::getItem('getUserByGuId', [
                ':guid' => $guid
            ]);
        } catch (RestApiException $e) {
            return null;
        }

        return $response;
    }


    /**
     * 获取用户信息 (by token)
     * @param string $token
     * @return User|null
     */
    public static function getUserByToken(string $token)
    {
        try {
            $response = self::getItem('getUserByToken', [
                'Authorization' => $token
            ]);
        } catch (RestApiException $e) {
            return null;
        }

        return $response;
    }
}

```

上面 `RestApiModel` 是我们公司对 `Guzzle` 的封装,用于 php 项目各个系统之间 `api` 调用. 代码就不方便透漏了.


## Guard 接口

`Illuminate\Contracts\Auth\Guard`

`Guard` 接口定义了某个实现了 `Authenticatable` (可认证的) 模型或类的认证方法以及一些常用的接口。

```
// 判断当前用户是否登录
public function check();
// 判断当前用户是否是游客（未登录）
public function guest();
// 获取当前认证的用户
public function user();
// 获取当前认证用户的 id，严格来说不一定是 id，应该是上个模型中定义的唯一的字段名
public function id();
// 根据提供的消息认证用户
public function validate(array $credentials = []);
// 设置当前用户
public function setUser(Authenticatable $user);
```

### StatefulGuard 接口

`Illuminate\Contracts\Auth\StatefulGuard`

`StatefulGuard` 接口继承自 `Guard` 接口，除了 `Guard` 里面定义的一些基本接口外，还增加了更进一步、有状态的 `Guard`.

新添加的接口有这些：

```
// 尝试根据提供的凭证验证用户是否合法
public function attempt(array $credentials = [], $remember = false);
// 一次性登录，不记录session or cookie
public function once(array $credentials = []);
// 登录用户，通常在验证成功后记录 session 和 cookie 
public function login(Authenticatable $user, $remember = false);
// 使用用户 id 登录
public function loginUsingId($id, $remember = false);
// 使用用户 ID 登录，但是不记录 session 和 cookie
public function onceUsingId($id);
// 通过 cookie 中的 remember token 自动登录
public function viaRemember();
// 登出
public function logout();
```

`Laravel` 中默认提供了 3 中 **guard** ：`RequestGuard`，`TokenGuard`，`SessionGuard`.

### RequestGuard

`Illuminate\Auth\RequestGuard`

RequestGuard 是一个非常简单的 guard. RequestGuard 是通过传入一个闭包来认证的。可以通过调用 `Auth::viaRequest` 添加一个自定义的 RequestGuard.


### SessionGuard

`Illuminate\Auth\SessionGuard`

SessionGuard 是 Laravel web 认证默认的 guard.

### TokenGuard

`Illuminate\Auth\TokenGuard`

TokenGuard 适用于无状态 api 认证，通过 token 认证.

## 实现自定义 `Guard`

`App\Auth\UserGuard.php`
```php
<?php

namespace App\Auth;

use Illuminate\Http\Request;
use Illuminate\Auth\GuardHelpers;
use Illuminate\Contracts\Auth\Guard;
use Illuminate\Contracts\Auth\UserProvider;

class UserGuard implements Guard

{
    use GuardHelpers;

    protected $user = null;

    protected $request;

    protected $provider;

    /**
     * The name of the query string item from the request containing the API token.
     *
     * @var string
     */
    protected $inputKey;

    /**
     * The name of the token "column" in persistent storage.
     *
     * @var string
     */
    protected $storageKey;

    /**
     * The user we last attempted to retrieve
     * @var
     */
    protected $lastAttempted;

    /**
     * UserGuard constructor.
     * @param UserProvider $provider
     * @param Request      $request
     * @return void
     */
    public function __construct(UserProvider $provider, Request $request = null)
    {
        $this->request = $request;
        $this->provider = $provider;
        $this->inputKey = 'Authorization';
        $this->storageKey = 'api_token';
    }

    /**
     * Get the currently authenticated user.
     * @return \Illuminate\Contracts\Auth\Authenticatable|null
     */
    public function user()
    {
        if(!is_null($this->user)) {
            return $this->user;
        }

        $user = null;

        $token = $this->getTokenForRequest();

        if(!empty($token)) {
            $user = $this->provider->retrieveByCredentials(
                [$this->storageKey => $token]
            );
        }

        return $this->user = $user;
    }

    /**
     * Rules a user's credentials.
     * @param  array $credentials
     * @return bool
     */
    public function validate(array $credentials = [])
    {
        if (empty($credentials[$this->inputKey])) {
            return false;
        }

        $credentials = [$this->storageKey => $credentials[$this->inputKey]];

        $this->lastAttempted = $user = $this->provider->retrieveByCredentials($credentials);

        return $this->hasValidCredentials($user, $credentials);
    }

    /**
     * Determine if the user matches the credentials.
     * @param  mixed $user
     * @param  array $credentials
     * @return bool
     */
    protected function hasValidCredentials($user, $credentials)
    {
        return !is_null($user) && $this->provider->validateCredentials($user, $credentials);
    }


    /**
     * Get the token for the current request.
     * @return string
     */
    public function getTokenForRequest()
    {
        $token = $this->request->header($this->inputKey);

        return $token;
    }

    /**
     * Set the current request instance.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return $this
     */
    public function setRequest(Request $request)
    {
        $this->request = $request;

        return $this;
    }
}

```

在 AppServiceProvider 的 boot 方法添加如下代码：
`App\Providers\AuthServiceProvider.php`
```php
<?php
.
.
.
// auth:api -> token provider.
Auth::provider('token', function() {
	return app(UserProvider::class);
});

// auth:api -> token guard.
// @throw \Exception
Auth::extend('token', function($app, $name, array $config) {
	if($name === 'api') {
		return app()->make(UserGuard::class, [
			'provider' => Auth::createUserProvider($config['provider']),
			'request'  => $app->request,
		]);
	}
	throw new \Exception('This guard only serves "auth:api".');
});
.
.
.
```


- 在 `config\auth.php`的 guards 数组中添加自定义 `guard`，一个自定义 guard 包括两部分： `driver` 和 `provider`.

- 设置 `config\auth.php` 的 defaults.guard 为 `api`.

```php
<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Authentication Defaults
    |--------------------------------------------------------------------------
    |
    | This option controls the default authentication "guard" and password
    | reset options for your application. You may change these defaults
    | as required, but they're a perfect start for most applications.
    |
    */

    'defaults' => [
        'guard' => 'api',
        'passwords' => 'users',
    ],

    /*
    |--------------------------------------------------------------------------
    | Authentication Guards
    |--------------------------------------------------------------------------
    |
    | Next, you may define every authentication guard for your application.
    | Of course, a great default configuration has been defined for you
    | here which uses session storage and the Eloquent user provider.
    |
    | All authentication drivers have a user provider. This defines how the
    | users are actually retrieved out of your database or other storage
    | mechanisms used by this application to persist your user's data.
    |
    | Supported: "session", "token"
    |
    */

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'token',
            'provider' => 'token',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | User Providers
    |--------------------------------------------------------------------------
    |
    | All authentication drivers have a user provider. This defines how the
    | users are actually retrieved out of your database or other storage
    | mechanisms used by this application to persist your user's data.
    |
    | If you have multiple user tables or models you may configure multiple
    | sources which represent each model / table. These sources may then
    | be assigned to any extra authentication guards you have defined.
    |
    | Supported: "database", "eloquent"
    |
    */

    'providers' => [
        'users' => [
            'driver' => 'eloquent',
            'model' => App\Models\User::class,
        ],

        'token' => [
            'driver' => 'token',
            'model' => App\Models\User::class,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Resetting Passwords
    |--------------------------------------------------------------------------
    |
    | You may specify multiple password reset configurations if you have more
    | than one user table or model in the application and you want to have
    | separate password reset settings based on the specific user types.
    |
    | The expire time is the number of minutes that the reset token should be
    | considered valid. This security feature keeps tokens short-lived so
    | they have less time to be guessed. You may change this as needed.
    |
    */

    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table' => 'password_resets',
            'expire' => 60,
        ],
    ],

];

```


原文[地址](https://www.zhanggaoyuan.com/topics/143/realization-of-user-interface-authentication-for-user-interface-api-based-on-laravel-auth)
参考文章: [地址](https://learnku.com/articles/3825/laravel-authentication-principle-and-full-custom-authentication)

第一次写这么多字的文章,写的不好请多多包涵!! 

原文链接：[https://www.zhanggaoyuan.com/article/9](https://www.zhanggaoyuan.com/article/9)