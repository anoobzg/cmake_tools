# Node.js CMake 集成架构

本文档说明 Node.js/npm 项目集成到 CMake 构建系统的架构设计。

## 🏗️ 系统架构

```
DesktopFluidd 项目
│
├── 源代码层
│   ├── FluiddWebview2/fluidd/        # Fluidd Vue.js 源代码
│   │   ├── src/                      # Vue 组件和逻辑
│   │   ├── package.json              # npm 依赖和脚本
│   │   └── vite.config.ts            # Vite 构建配置
│   │
│   └── src/                          # C++ 源代码
│       ├── wxapp_example.cpp         # 主应用（读取 config.ini）
│       └── CMakeLists.txt            # 构建配置
│
├── 构建层
│   ├── cmake_tools/entry/nodejs/     # Node.js CMake 工具
│   │   ├── nodejs.cmake              # 核心宏定义
│   │   ├── README.md                 # 使用文档
│   │   ├── EXAMPLES.md               # 示例代码
│   │   └── ARCHITECTURE.md           # 本文档
│   │
│   └── CMake 构建流程
│       ├── 1. 检测 Node.js/npm
│       ├── 2. 安装依赖（npm install）
│       ├── 3. 构建前端（npm run build）
│       ├── 4. 复制到 resources/
│       ├── 5. 创建软链接
│       └── 6. 构建 C++ 应用
│
├── 资源层
│   ├── resources/                    # 运行时资源（源码目录）
│   │   ├── config.ini                # 运行时配置
│   │   └── fluidd/                   # 前端静态文件
│   │       ├── index.html
│   │       └── assets/
│   │
│   └── out/.../resources/            # 软链接到源码 resources/
│
└── 运行时
    └── DesktopFluidd.exe
        └── 加载 resources/config.ini
            ├── LOCAL_BUILD  → resources/fluidd/index.html
            ├── DEV_SERVER   → http://localhost:5173
            └── REMOTE_SERVER → 远程 URL
```

## 🔄 构建流程

### 1. CMake 配置阶段

```
cmake --preset vs2022-debug
    │
    ├─→ 加载 cmake_tools/entry/nodejs/nodejs.cmake
    │
    ├─→ __find_nodejs()
    │   ├─ 查找 node 可执行文件
    │   ├─ 查找 npm 可执行文件
    │   └─ 获取版本信息
    │
    ├─→ __build_fluidd_frontend()
    │   ├─ 检查 dist/index.html 是否存在
    │   ├─ 如果不存在或 FORCE 选项：
    │   │   ├─ __check_npm_dependencies()
    │   │   ├─ __npm_install() (如果需要)
    │   │   └─ __npm_build("build")
    │   └─ 复制 dist/ → resources/fluidd/
    │
    ├─→ __add_fluidd_build_target("rebuild-fluidd")
    │   └─ 创建自定义 CMake 目标
    │
    ├─→ __add_real_target(DesktopFluidd)
    │   └─ 创建主应用目标
    │
    └─→ __add_symlink(resources)
        └─ 配置软链接命令
```

### 2. CMake 构建阶段

```
cmake --build out/vs2022-debug
    │
    ├─→ 编译 C++ 源文件
    │   └─ wxapp_example.cpp → DesktopFluidd.exe
    │
    └─→ POST_BUILD 命令
        └─ 创建软链接
            Windows: mklink /J
            Linux:   ln -sf
```

### 3. 手动重建前端

```
cmake --build . --target rebuild-fluidd
    │
    ├─→ PRE_BUILD: npm install
    ├─→ PRE_BUILD: npm run build
    └─→ POST_BUILD: 复制到 resources/
```

## 🎯 关键设计决策

### 1. 何时构建前端？

**决策：** 配置时检查，按需构建

**原因：**
- ✅ 首次克隆项目时自动构建，用户体验好
- ✅ 已构建时跳过，不影响增量构建速度
- ✅ 可通过 `rebuild-fluidd` 目标手动重建
- ❌ 但 CMake 重新配置时会重复检查（开销小）

