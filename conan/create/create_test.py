import os
import util

if __name__ == "__main__":
    name, version = util.parse_recipe()
    p = util.search_recipe_path(name, version)
    
    print('create conan package : {}'.format(p))
    cmd = "start /B /wait conan create {} -s build_type=Debug --version {}".format(str(p), version)
    os.system(cmd)