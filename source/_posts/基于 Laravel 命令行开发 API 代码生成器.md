---
title: 基于 Laravel 命令行开发 API 代码生成器
categories: laravel
tags:
  - laravel
abbrlink: 9e380d0
date: 2020-06-08 11:39:27
---

##  1. 命令行文件生成
```bash 
$ php artisan make:command ApiGenerator
```

## 2. 编写代码模板
就像你看到的，我使用了 php 的 `heredoc` 方式，不太优雅。开始用的文件方式，但是不支持替换数组，就放弃了；有好的建议欢迎提。

`App\Traits\GeneratorTemplate`

```php
<?php
/**
 * Created by PhpStorm.
 * User: JeffreyBool
 * Date: 2019/11/18
 * Time: 01:20
 */

namespace App\Traits;

trait GeneratorTemplate
{
    /**
     * 创建验证模板.
     * @param $dummyNamespace
     * @param $modelName
     * @param $storeRules
     * @param $updateRules
     * @param $storeMessages
     * @param $updateMessages
     * @return string
     */
    public function genValidationTemplate(
        $dummyNamespace,
        $modelName,
        $storeRules,
        $updateRules,
        $storeMessages,
        $updateMessages
    ) {
        $template = <<<EOF
<?php
namespace {$dummyNamespace};

class {$modelName}
{
    /**
     * @return array
     */
    public function store()
    {
        /**
         * 新增验证规则
         */
        return [
            'rules'=> $storeRules,

            'messgaes'=> $storeMessages
        ];
     }


    /**
     * 编辑验证规则
     */
    public function update()
    {
        return [
           'rules'=> $updateRules,

           'messgaes'=> $updateMessages
        ];
    }
}
EOF;
        return $template;
    }


    /**
     * 创建资源返回模板.
     * @param $dummyNamespace
     * @param $modelName
     * @return string
     */
    public function genResourceTemplate($dummyNamespace, $modelName)
    {
        $template = <<<EOF
<?php
namespace {$dummyNamespace};

use Illuminate\Http\Resources\Json\JsonResource;

class {$modelName}Resource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  \$request
     * @return array
     */
    public function toArray(\$request)
    {
        return parent::toArray(\$request);
    }
}
EOF;
        return $template;
    }

    /**
     * 创建控制器模板.
     * @param $dummyNamespace
     * @param $modelName
     * @param $letterModelName
     * @param $modelNamePluralLowerCase
     * @return string
     */
    public function genControllerTemplate($dummyNamespace, $modelName, $letterModelName, $modelNamePluralLowerCase)
    {
        $template = <<<EOF
<?php
namespace {$dummyNamespace};

use Illuminate\Http\Request;
use App\Models\\{$modelName};
use App\Http\Resources\\{$modelName}Resource;

class {$modelName}Controller extends Controller
{
    /**
     * Get {$modelName} Paginate.
     * @param {$modelName} \${$letterModelName}
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     */
    public function index({$modelName} \${$letterModelName})
    {
        \${$modelNamePluralLowerCase} = \${$letterModelName}->paginate();
        return {$modelName}Resource::collection(\${$modelNamePluralLowerCase});
    }


    /**
     * Create {$modelName}.
     * @param Request         \$request
     * @param {$modelName} \${$letterModelName}
     * @return \Illuminate\Http\Response
     */
    public function store(Request \$request, {$modelName} \${$letterModelName})
    {
        \$this->validateRequest(\$request);
        \${$letterModelName}->fill(\$request->all());
        \${$letterModelName}->save();

        return \$this->created(\${$letterModelName});
    }


    /**
     * All {$modelName}.
     * @param Request         \$request
     * @param {$modelName} \${$letterModelName}
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     */
    public function all(Request \$request, {$modelName} \${$letterModelName})
    {
       \${$modelNamePluralLowerCase} = \${$letterModelName}->get();

       return {$modelName}Resource::collection(\${$modelNamePluralLowerCase});
    }



    /**
     * Show {$modelName}.
     * @param {$modelName} \${$letterModelName}
     * @return {$modelName}Resource
     */
    public function show({$modelName} \${$letterModelName})
    {
        return new {$modelName}Resource(\${$letterModelName});
    }


    /**
     * Update {$modelName}.
     * @param Request         \$request
     * @param {$modelName} \${$letterModelName}
     * @return \Illuminate\Http\Response
     */
    public function update(Request \$request, {$modelName} \${$letterModelName})
    {
        \$this->validateRequest(\$request);
        \${$letterModelName}->fill(\$request->all());
        \${$letterModelName}->save();

        return \$this->noContent();
    }


    /**
     * Delete {$modelName}.
     * @param {$modelName} \${$letterModelName}
     * @return \Illuminate\Contracts\Routing\ResponseFactory|\Illuminate\Http\Response
     * @throws \Exception
     */
    public function destroy({$modelName} \${$letterModelName})
    {
        \${$letterModelName}->delete();
        return \$this->noContent();
    }
}
EOF;
        return $template;
    }

    /**
     * 创建模型模板.
     * @param $dummyNamespace
     * @param $modelName
     * @param $fields
     * @return string
     */
    public function genModelTemplate($dummyNamespace, $modelName, $fields)
    {
        $template = <<<EOF
<?php
namespace {$dummyNamespace};

class {$modelName} extends Model
{
    protected \$fillable = {$fields};
}
EOF;
        return $template;
    }
}
```
##  3. 实现代码生成器
现在让我们来实现第 1 步所创建的控制台命令。
在 `app/Console/Commands` 文件夹找到 `ApiGenerator.php`

