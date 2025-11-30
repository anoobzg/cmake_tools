script_folder="D:\code\Gitee\game-dev\cmake_tools\conan\create\cccl\all\test_package"
echo "echo Restoring environment" > "$script_folder\deactivate_conanbuildenv-debug-x86_64.sh"
for v in MSYS_ROOT MSYS_BIN PATH CC CXX LD
do
    is_defined="true"
    value=$(printenv $v) || is_defined="" || true
    if [ -n "$value" ] || [ -n "$is_defined" ]
    then
        echo export "$v='$value'" >> "$script_folder\deactivate_conanbuildenv-debug-x86_64.sh"
    else
        echo unset $v >> "$script_folder\deactivate_conanbuildenv-debug-x86_64.sh"
    fi
done


export MSYS_ROOT="/d/conan-cache/p/msys2f33247fcfc934/p/bin/msys64"
export MSYS_BIN="/d/conan-cache/p/msys2f33247fcfc934/p/bin/msys64/usr/bin"
export PATH="/d/conan-cache/p/msys2f33247fcfc934/p/bin:/d/conan-cache/p/msys2f33247fcfc934/p/bin/msys64/usr/bin:/d/conan-cache/p/b/cccl18145ee6f3b7e/p/bin:$PATH"
export CC="sh D:\conan-cache\p\b\cccl18145ee6f3b7e\p\bin\cccl --cccl-muffle"
export CXX="sh D:\conan-cache\p\b\cccl18145ee6f3b7e\p\bin\cccl --cccl-muffle"
export LD="sh D:\conan-cache\p\b\cccl18145ee6f3b7e\p\bin\cccl --cccl-muffle"