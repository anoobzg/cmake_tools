import os
import util

if __name__ == "__main__":
    name, version = util.parse_recipe()
    p = util.search_recipe_path(name, version)
    
    util.modify_yml_file(p, name, version)
    
    print('create conan package : {}'.format(p))
    util.conan_create_cross(p, version,  "Debug", "mips")
    util.conan_create_cross(p, version, "Release", "mips")

    util.conan_upload(name, version)