当然，该命令还没有设置，这就是为什么你看到一个默认的名称和说明。

修改命令标志和描述，如下：

```php
    /**
     * The name and signature of the console command.
     * @var string
     */
    protected $signature = 'api:generator
    {name : Class (singular) for example User}';

    /**
     * The console command description.
     * @var string
     */
    protected $description = 'Create Api operations';
```

描述要简洁、明了。

至于命令标志，可以根据个人喜好命名，就是后面我们要调用的 artisan 命令，如下：

```bash
$ php artisan api:generator RoleMenu
```

### 接下来实现数据库表结构读取

`App\Traits\MysqlStructure.php`

```php
<?php
namespace App\Traits;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\Console\Exception\RuntimeException;

trait MysqlStructure
{

    private $db;

    private $database;

    private $doctrineTypeMapping = [
        'tinyint'    => 'boolean',
        'smallint'   => 'smallint',
        'mediumint'  => 'integer',
        'int'        => 'integer',
        'integer'    => 'integer',
        'bigint'     => 'bigint',
        'tinytext'   => 'text',
        'mediumtext' => 'text',
        'longtext'   => 'text',
        'text'       => 'text',
        'varchar'    => 'string',
        'string'     => 'string',
        'char'       => 'string',
        'date'       => 'date',
        'datetime'   => 'datetime',
        'timestamp'  => 'datetime',
        'time'       => 'time',
        'float'      => 'float',
        'double'     => 'float',
        'real'       => 'float',
        'decimal'    => 'decimal',
        'numeric'    => 'decimal',
        'year'       => 'date',
        'longblob'   => 'blob',
        'blob'       => 'blob',
        'mediumblob' => 'blob',
        'tinyblob'   => 'blob',
        'binary'     => 'binary',
        'varbinary'  => 'binary',
        'set'        => 'simple_array',
        'json'       => 'json',
    ];

    /**
     * 表字段类型替换成laravel字段类型
     * @param string $table
     * @return Collection
     */
    public function tableFieldsReplaceModelFields(string $table): Collection
    {
        $sql = sprintf('SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = \'%s\' AND TABLE_NAME = \'%s\' ',
            $this->getDatabase(), $table);
        $columns = collect(DB::select($sql));
        if($columns->isEmpty()) {
            throw new RuntimeException(sprintf('Not Found Table, got "%s".', $table));
        }
        $columns = $columns->map(function($column) {
            if($column && $column->DATA_TYPE) {
                if(array_key_exists($column->DATA_TYPE,$this->doctrineTypeMapping)) {
                    $column->DATA_TYPE = $this->doctrineTypeMapping[$column->DATA_TYPE];
                }
            }
            return $column;
        });
        return $columns;
    }

    /**
     * 获取数据库所有表
     * @return array
     */
    protected function getAllTables()
    {
        $tables = DB::select('show tables');
        $box = [];
        $key = 'Tables_in_' . $this->db;
        foreach($tables as $tableName) {
            $tableName = $tableName->$key;
            $box[] = $tableName;
        }
        return $box;
    }


    /**
     * 输出表信息
     * @param $tableName
     */
    protected function outTableAction($tableName)
    {
        $columns = $this->getTableColumns($tableName);
        $rows = [];
        foreach($columns as $column) {
            $rows[] = [
                $column->COLUMN_NAME,
                $column->COLUMN_TYPE,
                $column->COLUMN_DEFAULT,
                $column->IS_NULLABLE,
                $column->EXTRA,
                $column->COLUMN_COMMENT,
            ];
        }
        $header = ['COLUMN', 'TYPE', 'DEFAULT', 'NULLABLE', 'EXTRA', 'COMMENT'];
        $this->table($header, $rows);
    }

    /**
     * 输出某个表所有字段
     * @param $tableName
     * @return mixed
     */
    public function getTableFields($tableName)
    {
        $columns = collect($this->getTableColumns($tableName));
        $columns = $columns->pluck('COLUMN_NAME');
        $columns = $columns->map(function($value) {
            return "'{$value}'";
        });
        return $columns->toArray();
    }


    /**
     * 获取数据库的表名
     * @param $table
     * @return array
     */
    public function getTableColumns($table)
    {
        $sql = sprintf('SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = \'%s\' AND TABLE_NAME = \'%s\' ',
            $this->getDatabase(), $table);
        $columns = DB::select($sql);
        if(!$columns) {
            throw new RuntimeException(sprintf('Not Found Table, got "%s".', $table));
        }
        return $columns;
    }


    /**
     * 获取表注释
     * @param $table
     * @return string
     */
    public function getTableComment($table)
    {
        $sql = sprintf('SELECT TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = \'%s\' AND TABLE_SCHEMA = \'%s\'',
            $table, $this->getDatabase());
        $tableComment = DB::selectOne($sql);
        if(!$tableComment) {
            return '';
        }
        return $tableComment->TABLE_COMMENT;
    }

    public function getDatabase()
    {
        return env('DB_DATABASE');
    }
}
```
上面是我封装的数据库表信息查询 sql 的文件。

