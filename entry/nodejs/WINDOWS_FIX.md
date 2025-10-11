# Windows npm 执行修复

## 🐛 问题描述

在 Windows 平台上，`__find_nodejs()` 宏中 `NPM_VERSION` 输出为空或不正确。

### 根本原因

在 Windows 上，npm 是一个批处理文件（`.cmd`），而 CMake 的 `find_program` 默认找到的是不带扩展名的 `npm`。当使用 `execute_process` 执行时，Windows 无法正确执行没有扩展名的批处理文件，导致：

1. `npm --version` 执行失败
2. `NPM_VERSION` 变量为空
3. 后续的 `npm install` 和 `npm run build` 也会失败

## ✅ 解决方案

### 1. 创建辅助宏 `__get_npm_command()`

```cmake
macro(__get_npm_command output_var)
    if(NPM_EXECUTABLE)
        set(${output_var} "${NPM_EXECUTABLE}")
        if(WIN32 AND NOT ${output_var} MATCHES "\\.cmd$")
            if(EXISTS "${${output_var}}.cmd")
                set(${output_var} "${${output_var}}.cmd")
            endif()
        endif()
    else()
        set(${output_var} "")
    endif()
endmacro()
```

### 2. 在所有使用 npm 的地方应用修复

更新以下宏/函数：
- `__find_nodejs()` - 版本检测
- `__npm_install()` - 安装依赖
- `__npm_build()` - 构建项目
- `__add_nodejs_build_target()` - 创建构建目标

### 3. 增强错误处理

添加：
- `ERROR_VARIABLE` - 捕获错误输出
- `RESULT_VARIABLE` - 检查执行结果
- `string(STRIP)` - 清理版本字符串
- `string(REGEX REPLACE)` - 移除多余的换行符

## 📊 修复前后对比

### 修复前

```
-- Found Node.js: D:/NodeJS/node.exe (v22.19.0)
-- NPM_EXECUTABLE: D:/NodeJS/npm
-- NPM_VERSION: ''
CMake Warning: npm found but version check failed:
```

### 修复后

```
-- Found Node.js: D:/NodeJS/node.exe (v22.19.0)
-- Found npm: D:/NodeJS/npm (v10.9.3)
-- NPM_EXECUTABLE: D:/NodeJS/npm
-- NPM_VERSION: '10.9.3'
-- ✅ NPM version format is correct
```

## 🔍 技术细节

### Windows 批处理文件处理

Windows 上的 npm 实际上是：
- `npm` (无扩展名) - Unix shell 脚本
- `npm.cmd` - Windows 批处理文件
- `npm.ps1` - PowerShell 脚本

CMake 的 `find_program` 在 Windows 上默认返回 `npm`（无扩展名），但 `execute_process` 需要完整的文件名才能执行。

### 解决方法

在执行前检查并添加 `.cmd` 扩展名：

```cmake
set(NPM_CMD "${NPM_EXECUTABLE}")
if(WIN32 AND NOT NPM_CMD MATCHES "\\.cmd$")
    if(EXISTS "${NPM_CMD}.cmd")
        set(NPM_CMD "${NPM_CMD}.cmd")
    endif()
endif()

execute_process(COMMAND ${NPM_CMD} --version ...)
```

## 🧪 测试验证

### 测试脚本

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

__find_nodejs()

message(STATUS "NODEJS_VERSION: '${NODEJS_VERSION}'")
message(STATUS "NPM_VERSION: '${NPM_VERSION}'")

if(NPM_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(STATUS "✅ NPM version format is correct")
endif()
```

### 预期输出

```
-- Found Node.js: D:/NodeJS/node.exe (v22.19.0)
-- Found npm: D:/NodeJS/npm (v10.9.3)
-- NODEJS_VERSION: 'v22.19.0'
-- NPM_VERSION: '10.9.3'
-- ✅ NPM version format is correct
```

## 📝 影响的文件

```
cmake_tools/entry/nodejs/
└── nodejs.cmake
    ├── __find_nodejs()               ✅ 已修复
    ├── __get_npm_command()           ✅ 新增
    ├── __npm_install()               ✅ 已修复
    ├── __npm_build()                 ✅ 已修复
    └── __add_nodejs_build_target()   ✅ 已修复
```

## 🎯 相关问题

### 问题 1：为什么 `find_program` 不直接查找 `.cmd` 文件？

CMake 的 `find_program` 在 Windows 上会自动添加 `.exe`、`.com`、`.bat` 等扩展名进行搜索，但优先返回无扩展名的文件（如果存在）。npm 包同时提供了多个版本（shell、cmd、ps1），`find_program` 返回了通用的无扩展名版本。

### 问题 2：为什么不直接在 `find_program` 中指定 `npm.cmd`？

虽然可以这样做，但会导致：
- Linux/macOS 上找不到 npm
- 需要为不同平台写不同的逻辑
- 当前的方案更加通用和简洁

### 问题 3：其他 Windows 工具也有这个问题吗？

是的，所有以批处理文件形式提供的命令行工具都可能有类似问题，例如：
- yarn
- pnpm
- gulp
- grunt

## 💡 最佳实践

### 1. 使用辅助宏

为平台特定的命令创建辅助宏：

```cmake
macro(__get_executable_command base_path output_var)
    set(${output_var} "${base_path}")
    if(WIN32)
        if(EXISTS "${base_path}.cmd")
            set(${output_var} "${base_path}.cmd")
        elseif(EXISTS "${base_path}.bat")
            set(${output_var} "${base_path}.bat")
        endif()
    endif()
endmacro()
```

### 2. 总是检查执行结果

```cmake
execute_process(
    COMMAND ${TOOL} --version
    OUTPUT_VARIABLE VERSION
    ERROR_VARIABLE ERROR
    RESULT_VARIABLE RESULT
)

if(NOT RESULT EQUAL 0)
    message(WARNING "Command failed: ${ERROR}")
endif()
```

### 3. 清理输出

```cmake
string(STRIP "${VERSION}" VERSION)
string(REGEX REPLACE "[\r\n]+" "" VERSION "${VERSION}")
```

## 🔗 相关资源

- [CMake execute_process 文档](https://cmake.org/cmake/help/latest/command/execute_process.html)
- [CMake find_program 文档](https://cmake.org/cmake/help/latest/command/find_program.html)
- [Windows CMD 批处理文件](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cmd)

## ✅ 验证清单

在 Windows 上验证修复：

- [x] `__find_nodejs()` 正确检测 Node.js 版本
- [x] `__find_nodejs()` 正确检测 npm 版本
- [x] `__npm_install()` 可以安装依赖
- [x] `__npm_build()` 可以构建项目
- [x] `__add_nodejs_build_target()` 创建的目标可以执行

---

**修复日期:** 2025-10-11  
**平台:** Windows 10/11  
**测试版本:** Node.js 22.19.0, npm 10.9.3  
**状态:** ✅ 已解决

