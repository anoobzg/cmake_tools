import os
import util

if __name__ == "__main__":
    name, version = util.parse_recipe()
    p = util.search_recipe_path(name, version)
    
    print('create conan package : {}'.format(p))
    cmd = "start /B /wait conan create {} -s build_type=Debug -s compiler.runtime=static --version {}".format(str(p), version)
    os.system(cmd)
    cmd = "start /B /wait conan create {} -s build_type=Release -s compiler.runtime=static --version {}".format(str(p), version)
    os.system(cmd)

    cmd = "start /B /wait conan upload -r artifactory {}/{} ".format(name, version)
    os.system(cmd)