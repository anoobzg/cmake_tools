# utilities for files collection

macro(__files_group dir src)   #support 2 level
	file(GLOB _src ${dir}/*.h ${dir}/*.cpp ${dir}/*.cc ${dir}/*.c ${dir}/*.proto)
	file(GLOB children RELATIVE ${dir} ${dir}/*)
	foreach(child ${children})
		set(sub_dir ${dir}/${child})
		if(IS_DIRECTORY ${sub_dir})
			file(GLOB sub_src ${sub_dir}/*.h ${sub_dir}/*.cpp ${sub_dir}/*.cc ${sub_dir}/*.c)
			source_group(${child} FILES ${sub_src})
			set(_src ${_src} ${sub_src})
		endif()
	endforeach()
	set(${src} ${_src})
endmacro()

macro(__files_group_2 dir folder src)   #support 2 level
	file(GLOB _src ${dir}/*.h ${dir}/*.cpp)
	file(GLOB children RELATIVE ${dir} ${dir}/*)
	foreach(child ${children})
		set(sub_dir ${dir}/${child})
		if(IS_DIRECTORY ${sub_dir})
			file(GLOB sub_src ${sub_dir}/*.h ${sub_dir}/*.cpp)
			source_group(${folder}/${child} FILES ${sub_src})
			set(_src ${_src} ${sub_src})
		endif()
	endforeach()
	set(${src} ${_src})
endmacro()

function(__use_source_group)
	#message(STATUS "__collect_assign_source_group : ${ARGN}")
    foreach(source IN ITEMS ${ARGN})
		#message(STATUS "__collect_assign_source_group item: ${source}")
        if (IS_ABSOLUTE ${source})
            #message(WARNING "__collect_assign_source_group must be relative path.")
			string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" out "${source}")
			#message(STATUS "${source}  ----> ${out}")
			set(source ${out})
        endif()
        get_filename_component(SOURCE_PATH ${source} PATH)
        string(REPLACE "/" "\\" SOURCE_PATH_GROUP "${SOURCE_PATH}")
				
        source_group("${SOURCE_PATH_GROUP}" FILES "${source}")
    endforeach()
endfunction()

macro(__add_symlink target source_dir relative_path)
	get_filename_component(LAST_NAME "${source_dir}" NAME)
	__normal_message("...... ${source_dir}, ${LAST_NAME}")
	if (WIN32)
		add_custom_command(TARGET ${target} POST_BUILD
			COMMAND echo "Symlinking the resources directory ${source_dir} into $<TARGET_FILE_DIR:${target}>/${relative_path}/${LAST_NAME}"
			COMMAND ${CMAKE_COMMAND} -E make_directory "\"$<TARGET_FILE_DIR:${target}>/${relative_path}\""
			COMMAND if not exist "\"$<TARGET_FILE_DIR:${target}>/${relative_path}/${LAST_NAME}\"" "(" mklink /J "\"$<TARGET_FILE_DIR:${target}>/${relative_path}/${LAST_NAME}\"" "\"${source_dir}\"" ")"
		)
	else ()
		# Linux/Unix: use symbolic link
		add_custom_command(TARGET ${target} POST_BUILD
			COMMAND echo "Symlinking the resources directory ${source_dir} into $<TARGET_FILE_DIR:${target}>/${relative_path}/${LAST_NAME}"
			COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${target}>/${relative_path}"
			COMMAND test -e "$<TARGET_FILE_DIR:${target}>/${relative_path}/${LAST_NAME}" || ln -sf "${source_dir}" "$<TARGET_FILE_DIR:${target}>/${relative_path}/${LAST_NAME}"
		)
	endif ()
endmacro()

macro(__copy_directories_runtime target source_dirs)
	# __normal_message("__copy_directories_runtime from ${${source_dirs}}")
	foreach(source_dir ${${source_dirs}})
		file(GLOB COPY_FILES "${source_dir}/*.dll")
		# __normal_message("__copy_directories_runtime find ${COPY_FILES}")
		foreach(file ${COPY_FILES})
			get_filename_component(filename ${file} NAME)
			add_custom_command(TARGET ${target} POST_BUILD
				COMMAND echo "Copy runtime from ${file} into $<TARGET_FILE_DIR:${target}>"
				COMMAND ${CMAKE_COMMAND} -E copy "${file}" "\"$<TARGET_FILE_DIR:${target}>/${filename}\"" 
			)	
		endforeach()		
	endforeach()
endmacro()
