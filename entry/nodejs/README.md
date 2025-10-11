# Node.js CMake Utilities

这个模块提供了在 CMake 构建系统中集成 Node.js/npm 项目的**通用**工具宏。

可以用于构建任何基于 npm 的前端项目（Vue.js、React、Angular 等）。

## 📋 功能

- 自动检测 Node.js 和 npm
- 自动安装 npm 依赖
- 构建任何 npm 项目
- 将构建输出复制到指定目录
- 创建自定义构建目标
- 跨平台支持（Windows、Linux、macOS）

## 🔧 宏定义

### `__find_nodejs()`

查找系统中的 Node.js 和 npm 可执行文件。

```cmake
__find_nodejs()
```

设置变量：
- `NODEJS_EXECUTABLE` - Node.js 可执行文件路径
- `NODEJS_VERSION` - Node.js 版本
- `NPM_EXECUTABLE` - npm 可执行文件路径
- `NPM_VERSION` - npm 版本

### `__build_nodejs_project(source_dir output_dir [FORCE])`

**通用宏**：构建任何 Node.js/npm 项目并复制到输出目录。

**参数：**
- `source_dir` - Node.js 项目源代码目录（必须包含 package.json）
- `output_dir` - 构建输出目录
- `FORCE` - 可选，强制重新构建

**示例：**

```cmake
# 在 CMakeLists.txt 中
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 构建 Vue.js 项目（Fluidd）
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# 构建 React 项目
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/admin
    ${CMAKE_SOURCE_DIR}/resources/admin
)

# 强制重新构建
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/my-app
    ${CMAKE_SOURCE_DIR}/resources/my-app
    FORCE
)
```

**行为：**
1. 检查 Node.js 和 npm 是否可用
2. 检查是否需要构建（dist/index.html 是否存在）
3. 如果需要，安装 npm 依赖（如果 node_modules 不存在）
4. 运行 `npm run build`
5. 将 `dist/` 目录复制到输出目录

### `__add_nodejs_build_target(target_name source_dir output_dir)`

**通用函数**：创建一个自定义 CMake 目标来构建任何 Node.js/npm 项目。

**参数：**
- `target_name` - CMake 目标名称（自定义）
- `source_dir` - Node.js 项目源代码目录
- `output_dir` - 构建输出目录

**示例：**

```cmake
# 创建目标：rebuild-fluidd
__add_nodejs_build_target(
    rebuild-fluidd
    ${CMAKE_SOURCE_DIR}/frontend/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# 创建目标：rebuild-admin
__add_nodejs_build_target(
    rebuild-admin
    ${CMAKE_SOURCE_DIR}/frontend/admin-panel
    ${CMAKE_SOURCE_DIR}/resources/admin
)

# 创建目标：rebuild-docs
__add_nodejs_build_target(
    rebuild-docs
    ${CMAKE_SOURCE_DIR}/docs-site
    ${CMAKE_SOURCE_DIR}/public/docs
)
```

**使用：**

```bash
# 重新构建前端
cmake --build . --target rebuild-fluidd
cmake --build . --target rebuild-admin

# 或在 Visual Studio 中右键项目选择 "生成"
```

### `__npm_install(source_dir)`

在指定目录安装 npm 依赖。

```cmake
__npm_install(${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd)
```

### `__npm_build(source_dir build_script)`

运行 npm 构建脚本。

```cmake
__npm_build(${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd "build")
```

## 💡 使用场景

### 场景 1：在 CMake 配置时自动构建前端

```cmake
# src/CMakeLists.txt
include(${CMAKE_SOURCE_DIR}/cmake_tools/entry/nodejs/nodejs.cmake)

# 配置时构建一次（适用于任何 npm 项目）
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/my-app      # 你的前端项目
    ${CMAKE_SOURCE_DIR}/resources/web        # 输出目录
)
```

**优点：** 首次配置时自动构建，适用于任何 Vue/React/Angular 项目
**缺点：** 每次 CMake 重新配置都会检查

### 场景 2：创建可选的构建目标

```cmake
# src/CMakeLists.txt
include(${CMAKE_SOURCE_DIR}/cmake_tools/entry/nodejs/nodejs.cmake)

# 创建可选目标（通用方式）
__add_nodejs_build_target(
    rebuild-frontend                          # 自定义目标名
    ${CMAKE_SOURCE_DIR}/frontend/my-app      # 任何 npm 项目
    ${CMAKE_SOURCE_DIR}/resources/web        # 输出目录
)

# 使用：cmake --build . --target rebuild-frontend
```

**优点：** 按需构建，不影响常规构建流程，适用于任何前端框架
**缺点：** 需要手动触发

### 场景 3：作为主目标的依赖（推荐）

