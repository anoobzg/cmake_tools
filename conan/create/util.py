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
    # Get the absolute path of the directory containing this util.py file
    # This is the same directory as create.py (cmake_tools/conan/create/)
    util_dir = pathlib.Path(__file__).parent.absolute()
    
    # Build absolute path to recipe root
    recipe_root = util_dir / name
    config_file = recipe_root / "config.yml"
    print("Searching recipe config_file: {}".format(config_file))
    try:
        with open(config_file, 'r') as file:
            data = yaml.safe_load(file)
            if 'versions' in data:
                versions = data['versions']
                if version in versions:
                    ver = versions[version]
                    recipe_root = recipe_root / ver['folder']

    except FileNotFoundError:
        print("FileNotFoundError : {}".format(config_file))

    return recipe_root

def modify_yml_file(recipe_root, name, version):
    if name == "opencv":
        return
    
    import yaml
    conandata_yml = recipe_root.joinpath("conandata.yml")
    try:
        data = {}
        with open(conandata_yml, 'r') as file:
            data = yaml.safe_load(file)

        all_versions = data['sources'][version]
        if 'url' in all_versions:
            urls = all_versions['url']
            is_list = isinstance(urls, list)
            url = urls[0] if is_list else urls
            if not is_list:
                print("Using Single URL: {}".format(url))
            elif is_list:
                print("Using First URL: {}".format(url))
            
            is_url_file = True if url.startswith('file:///') else False
            file = None
            if not is_url_file:    
                folder = url.replace('https://', '')
                file = 'file:///D://code//Gitea//out//' + folder
            else:
                print("File URL already exists in conandata.yml: {}".format(url))
                file = url
                
            real_path = file.replace('file:///', '')
            if not os.path.exists(real_path):
                print("Downloading file: {0} -> {1}".format(url, real_path))
                os.system(f"curl -L -o {real_path} --create-dirs --retry 3  {url}")

            if not is_url_file:
                if is_list:
                    if not file in data['sources'][version]['url']:
                        print("Adding file to conandata.yml: {}".format(file))
                        data['sources'][version]['url'].insert(0, file)
                else:
                    print("Adding file to conandata.yml: {}".format(real_path))
                    data['sources'][version]['url'] = [file, url]

            with open(conandata_yml, 'w', encoding='utf-8') as f:
                yaml.dump_all(documents=[data], stream=f, allow_unicode=True)

                

    except FileNotFoundError:
        print("FileNotFoundError : {}".format(conandata_yml))
    except ValueError as e:
        print("ValueError : {}".format(e))

def conan_upload(name, version):
    system = platform.system()
    cmd = "conan upload -r artifactory {}/{} ".format(name, version)

    if system == "Windows":
        cmd = "start /B /wait {}".format(cmd) 
    os.system(cmd)

def conan_create(recipe_path, version, build_type, is_static=False):
    system = platform.system()
    
    cmd = "conan create {} -s build_type={} --version {}".format(str(recipe_path), build_type, version)
    if is_static == True:
        cmd = "{} -s compiler.runtime=static".format(cmd)

    if system == "Windows":
        cmd = "start /B /wait {}".format(cmd)

    os.system(cmd)

def conan_create_cross(recipe_path, version, build_type, host_profile, is_static=False):
    system = platform.system()
    
    cmd = "conan create {} -s build_type={} --version {}".format(str(recipe_path), build_type, version)
    if is_static == True:
        cmd = "{} -s compiler.runtime=static".format(cmd)

    cmd = "{} --profile:build=default --profile:host={}".format(cmd, host_profile)

    if system == "Windows":
        cmd = "start /B /wait {}".format(cmd)

    os.system(cmd)
    