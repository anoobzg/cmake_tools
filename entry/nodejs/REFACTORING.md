# Node.js CMake 工具重构说明

## 🔄 重构概述

将原本专门为 Fluidd 设计的 CMake 宏重构为**通用的 Node.js/npm 项目构建工具**。

## 📝 变更详情

### 重命名的函数

| 旧名称（已废弃） | 新名称（推荐使用） | 状态 |
|-----------------|-------------------|------|
| `__build_fluidd_frontend()` | `__build_nodejs_project()` | ✅ 向后兼容 |
| `__add_fluidd_build_target()` | `__add_nodejs_build_target()` | ✅ 向后兼容 |

### 向后兼容性

旧的函数名称仍然可用，但会显示废弃警告：

```cmake
# 旧代码仍然可以工作
__build_fluidd_frontend(src dst)
# 警告：__build_fluidd_frontend is deprecated, use __build_nodejs_project instead

# 推荐使用新名称
__build_nodejs_project(src dst)
```

## 🎯 设计目标

### 之前
- ❌ 名称与 Fluidd 绑定
- ❌ 暗示只能用于 Fluidd 项目
- ❌ 不够通用

### 现在
- ✅ 完全通用的命名
- ✅ 适用于任何 npm 项目
- ✅ 清晰的用途说明
- ✅ 向后兼容旧代码

## 🌐 支持的项目类型

现在明确支持：

### 前端框架
- Vue.js (Fluidd, Vite, Nuxt)
- React (Create React App, Next.js)
- Angular (Angular CLI)
- Svelte (SvelteKit)
- Preact
- Solid.js

### 文档工具
- VuePress
- Docusaurus
- Docsify
- Nextra

### 静态站点生成器
- Next.js (SSG)
- Nuxt (SSG)
- Gatsby
- Astro

### 其他
- 任何有 `package.json` 和 `npm run build` 的项目

## 📚 迁移指南

### 无需修改的情况

如果你的代码使用旧函数名，**无需立即修改**，会继续正常工作：

```cmake
# 这段代码仍然有效
__build_fluidd_frontend(
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)
```

### 推荐的迁移方式

逐步迁移到新名称：

#### 步骤 1：更新函数调用

```cmake
# 之前
__build_fluidd_frontend(src dst)

# 之后
__build_nodejs_project(src dst)
```

#### 步骤 2：更新注释

```cmake
# 之前
# Build Fluidd frontend

# 之后
# Build Node.js project (Fluidd Vue.js application)
```

#### 步骤 3：测试

```bash
cmake --preset vs2022-debug
cmake --build out/vs2022-debug
```

## 🔧 使用示例

### 通用模板

```cmake
include(cmake_tools/entry/nodejs/nodejs.cmake)

# 构建任何 npm 项目
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/my-app
    ${CMAKE_SOURCE_DIR}/resources/web
)

# 创建重建目标
__add_nodejs_build_target(
    rebuild-frontend
    ${CMAKE_SOURCE_DIR}/frontend/my-app
    ${CMAKE_SOURCE_DIR}/resources/web
)
```

### Vue.js (Fluidd) 示例

```cmake
# Fluidd 特定配置
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd    # Vue.js 项目
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)

__add_nodejs_build_target(
    rebuild-fluidd
    ${CMAKE_SOURCE_DIR}/FluiddWebview2/fluidd
    ${CMAKE_SOURCE_DIR}/resources/fluidd
)
```

### React 示例

```cmake
# React 项目
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/admin-panel     # React 项目
    ${CMAKE_SOURCE_DIR}/resources/admin
)

__add_nodejs_build_target(
    rebuild-admin
    ${CMAKE_SOURCE_DIR}/frontend/admin-panel
    ${CMAKE_SOURCE_DIR}/resources/admin
)
```

### Angular 示例

```cmake
# Angular 项目
__build_nodejs_project(
    ${CMAKE_SOURCE_DIR}/frontend/dashboard       # Angular 项目
    ${CMAKE_SOURCE_DIR}/resources/dashboard
)

__add_nodejs_build_target(
    rebuild-dashboard
    ${CMAKE_SOURCE_DIR}/frontend/dashboard
    ${CMAKE_SOURCE_DIR}/resources/dashboard
)
```

## 📖 更新的文档

以下文档已更新以反映通用性：

- ✅ `nodejs.cmake` - 添加通用性说明
- ✅ `README.md` - 更新为通用文档
- ✅ `EXAMPLES.md` - 添加多种框架示例
- ✅ `src/CMakeLists.txt` - 使用新名称并添加注释

## ⚙️ 技术细节

### 实现方式

```cmake
# 新的通用宏
macro(__build_nodejs_project source_dir output_dir)
    # ... 通用实现 ...
endmacro()

# 向后兼容的别名
macro(__build_fluidd_frontend source_dir output_dir)
    message(DEPRECATION "__build_fluidd_frontend is deprecated, use __build_nodejs_project instead")
    __build_nodejs_project(${source_dir} ${output_dir} ${ARGN})
endmacro()
```

### 废弃警告

使用旧名称时会看到：

```
CMake Deprecation Warning at cmake_tools/entry/nodejs/nodejs.cmake:175 (message):
  __build_fluidd_frontend is deprecated, use __build_nodejs_project instead
```

## 🎉 优点

### 1. 通用性
- 可用于任何 npm 项目
- 不限于特定框架

### 2. 清晰性
- 函数名称表明用途
- 代码更易理解

### 3. 可扩展性
- 易于添加新功能
- 支持更多项目类型

### 4. 向后兼容
- 旧代码继续工作
- 平滑的迁移路径

### 5. 文档完善
- 清晰的使用说明
- 多种示例代码

## 📊 影响范围

### 已更新的文件

```
cmake_tools/entry/nodejs/
├── nodejs.cmake          ✅ 重构核心宏
├── README.md             ✅ 更新为通用文档
├── EXAMPLES.md           ✅ 添加多框架示例
└── REFACTORING.md        ✅ 本文档

src/
└── CMakeLists.txt        ✅ 使用新 API

文档/
├── QUICKSTART.md         ✅ 更新说明
└── NODE_CMAKE_INTEGRATION.md  ✅ 更新总结
```

### 未受影响的功能

- ✅ 所有现有功能保持不变
- ✅ 构建行为完全相同
- ✅ 配置参数完全兼容
- ✅ 错误处理逻辑不变

## 🔮 未来计划

### 短期
- [ ] 在更多示例中展示通用性
- [ ] 添加更多前端框架的配置示例
- [ ] 创建模板项目

### 长期
- [ ] 支持自定义构建脚本名称
- [ ] 支持自定义输出目录名称
- [ ] 添加构建优化选项
- [ ] 集成测试运行器

## 📞 问题反馈

如果遇到问题：

1. 检查是否使用了正确的新名称
2. 查看 `README.md` 了解用法
3. 参考 `EXAMPLES.md` 中的示例
4. 查看 `ARCHITECTURE.md` 了解设计

## ✅ 检查清单

迁移完成检查：

- [ ] 更新所有 `__build_fluidd_frontend` 为 `__build_nodejs_project`
- [ ] 更新所有 `__add_fluidd_build_target` 为 `__add_nodejs_build_target`
- [ ] 更新相关注释说明通用性
- [ ] 测试构建流程
- [ ] 确认没有废弃警告（可选）

---

**重构日期:** 2025-10-11  
**版本:** 2.0  
**向后兼容:** ✅ 是  
**状态:** ✅ 完成

