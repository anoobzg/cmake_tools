import os
import util

if __name__ == "__main__":
    name, version = util.parse_recipe()
    p = util.search_recipe_path(name, version)
    
    print('create conan package : {}'.format(p))
    util.conan_create(p, version, "Debug")