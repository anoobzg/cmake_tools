
import sys
import os
import getopt
from pathlib import Path

sys.path.append(sys.path[0] + '/../../pmodules/')

execute_dir = Path(sys.path[0]).resolve()
source_dir = execute_dir.parent.parent.parent

import log
logger = log.create_log('pack')
logger.info("execute_dir : {}".format(execute_dir))
logger.info("source_dir : {}".format(source_dir))

preset_name = 'ninja-release'
cmake_args = ""
#parse args
try:
    opts, args = getopt.getopt(sys.argv[1:], shortopts='', longopts=['cmake_args=','preset_name='])
    logger.info("getopt.getopt -> : {}".format(str(opts)))
except getopt.GetoptError:
    logger.warning("_parse_args error.")
    sys.exit(2)
for opt, arg in opts:
    if opt == '--cmake_args':
        cmake_args = arg 
    if opt == '--preset_name':
        preset_name = arg 

binary_dir =  source_dir.joinpath('./out/{}/build/'.format(preset_name))
install_dir = source_dir.joinpath('./out/{}/install/'.format(preset_name))

logger.info("binary_dir : {}".format(binary_dir))
logger.info("install_dir : {}".format(install_dir))

import executor
cmd = "cmake --preset={0} {1} && cmake --build --preset={0} && cmake --install {2}".format(preset_name, cmake_args, binary_dir)
executor.run(cmd, True, logger)

os.chdir(binary_dir.absolute())
make_cmd = 'ninja'
cmd = "{0} package".format(make_cmd)
executor.run(cmd, True, logger)