**替代方案：**
- 方案 A：每次构建都重建前端 → 太慢
- 方案 B：完全手动构建 → 用户体验差
- 方案 C：作为依赖项 → 难以控制

### 2. 如何部署资源？

**决策：** 使用软链接而不是文件拷贝

**原因：**
- ✅ 修改配置文件立即生效
- ✅ 节省磁盘空间
- ✅ 开发更便捷
- ✅ 跨平台支持（Windows junction + Linux symlink）
- ❌ Windows 需要管理员或开发者模式

**实现：**
```cmake
__add_symlink(DesktopFluidd ${CMAKE_SOURCE_DIR}/resources "")
# 创建：<exe_dir>/resources -> <source>/resources
```

### 3. 配置系统设计

**决策：** 运行时配置文件（INI）+ 软链接

**原因：**
- ✅ 无需重新编译即可切换模式
- ✅ 用户可直接编辑配置文件
- ✅ 支持多种加载方式
- ❌ 需要确保配置文件与可执行文件一起部署

**配置流程：**
```
DesktopFluidd.exe 启动
    │
    ├─→ GetResourcePath("config.ini")
    │   └─ 相对于可执行文件查找
    │
    ├─→ wxFileConfig 读取配置
    │
    ├─→ LoadFluiddUrlFromConfig()
    │   ├─ LOCAL_BUILD  → file:///resources/fluidd/index.html
    │   ├─ DEV_SERVER   → http://localhost:5173
    │   └─ REMOTE_SERVER → config 中的 URL
    │
    └─→ new FluiddView(url)
```

## 📊 数据流图

### 开发模式（DEV_SERVER）

```
开发者修改前端代码
    ↓
Vite 检测到变化
    ↓
自动重新编译
    ↓
热模块替换（HMR）
    ↓
WebView 自动刷新
    ↓
无需重启应用
```

### 生产模式（LOCAL_BUILD）

```
开发者修改前端代码
    ↓
cmake --build . --target rebuild-fluidd
    ↓
npm run build
    ↓
复制 dist/ → resources/fluidd/
    ↓
由于软链接，立即生效
    ↓
重启应用查看变化
```

## 🔌 接口定义

### CMake 宏接口

```cmake
# 核心构建宏
__build_fluidd_frontend(
    source_dir    # 必需：包含 package.json 的目录
    output_dir    # 必需：构建输出目录
    [FORCE]       # 可选：强制重建
)

# 创建构建目标
__add_fluidd_build_target(
    target_name   # 必需：CMake 目标名称
    source_dir    # 必需：源代码目录
    output_dir    # 必需：输出目录
)

# 底层工具
__find_nodejs()                    # 查找 Node.js 和 npm
__npm_install(source_dir)          # 安装依赖
__npm_build(source_dir script)     # 运行构建脚本
```

### C++ 配置接口

```cpp
// 读取配置文件
wxString GetResourcePath(const wxString& relativePath);
wxString LoadFluiddUrlFromConfig();

// 配置文件格式（INI）
[Fluidd]
LoadingMode=LOCAL_BUILD|DEV_SERVER|REMOTE_SERVER
DevServerUrl=http://localhost:5173
RemoteServerUrl=http://...

[Application]
EnableDevTools=true|false
WindowWidth=1280
WindowHeight=800
StartMaximized=true|false
```

## 🛠️ 扩展性

### 添加新的前端项目

```cmake
# 1. 定义变量
set(ADMIN_SRC ${CMAKE_SOURCE_DIR}/frontend/admin)
set(ADMIN_OUT ${CMAKE_SOURCE_DIR}/resources/admin)

# 2. 构建前端
__build_fluidd_frontend(${ADMIN_SRC} ${ADMIN_OUT})

# 3. 创建构建目标
__add_fluidd_build_target(rebuild-admin ${ADMIN_SRC} ${ADMIN_OUT})

# 4. 部署资源
__add_symlink(DesktopFluidd ${ADMIN_OUT} "admin")
```

### 自定义构建脚本

