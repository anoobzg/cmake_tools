import os
import sys
import pathlib
import subprocess

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

if __name__ == "__main__":
    name, version = parse_recipe()
    p = search_recipe_path(name, version)
    
    print('create conan package : {}'.format(p))
    cmd = "start /B /wait conan create {} -s build_type=Debug --version {}".format(str(p), version)
    os.system(cmd)
    cmd = "start /B /wait conan create {} -s build_type=Release --version {}".format(str(p), version)
    os.system(cmd)