import os
import sys
import pathlib
import platform

def parse_recipe():
    name = 'default'
    version = '0.0.0'
    if len(sys.argv) == 2:
        name = sys.argv[1]
    elif len(sys.argv) == 3:
        name = sys.argv[1]
        version = sys.argv[2] 

    return (name, version)

def search_recipe_path(name, version) -> pathlib.Path:
    import yaml
    recipe_root = pathlib.Path(name)
    config_file = recipe_root.joinpath("config.yml")
    try:
        with open(config_file, 'r') as file:
            data = yaml.safe_load(file)
            if 'versions' in data:
                versions = data['versions']
                if version in versions:
                    ver = versions[version]
                    recipe_root = recipe_root.joinpath(ver['folder'])

    except FileNotFoundError:
        print("FileNotFoundError : {}".format(config_file))

    return recipe_root

def conan_upload(name, version):
    system = platform.system()
    cmd = "conan upload -r artifactory {}/{} ".format(name, version)

    if system == "Windows":
        cmd = "start /B /wait {}".format(cmd) 
    os.system(cmd)

def conan_create(recipe_path, version, build_type, is_static=False):
    cmd = "conan create {} -s build_type={} --version {}".format(str(recipe_path), build_type, version)
    if is_static == True:
        cmd = "{} -s compiler.runtime=static".format(cmd)

    if system == "Windows":
        cmd = "start /B /wait {}".format(cmd)
         
    os.system(cmd)
    