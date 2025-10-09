
FullExecPath=$PWD
pushd `dirname $0` > /dev/null
FullScriptPath=`pwd`
popd > /dev/null

echo "FullExecPath: $FullExecPath"
echo "FullScriptPath: $FullScriptPath"

conan_profile_dir=$FullScriptPath
deps_dir=$FullScriptPath/out/ninja-release-mips/build/deps
mkdir -p $deps_dir

conan install $conan_profile_dir --output-folder=$deps_dir -s build_type=Release --profile:build=default --profile:host=mips

source $deps_dir/conanbuild.sh

echo $CC

cmake -S . -B out/ninja-release-mips/build -DCMAKE_BUILD_TYPE=Release -G "Ninja"