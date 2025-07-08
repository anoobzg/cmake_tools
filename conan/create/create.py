import os
import util

if __name__ == "__main__":
    name, version = util.parse_recipe()
    p = util.search_recipe_path(name, version)
    
    util.modify_yml_file(p, name, version)
    
    print('create conan package : {}'.format(p))
    util.conan_create(p, version, "Debug")
    util.conan_create(p, version, "Release")

    util.conan_upload(name, version)