### 生成代码实现

下面，我们来看看怎样使用`App\Traits\GeneratorTemplate` 文件夹下的 model 模板创建模型。
```php
/**
 * 创建模型
 * @param $name
 */
protected function model($name)
{
	$namespace = $this->getDefaultNamespace('Models');
	$table = Str::snake(Str::pluralStudly(class_basename($this->argument('name'))));
	$columns = $this->getTableFields($table);
	$fields = "[";
	for($i = 0; $i < count($columns); $i++) {
		$column = $columns[$i];
		if(in_array($column, ["'id'", "'created_at'", "'updated_at'", "'status'"])) {
			continue;
		}
		$fields .= sprintf("%s,", $column);
	}
	$fields .= "]";
	$fields = str_replace(",]", "]", $fields);
	$modelTemplate = $this->genModelTemplate($namespace, $name, $fields);
	$class = $namespace . '\\' . $name;
	if(class_exists($class)) {
		throw new RuntimeException(sprintf('class %s exist', $class));
	}
	file_put_contents(app_path("/Models/{$name}.php"), $modelTemplate);
	$this->info($name . ' created model successfully.');
}
```

​

从代码可以看到，`model`方法需要一个 `name` 参数，它由我们在 artisan 命令里传入。
看看 `$modelTemplate` 属性。我们使用变量把`model`模板文件里的占位符替换为我们期望的值。

基本上，在`App\Traits\GeneratorTemplate`文件里，我们用`$name`替换了`{{modelName}}`。请记住，在我们的例子中，`$name`的值是 RoleMenu。

你可以打开`App\Traits\GeneratorTemplate`文件检查一下，所有的`{{modelName}}`都被替换为了 RoleMenu。

`file_put_contents`函数再次使用了`$name`创建了一个新文件，因此它被命名为`RoleMenu.php`。并且，我们给这个文件传入内容，这些内容是从`$modelTemplate`属性获取的。`$modelTemplate`属性值是`App\Traits\GeneratorTemplate`文件的内容，只是所有的占位符均被替换了。

同样的事情还发生在`controller`和`validation`方法里。因此，我将这两个方法的内容粘贴在这里。

`App\Console\Commands\ApiGenerator.php`