```cmake
# 如果 package.json 使用不同的脚本名
__find_nodejs()
__npm_install(${SOURCE_DIR})
__npm_build(${SOURCE_DIR} "build:production")
```

### 集成其他构建工具

```cmake
# Webpack
__npm_build(${SOURCE_DIR} "webpack-build")

# Rollup
__npm_build(${SOURCE_DIR} "rollup")

# 自定义
execute_process(
    COMMAND ${CUSTOM_BUILD_TOOL} ${ARGS}
    WORKING_DIRECTORY ${SOURCE_DIR}
)
```

## 🔒 安全考虑

### 1. Node.js 检测

- 不强制要求 Node.js（可选依赖）
- 未找到时警告但继续构建
- 允许使用预构建的前端

### 2. 命令执行

- 所有 npm 命令在指定目录执行
- 使用 CMake `execute_process` 安全执行
- 捕获并检查返回码

### 3. 路径处理

- 使用 CMake 变量而非硬编码
- 自动规范化路径分隔符
- 支持相对和绝对路径

### 4. 软链接权限

- Windows 检查管理员权限
- 提供清晰的错误提示
- 文档说明权限要求

## 📈 性能优化

### 1. 增量构建

- 检查 `dist/index.html` 存在性
- 跳过不必要的重建
- 可选的强制重建

### 2. 缓存策略

```
首次构建：
  ├─ npm install  (~2-3 分钟)
  └─ npm build    (~30-60 秒)

后续构建：
  └─ 跳过（已存在） (~0 秒)

手动重建：
  ├─ 重用 node_modules (~0 秒)
  └─ npm build      (~30-60 秒)
```

### 3. 并行构建

- CMake 构建与前端构建分离
- 不阻塞 C++ 编译
- 配置时异步执行

## 🧪 测试策略

### 单元测试

```cmake
# 测试 Node.js 检测
__find_nodejs()
if(NOT NODEJS_EXECUTABLE)
    message(FATAL_ERROR "Test failed: Node.js not found")
endif()

# 测试构建
__build_fluidd_frontend(${TEST_SRC} ${TEST_OUT})
if(NOT EXISTS "${TEST_OUT}/index.html")
    message(FATAL_ERROR "Test failed: Build output missing")
endif()
```

### 集成测试

```bash
# 完整构建测试
rm -rf out/
cmake --preset vs2022-debug
cmake --build out/vs2022-debug

# 验证输出
test -f out/vs2022-debug/bin/Debug/DesktopFluidd.exe
test -L out/vs2022-debug/bin/Debug/resources
test -f resources/fluidd/index.html
```

## 🐛 故障排除

### 诊断工具

```cmake
# 启用调试输出
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_MESSAGE_LOG_LEVEL DEBUG)

# 检查环境
__find_nodejs()
message(STATUS "Node.js: ${NODEJS_EXECUTABLE}")
message(STATUS "npm: ${NPM_EXECUTABLE}")
message(STATUS "Working directory: ${CMAKE_CURRENT_SOURCE_DIR}")
```

### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Node.js 未找到 | 未安装或不在 PATH | 安装 Node.js 或设置 PATH |
| npm install 失败 | 网络问题 | 配置 npm 镜像 |
| 构建输出缺失 | 构建脚本错误 | 检查 package.json |
| 软链接失败 | 权限不足 | 管理员运行或开发者模式 |
| WebView 错误 | 资源未部署 | 检查软链接和文件存在性 |

## 📚 参考资料

- [CMake 文档](https://cmake.org/cmake/help/latest/)
- [npm 脚本](https://docs.npmjs.com/cli/v8/using-npm/scripts)
- [Windows 软链接](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/mklink)
- [Linux 符号链接](https://man7.org/linux/man-pages/man1/ln.1.html)

---

**设计原则：**
- 🎯 开发者体验优先
- 🔄 自动化优于手动
- 🚀 性能与便利性平衡
- 🔌 可扩展可定制
- 📖 文档完备清晰

**版本:** 1.0  
**最后更新:** 2025-10-11