```cmake
# src/CMakeLists.txt
include(${CMAKE_SOURCE_DIR}/cmake_tools/entry/nodejs/nodejs.cmake)

# 创建前端构建目标（通用）
__add_nodejs_build_target(
    my-frontend
    ${CMAKE_SOURCE_DIR}/frontend/app
    ${CMAKE_SOURCE_DIR}/resources/web
)

# 主目标
add_executable(MyApp main.cpp)
target_link_libraries(MyApp PRIVATE ...)

# 可选：让主目标依赖前端构建
# add_dependencies(MyApp my-frontend)
```

**优点：** 灵活控制，可以选择是否自动构建，适用于任何项目结构
**缺点：** 需要额外配置依赖关系

## 🌟 通用性说明

这些宏是**完全通用的**，适用于：

- ✅ Vue.js 项目（如 Fluidd）
- ✅ React 项目
- ✅ Angular 项目
- ✅ Svelte 项目
- ✅ 任何使用 npm 构建的前端项目
- ✅ 文档生成工具（VuePress、Docusaurus 等）
- ✅ 静态站点生成器（Nuxt、Next.js 等）

**要求：**
- 项目根目录有 `package.json`
- `package.json` 中定义了 `build` 脚本
- 构建输出在 `dist/` 目录
- `dist/index.html` 作为入口文件

## 🎯 最佳实践

### 推荐配置（通用模板）

```cmake
# src/CMakeLists.txt
include(${CMAKE_SOURCE_DIR}/cmake_tools/entry/nodejs/nodejs.cmake)

# 1. 尝试在配置时构建（如果未构建）
# 适用于任何 npm 项目
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/my-app     # 你的项目路径
    ${CMAKE_SOURCE_DIR}/resources/web       # 输出路径
)

# 2. 创建可选的重新构建目标
__add_nodejs_build_target(
    rebuild-frontend                        # 自定义名称
    ${CMAKE_SOURCE_DIR}/frontend/my-app
    ${CMAKE_SOURCE_DIR}/resources/web
)

# 3. 创建主应用目标
add_executable(MyApp ${SRCS})
target_link_libraries(MyApp PRIVATE ...)

# 4. 可选：部署资源
# （根据你的项目需求）
```

### Fluidd 项目示例

```cmake
# DesktopFluidd 的实际配置
include(${CMAKE_SOURCE_DIR}/cmake_tools/entry/nodejs/nodejs.cmake)

# 使用通用宏构建 Fluidd (Vue.js)
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# 创建重建目标
__add_nodejs_build_target(
    rebuild-fluidd
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# 主应用
__add_real_target(DesktopFluidd exe ...)

# 软链接资源
__add_symlink(DesktopFluidd ${CMAKE_SOURCE_DIR}/resources "")
```

### 工作流程

1. **首次构建：**
   ```bash
   cmake --preset vs2022-debug
   # 自动检测并构建 Fluidd 前端（如果需要）
   cmake --build out/vs2022-debug
   ```

2. **前端开发时：**
   ```bash
   # 使用开发服务器
   cd FluiddWebview2/fluidd
   npm run dev
   
   # 或重新构建
   cmake --build out/vs2022-debug --target rebuild-fluidd
   ```

3. **发布前：**
   ```bash
   # 强制重新构建前端
   cmake --build out/vs2022-release --target rebuild-fluidd
   cmake --build out/vs2022-release --config Release
   ```

## ⚠️ 注意事项

1. **Node.js 版本要求**
   - Fluidd 需要 Node.js 20.x 或 22.x
   - 建议使用 LTS 版本

2. **首次构建时间**
   - 首次运行 `npm install` 需要下载依赖，可能需要几分钟
   - 后续构建会更快

3. **网络问题**
   - 如果 npm 下载慢，可以配置国内镜像：
   ```bash
   npm config set registry https://registry.npmmirror.com
   ```

4. **Windows 路径问题**
   - CMake 会自动处理路径分隔符
   - 建议使用 CMake 变量而不是硬编码路径

5. **并行构建**
   - npm 构建是单线程的
   - 不要在 CMake 并行构建中多次触发 npm

## 🔍 调试

### 启用详细输出

```cmake
set(CMAKE_VERBOSE_MAKEFILE ON)
```

### 检查 Node.js

```cmake
__find_nodejs()
message(STATUS "Node.js: ${NODEJS_EXECUTABLE}")
message(STATUS "npm: ${NPM_EXECUTABLE}")
```

### 手动测试

```bash
cd FluiddWebview2/fluidd
npm install
npm run build
# 检查 dist/ 目录
```

## 📚 相关文档

- [Node.js 官方文档](https://nodejs.org/docs/)
- [npm 文档](https://docs.npmjs.com/)
- [CMake 自定义命令](https://cmake.org/cmake/help/latest/command/add_custom_command.html)
- [Fluidd 构建指南](../../FLUIDD_INTEGRATION.md)

---

**版本:** 1.0  
**最后更新:** 2025-10-11

