# Node.js CMake 宏使用示例

本文档提供 `nodejs.cmake` 宏的实际使用示例。

## 📚 基础示例

### 示例 1：自动构建（配置时）

最简单的方式，在 CMake 配置时自动构建前端（如果需要）。

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(MyProject)

# 包含 Node.js 工具
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 自动构建 Fluidd 前端（如果 dist 不存在）
__build_fluidd_frontend(
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd    # 源代码目录
    ${CMAKE_SOURCE_DIR}/resources/fluidd          # 输出目录
)

# 创建主应用
add_executable(MyApp main.cpp)
```

**使用：**
```bash
cmake -B build
# 如果前端未构建，会自动构建
cmake --build build
```

### 示例 2：创建可选构建目标

创建一个独立的构建目标，按需手动触发。

```cmake
# CMakeLists.txt
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 创建前端构建目标
__add_fluidd_build_target(
    rebuild-frontend                              # 目标名称
    ${CMAKE_SOURCE_DIR}/frontend                  # 源代码
    ${CMAKE_SOURCE_DIR}/resources/web             # 输出
)

add_executable(MyApp main.cpp)
```

**使用：**
```bash
cmake -B build
cmake --build build

# 需要时手动重新构建前端
cmake --build build --target rebuild-frontend
```

### 示例 3：组合使用

同时使用自动构建和手动目标。

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 1. 配置时自动构建（如果需要）
__build_fluidd_frontend(
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# 2. 创建手动重建目标
__add_fluidd_build_target(
    rebuild-fluidd
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# 3. 创建应用
add_executable(MyApp main.cpp)
```

**工作流程：**
```bash
# 首次构建 - 自动构建前端
cmake -B build
cmake --build build

# 开发时 - 手动重建前端
cmake --build build --target rebuild-fluidd

# 或强制重新配置
cmake -B build -DCMAKE_BUILD_TYPE=Release
```

## 🎯 高级示例

### 示例 4：强制重新构建

即使前端已存在也强制重新构建。

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 添加选项
option(FORCE_REBUILD_FRONTEND "Force rebuild frontend" OFF)

if(FORCE_REBUILD_FRONTEND)
    __build_fluidd_frontend(
        ${CMAKE_SOURCE_DIR}/frontend
        ${CMAKE_SOURCE_DIR}/resources/web
        FORCE  # 强制重建
    )
else()
    __build_fluidd_frontend(
        ${CMAKE_SOURCE_DIR}/frontend
        ${CMAKE_SOURCE_DIR}/resources/web
    )
endif()
```

**使用：**
```bash
# 正常构建
cmake -B build

# 强制重建前端
cmake -B build -DFORCE_REBUILD_FRONTEND=ON
```

### 示例 5：条件构建

根据构建类型决定是否构建前端。

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 只在 Release 构建时重新构建前端
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Release build - rebuilding frontend")
    __build_fluidd_frontend(
        ${CMAKE_SOURCE_DIR}/frontend
        ${CMAKE_SOURCE_DIR}/resources/web
        FORCE
    )
else()
    message(STATUS "Debug build - using existing frontend")
    __build_fluidd_frontend(
        ${CMAKE_SOURCE_DIR}/frontend
        ${CMAKE_SOURCE_DIR}/resources/web
    )
endif()
```

### 示例 6：多个前端项目

构建多个独立的前端项目。

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 主前端
__build_fluidd_frontend(
    ${CMAKE_SOURCE_DIR}/frontend/main
    ${CMAKE_SOURCE_DIR}/resources/main
)

__add_fluidd_build_target(
    rebuild-main-frontend
    ${CMAKE_SOURCE_DIR}/frontend/main
    ${CMAKE_SOURCE_DIR}/resources/main
)

# 管理界面
__build_fluidd_frontend(
    ${CMAKE_SOURCE_DIR}/frontend/admin
    ${CMAKE_SOURCE_DIR}/resources/admin
)

__add_fluidd_build_target(
    rebuild-admin-frontend
    ${CMAKE_SOURCE_DIR}/frontend/admin
    ${CMAKE_SOURCE_DIR}/resources/admin
)
```

**使用：**
```bash
# 重建主前端
cmake --build build --target rebuild-main-frontend

# 重建管理界面
cmake --build build --target rebuild-admin-frontend
```

### 示例 7：作为依赖项

让主应用依赖前端构建。

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 创建前端构建目标
__add_fluidd_build_target(
    frontend-build
    ${CMAKE_SOURCE_DIR}/frontend
    ${CMAKE_SOURCE_DIR}/resources/web
)

# 创建主应用
add_executable(MyApp main.cpp)

# 让应用依赖前端构建（每次构建应用时都会重建前端）
add_dependencies(MyApp frontend-build)
```

**注意：** 这会导致每次构建应用都重建前端，可能不是期望的行为。

### 示例 8：自定义构建脚本