```php
<?php

namespace App\Console\Commands;

use Illuminate\Support\Str;
use App\Traits\MysqlStructure;
use Illuminate\Console\Command;
use App\Traits\GeneratorTemplate;
use Symfony\Component\Console\Exception\RuntimeException;

class ApiGenerator extends Command
{
    use MysqlStructure, GeneratorTemplate;

    private $db;

    /**
     * The name and signature of the console command.
     * @var string
     */
    protected $signature = 'api:generator
    {name : Class (singular) for example User}';

    /**
     * The console command description.
     * @var string
     */
    protected $description = 'Create Api operations';

    public function __construct()
    {
        parent::__construct();
        $this->db = env('DB_DATABASE');
    }

    /**
     * Get the root namespace for the class.
     * @return string
     */
    protected function rootNamespace()
    {
        return $this->laravel->getNamespace();
    }

    /**
     * Get the default namespace for the class.
     * @param $name
     * @return string
     */
    protected function getDefaultNamespace($name)
    {
        $namespace = trim($this->rootNamespace(), '\\') . '\\' . $name;
        return $namespace;
    }

    /**
     * 获取规则文件
     * @param $type
     * @return bool|string
     */
    protected function getStub($type)
    {
        return file_get_contents(resource_path("stubs/$type.stub"));
    }


    /**
     * 创建规则文件
     * @param $name
     */
    protected function validation($name)
    {
        $namespace = $this->getDefaultNamespace('Http\Validations\Api');
        $table = Str::snake(Str::pluralStudly(class_basename($this->argument('name'))));
        $columns = $this->tableFieldsReplaceModelFields($table);
        $rules = "[\n";
        $messgaes = '[]';
        foreach($columns as $column) {
            if(in_array($column->COLUMN_NAME, ['id', 'created_at', 'updated_at', 'status'])) {
                continue;
            }
            $rule = '';
            if($column->IS_NULLABLE == "YES") {
                $rule .= 'required';
            } else {
                $rule .= 'nullable';
            }
            if($column->CHARACTER_MAXIMUM_LENGTH) {
                $rule .= '|max:' . $column->CHARACTER_MAXIMUM_LENGTH;
            }
            $rules .= sprintf("                '%s' => '%s',\n", $column->COLUMN_NAME, $rule);
        }
        $rules .= "            ]";
        $templateContent = $this->genValidationTemplate($namespace, $name, $rules, $rules, $messgaes, $messgaes);
        $class = $namespace . '\\' . $name;
        if(class_exists($class)) {
            throw new RuntimeException(sprintf('class %s exist', $class));
        }
        file_put_contents(app_path("/Http/Validations/Api/{$name}.php"), $templateContent);
        $this->info($name . ' created validation successfully.');
    }

    /**
     * 创建资源文件
     * @param $name
     */
    protected function resource($name)
    {
        $namespace = $this->getDefaultNamespace('Http\Resources');
        $resourceTemplate = $this->genResourceTemplate($namespace, $name);
        $class = $namespace . '\\' . $name;
        if(class_exists($class)) {
            throw new RuntimeException(sprintf('class %s exist', $class));
        }
        file_put_contents(app_path("/Http/Resources/{$name}Resource.php"), $resourceTemplate);
        $this->info($name . ' created resource successfully.');
    }

    /**
     * 创建控制器
     * @param $name
     */
    protected function controller($name)
    {
        $namespace = $this->getDefaultNamespace('Http\Controllers\Api');
        $controllerTemplate = $this->genControllerTemplate($namespace, $name, Str::camel($name),
            Str::pluralStudly(Str::camel($name)));
        $class = $namespace . '\\' . $name;
        if(class_exists($class)) {
            throw new RuntimeException(sprintf('class %s exist', $class));
        }
        file_put_contents(app_path("/Http/Controllers/Api/{$name}Controller.php"), $controllerTemplate);
        $this->info($name . ' created controller successfully.');
    }

    /**
     * 创建模型
     * @param $name
     */
    protected function model($name)
    {
        $namespace = $this->getDefaultNamespace('Models');
        $table = Str::snake(Str::pluralStudly(class_basename($this->argument('name'))));
        $columns = $this->getTableFields($table);
        $fields = "[";
        for($i = 0; $i < count($columns); $i++) {
            $column = $columns[$i];
            if(in_array($column, ["'id'", "'created_at'", "'updated_at'", "'status'"])) {
                continue;
            }
            $fields .= sprintf("%s,", $column);
        }
        $fields .= "]";
        $fields = str_replace(",]", "]", $fields);
        $modelTemplate = $this->genModelTemplate($namespace, $name, $fields);
        $class = $namespace . '\\' . $name;
        if(class_exists($class)) {
            throw new RuntimeException(sprintf('class %s exist', $class));
        }
        file_put_contents(app_path("/Models/{$name}.php"), $modelTemplate);
        $this->info($name . ' created model successfully.');
    }

    /**
     * Execute the console command.
     * @return mixed
     */
    public function handle()
    {
        $name = Str::ucfirst($this->argument('name'));
        $this->validation($name);
        $this->resource($name);
        $this->controller($name);
        $this->model($name);
    }
}

```

至此本篇文章完结。后续打开基于 `laravel` 和 `react` 开发一套全新的cms系统，到时候会将很多代码封装成 sdk

需要值得一提的是我生成的  `verification` 文件啥都没有，可以根据数据库的表字段类型生成验证规则，是不是节省了很多编码时间呢？ 哈哈哈哈
[verification文章参考](https://learnku.com/laravel/t/3137/design-of-shared-verification-rule-layer)
[代码参考文章](https://learnku.com/laravel/t/12500/command-line-combat-hand-in-hand-to-create-a-laravel-crud-code-generator-for-you)

