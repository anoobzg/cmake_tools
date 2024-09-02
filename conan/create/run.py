import os
import sys
import subprocess

if len(sys.argv) == 2:
    recipe = sys.argv[1]
    cmd = "start /B /wait conan create {} -s build_type=Debug".format(recipe)
    os.system(cmd)
    print("continue ...........................")
    
    cmd = "start /B /wait conan create {} -s build_type=Release".format(recipe)
    os.system(cmd)
else:
    print('specify a recipe.')