如果 package.json 中使用了不同的构建脚本名称。

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 手动调用底层宏
__find_nodejs()

if(NODEJS_EXECUTABLE AND NPM_EXECUTABLE)
    # 安装依赖
    __npm_install(${CMAKE_SOURCE_DIR}/frontend)
    
    # 运行自定义构建脚本
    __npm_build(${CMAKE_SOURCE_DIR}/frontend "build:prod")
    
    # 手动复制输出
    file(COPY ${CMAKE_SOURCE_DIR}/frontend/build/
         DESTINATION ${CMAKE_SOURCE_DIR}/resources/web/)
endif()
```

## 🔧 实际项目示例

### DesktopFluidd 项目

这是本项目的实际配置：

```cmake
# src/CMakeLists.txt
set(SRCS wxapp_example.cpp)

# Find wxWidgets
if(NOT TARGET wxWidgets::wxWidgets)
    find_package(wxWidgets CONFIG REQUIRED)
endif()

# Include Node.js build utilities
include(${CMAKE_SOURCE_DIR}/cmake_tools/entry/nodejs/nodejs.cmake)

# Build Fluidd frontend at configure time (if not already built)
__build_fluidd_frontend(
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# Create optional target for rebuilding frontend
__add_fluidd_build_target(
    rebuild-fluidd
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

# Create main application target
__add_real_target(DesktopFluidd exe 
    SOURCE ${SRCS}
    LIB FluiddWebview2 wxWidgets::wxWidgets
)

# Create symlink for resources
__add_symlink(DesktopFluidd ${CMAKE_SOURCE_DIR}/resources "")
```

**工作流程：**

```bash
# 1. 首次配置 - 自动构建前端
cmake --preset vs2022-debug

# 2. 构建应用
cmake --build out/vs2022-debug

# 3. 运行
out/vs2022-debug/bin/Debug/DesktopFluidd.exe

# 4. 需要时重建前端
cmake --build out/vs2022-debug --target rebuild-fluidd

# 5. 或使用批处理脚本
build-fluidd-frontend.bat
```

## 💡 最佳实践

### ✅ 推荐做法

1. **组合使用自动和手动构建**
   ```cmake
   __build_fluidd_frontend(...)       # 自动
   __add_fluidd_build_target(...)     # 手动
   ```

2. **清晰的命名**
   ```cmake
   __add_fluidd_build_target(rebuild-fluidd ...)  # 好
   __add_fluidd_build_target(f ...)               # 差
   ```

3. **添加状态消息**
   ```cmake
   message(STATUS "Frontend will be built if needed")
   __build_fluidd_frontend(...)
   ```

4. **使用 CMake 变量**
   ```cmake
   set(FRONTEND_SRC ${CMAKE_SOURCE_DIR}/frontend)
   set(FRONTEND_OUT ${CMAKE_SOURCE_DIR}/resources/web)
   __build_fluidd_frontend(${FRONTEND_SRC} ${FRONTEND_OUT})
   ```

### ❌ 避免的做法

1. **不要让主目标依赖前端构建**
   ```cmake
   # 不推荐 - 会导致每次都重建前端
   add_dependencies(MyApp frontend-build)
   ```

2. **不要硬编码路径**
   ```cmake
   # 差
   __build_fluidd_frontend(
       "C:/Projects/MyApp/frontend"
       "C:/Projects/MyApp/resources"
   )
   
   # 好
   __build_fluidd_frontend(
       ${CMAKE_SOURCE_DIR}/frontend
       ${CMAKE_SOURCE_DIR}/resources
   )
   ```

3. **不要忘记检查 Node.js**
   ```cmake
   # 如果手动使用底层宏，先检查
   __find_nodejs()
   if(NOT NODEJS_EXECUTABLE)
       message(WARNING "Node.js not found!")
       return()
   endif()
   ```

## 🐛 调试技巧

### 查看 Node.js 信息

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)
__find_nodejs()

message(STATUS "=== Node.js Information ===")
message(STATUS "Node.js executable: ${NODEJS_EXECUTABLE}")
message(STATUS "Node.js version: ${NODEJS_VERSION}")
message(STATUS "npm executable: ${NPM_EXECUTABLE}")
message(STATUS "npm version: ${NPM_VERSION}")
```

### 测试构建

```cmake
# 创建测试目标
__add_fluidd_build_target(test-build ${SRC} ${OUT})

# 单独运行
# cmake --build build --target test-build
```

### 详细输出

```bash
# CMake 详细模式
cmake -B build --log-level=DEBUG

# 或
cmake -B build --trace
```

## 📚 参考

- [主 README](README.md)
- [CMake 文档](https://cmake.org/documentation/)
- [npm 文档](https://docs.npmjs.com/)

---

**提示:** 如果遇到问题，先尝试手动构建前端确认 Node.js 环境正常：

```bash
cd frontend
npm install
npm run build
```

