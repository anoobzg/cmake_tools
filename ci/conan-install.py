import sys;

if __name__ == "__main__":
    directory = sys.path[0]
    sys.path.append(sys.path[0] + '/../python/')

    working_path = sys.argv[1]
    project_path = sys.argv[2]
    channel = sys.argv[3]
    
    import osSystem
    osSystem.conan_install(working_path, project_path, channel, build=False, only_root=True, update=False)