#!/bin/bash

# 定义应用包路径
APP_PATH="PiocreatBox.app"

# 递归查找所有可执行文件和动态库
find "$APP_PATH" -type f \( -perm +111 -o -name "*.dylib" -o -name "*.so" \) -print0 | while IFS= read -r -d '' file; do
    # 检查是否为 Mach-O 文件
    if file "$file" | grep -q "Mach-O"; then
        echo "=============================================="
        echo "检查文件: $file"
        echo "依赖列表:"
        otool -L "$file"
        echo ""
    fi
done
