script_folder="/home/anoob/Public/work/mgba/cmake/conan/create/m4/all/test_package"
echo "echo Restoring environment" > "$script_folder/deactivate_conanbuildenv-release-armv8.sh"
for v in M4 PATH
do
    is_defined="true"
    value=$(printenv $v) || is_defined="" || true
    if [ -n "$value" ] || [ -n "$is_defined" ]
    then
        echo export "$v='$value'" >> "$script_folder/deactivate_conanbuildenv-release-armv8.sh"
    else
        echo unset $v >> "$script_folder/deactivate_conanbuildenv-release-armv8.sh"
    fi
done


export M4="/home/anoob/.conan2/p/b/m47a2f239969802/p/bin/m4"
export PATH="/home/anoob/.conan2/p/b/m47a2f239969802/p/bin:$PATH"