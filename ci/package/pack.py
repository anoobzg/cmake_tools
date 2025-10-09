
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

# -DPROJECT_VERSION_MAJOR=%MAJOR% ^
# -DPROJECT_VERSION_MINOR=%MINOR% ^
# -DPROJECT_VERSION_PATCH=%PATCH% ^
# -DPROJECT_BUILD_ID=%BUILD% ^
# -DPROJECT_VERSION_EXTRA=%VERSION_EXTRA% ^

preset_name = 'ninja-release'
cmake_args = ""

# param
version_major = 0
version_minor = 0
version_patch = 0
version_extra = "Unknown"
custom_type = ""

build_id = ""

#parse args
try:
    opts, args = getopt.getopt(sys.argv[1:], shortopts='',
                                longopts=['custom_type=',
                                          'version_major=',
                                          'version_minor=',
                                          'version_patch=',
                                          'version_extra=',
                                          'build_id=',
                                          'preset_name=']
                                          )
    logger.info("getopt.getopt -> : {}".format(str(opts)))
except getopt.GetoptError:
    logger.warning("_parse_args error.")
    sys.exit(2)
for opt, arg in opts:
    if opt == '--version_major':
        version_major = arg
    elif opt == '--version_minor':
        version_minor = arg
    elif opt == '--version_patch':
        version_patch = arg
    elif opt == '--version_extra':
        version_extra = arg
    elif opt == '--build_id':
        build_id = arg
    elif opt == '--preset_name':
        preset_name = arg 
    elif opt == '--custom_type':
        custom_type = arg

# build_id use git hash, if not set
if build_id == "":
    pass
    # import git
    # build_id = git.get_main_hash(source_dir)

cmake_args = "-DPROJECT_VERSION_MAJOR={0} "\
            "-DPROJECT_VERSION_MINOR={1} "\
            "-DPROJECT_VERSION_PATCH={2} "\
            "-DPROJECT_BUILD_ID={3} "\
            "-DPROJECT_VERSION_EXTRA={4} "\
            "-DCUSTOM_TYPE={5}"\
                .format(version_major, 
                        version_minor, 
                        version_patch, 
                        build_id, 
                        version_extra,
                        custom_type
                        )

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