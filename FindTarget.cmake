set(_FIND_TARGET_TMP_DIR "${CMAKE_BINARY_DIR}/_find_target")

macro(move_to_parent_scope list_var)
	foreach(var ${list_var})
		if(DEFINED ${var})
			set(${var} "${${var}}" PARENT_SCOPE)
		endif()
	endforeach()
endmacro()
macro(move_to_global_scope list_var)
	foreach(var ${list_var})
		if(DEFINED ${var})
			# do something
		endif()
	endforeach()
endmacro()
macro(convert_to_blankable var value)
	if(DEFINED ${var})
		if(${var})
			set(${var} "${value}")
		else()
			set(${var} "")
		endif()
	endif()
endmacro()

macro(_find_target_create_hash hash)
	file(WRITE
		"${_FIND_TARGET_TMP_DIR}/skiphash/${hash}"
		${ARGN}
	)
endmacro()

macro(_find_target_read_hash hash outvar)
	file(READ
		"${_FIND_TARGET_TMP_DIR}/skiphash/${hash}"
		${outvar}
		${ARGN}
	)
endmacro()

macro(_find_target_read_list_hash hash outvar)
	file(STRINGS
		"${_FIND_TARGET_TMP_DIR}/skiphash/${hash}"
		${outvar}
		${ARGN}
	)
endmacro()


macro(_find_target_contain_hash hash outvar)
	if(EXISTS "${_FIND_TARGET_TMP_DIR}/skiphash/${hash}")
		set(${outvar} True)
	endif()
endmacro()

macro(_find_target_remove_hash hash)
	file(REMOVE_RECURSE
		"${_FIND_TARGET_TMP_DIR}/skiphash/${hash}"
	)
endmacro()

function(_find_target_auto_remove_deleted_hash hash1)
	file(GLOB HASHS "${_FIND_TARGET_TMP_DIR}/hash/*")
	foreach(HASH ${HASHS})
		if(NOT ${HASH} IN_LIST _find_target_RECORDED_HASHS)
			file(REMOVE_RECURSE ${HASH})
		endif()
	endforeach()
endfunction()

function(_find_target_find_targets)
	cmake_parse_arguments(ARG
		""
		"TARGETS_VAR;OPTIONAL_TARGETS_VAR;OUT_VAR"
		"TARGETS;OPTIONAL_TARGETS"
		${ARGN}
	)
	# find targets
	if(ARG_TARGETS)
		foreach(TARGETS ${ARG_TARGETS})
			if(TARGET ${TARGETS})
				list(APPEND ${ARG_TARGETS_VAR} ${TARGETS})
			else()
				set(${ARG_OUT_VAR} False PARENT_SCOPE)
				return()
			endif()
		endforeach()
	endif()
	# find optional targets
	foreach(TARGETS ${ARG_OPTIONAL_TARGETS})
		if(TARGET ${TARGETS})
			list(APPEND ${ARG_OPTIONAL_TARGETS_VAR} ${TARGETS})
		endif()
	endforeach()
	# set output result
	set(${ARG_OUT_VAR} True PARENT_SCOPE)
	move_to_parent_scope(
		${ARG_TARGETS_VAR}
		${ARG_OPTIONAL_TARGETS_VAR}
	)
endfunction()

function(_find_target_use_find_package PREFIX)
	cmake_parse_arguments(ARG
		"CONFIG_ONLY;QUIET"
		"PACKAGE_NAME"
		"COMPONENTS;OPTIONAL_COMPONENTS;TARGETS;OPTIONAL_TARGETS"
		${ARGN}
	)
	
	if(NOT ARG_PACKAGE_NAME)
		message(FATAL_ERROR "PACKAGE_NAME argument need to be provided")
	endif()
	if(NOT ARG_CONFIG_ONLY AND NOT ARG_TARGETS)
		message(FATAL_ERROR "TARGETS argument need to be provided")
	endif()
	
	if(${ARG_PACKAGE_NAME} STREQUAL ${PREFIX})
		message(FATAL_ERROR "Both PREFIX and PACKAGE_NAME must to be different.")
	endif()
	
	list(APPEND LIST_TO_HASH "ARGN_HASH;${ARGN}")
	list(APPEND LIST_TO_HASH "MODULE_PATH;${CMAKE_MODULE_PATH}")
	
	list(APPEND LIST_TO_HASH "PACKAGE_NAME_ROOT;${${ARG_PACKAGE_NAME}_ROOT}")
	list(APPEND LIST_TO_HASH "PACKAGE_NAME_DIR;${${ARG_PACKAGE_NAME}_DIR}")
	list(APPEND LIST_TO_HASH "PREFIX_PATH;${CMAKE_PREFIX_PATH}")
	if(APPLE)
		list(APPEND LIST_TO_HASH "FRAMEWORK_PATH;${CMAKE_FRAMEWORK_PATH}")
		list(APPEND LIST_TO_HASH "APPBUNDLE_PATH;${CMAKE_APPBUNDLE_PATH}")
	endif()
	
	list(APPEND LIST_TO_HASH "ENV_PACKAGE_NAME_ROOT;$ENV{${ARG_PACKAGE_NAME}_ROOT}")
	list(APPEND LIST_TO_HASH "ENV_PACKAGE_NAME_DIR;$ENV{${ARG_PACKAGE_NAME}_DIR}")
	list(APPEND LIST_TO_HASH "ENV_PREFIX_PATH;$ENV{CMAKE_PREFIX_PATH}")
	if(APPLE)
		list(APPEND LIST_TO_HASH "ENV_FRAMEWORK_PATH;$ENV{CMAKE_FRAMEWORK_PATH}")
		list(APPEND LIST_TO_HASH "ENV_APPBUNDLE_PATH;$ENV{CMAKE_APPBUNDLE_PATH}")
	endif()
	
	list(APPEND LIST_TO_HASH "ENV_SYSTEM_PREFIX_PATH;$ENV{CMAKE_SYSTEM_PREFIX_PATH}")
	if(APPLE)
		list(APPEND LIST_TO_HASH "ENV_SYSTEM_FRAMEWORK_PATH;$ENV{CMAKE_SYSTEM_FRAMEWORK_PATH}")
		list(APPEND LIST_TO_HASH "ENV_SYSTEM_APPBUNDLE_PATH;$ENV{CMAKE_SYSTEM_APPBUNDLE_PATH}")
	endif()
	
	list(APPEND LIST_TO_HASH "ENV_PATH;$ENV{PATH}")
	
	string(SHA256 HASH "${LIST_TO_HASH}")
	_find_target_contain_hash(${HASH} ISCONTAIN)
	if(ISCONTAIN)
		_find_target_read_list_hash(${HASH} FILE_PATH)
		list(POP_FRONT FILE_PATH FILE_OLD_HASH)
		if(EXISTS "${FILE_PATH}")
			file(SHA256 "${FILE_PATH}" FILE_HASH)
			if(${FILE_OLD_HASH} STREQUAL ${FILE_HASH})
				set(ISSKIP True)
			else()
				_find_target_remove_hash(${HASH})
			endif()
		endif()
		if(ISSKIP)
			if(NOT ARG_QUIET)
				message(STATUS "Skip finding ${PREFIX} by find_package with package ${ARG_PACKAGE_NAME}.")
				message(STATUS "Remove ${_FIND_TARGET_TMP_DIR}/skiphash/${HASH} to disable skipping.")
			endif()
			return()
		endif()
	endif()
	if(NOT ARG_QUIET)
		message(STATUS "Try finding ${PREFIX} using find_package with package ${ARG_PACKAGE_NAME}...")
	endif()
	
	find_package(${ARG_PACKAGE_NAME}
		COMPONENTS ${ARG_COMPONENTS}
		OPTIONAL_COMPONENTS ${ARG_OPTIONAL_COMPONENTS}
		QUIET
		GLOBAL
	)
	
	if(NOT ${ARG_PACKAGE_NAME}_FOUND)
		if(NOT ARG_QUIET)
			message(STATUS "Package ${ARG_PACKAGE_NAME} not found.")
		endif()
		return()
	elseif(ARG_CONFIG_ONLY)
		_find_target_find_targets(
			OUT_VAR ${PREFIX}_FOUND
			OPTIONAL_TARGETS_VAR ${PREFIX}_OPTIONAL_TARGETS
			OPTIONAL_TARGETS
				${ARG_TARGETS}
				${ARG_OPTIONAL_TARGETS}
		)
	else()
		_find_target_find_targets(
			OUT_VAR ${PREFIX}_FOUND
			TARGETS_VAR ${PREFIX}_TARGETS
			TARGETS ${ARG_TARGETS}
			OPTIONAL_TARGETS_VAR ${PREFIX}_OPTIONAL_TARGETS
			OPTIONAL_TARGETS ${ARG_OPTIONAL_TARGETS}
		)
	endif()
	if(${PREFIX}_FOUND)
		if(NOT ARG_QUIET)
			message(STATUS "Package ${ARG_PACKAGE_NAME} found.")
		endif()
		move_to_parent_scope(
			${PREFIX}_FOUND
			${PREFIX}_TARGETS
			${PREFIX}_OPTIONAL_TARGETS
		)
		return()
	elseif(${ARG_PACKAGE_NAME}_FOUND)
		file(SHA256 "${${ARG_PACKAGE_NAME}_CONFIG}" FILE_HASH)
		_find_target_create_hash(${HASH}
			"${FILE_HASH}\n${${ARG_PACKAGE_NAME}_CONFIG}"
		)
		message(FATAL_ERROR
			"Package ${ARG_PACKAGE_NAME} found but required target not found.\n"
			"Since find_package() was runned, you need to reconfigure "
			"manual to skip this step.\n"
			"This happend when wrong package was provided to be found.\n"
			"Delete file ${_FIND_TARGET_TMP_DIR}/skiphash/${HASH} to disable skipping."
		)
	elseif(NOT ARG_QUIET)
		message(STATUS "Package ${ARG_PACKAGE_NAME} not found.")
	endif()
endfunction() # end use_find_package

function(_find_target_use_pkgconfig PREFIX)
	cmake_parse_arguments(ARG
		"QUIET"
		""
		"MODULE_SPEC"
		${ARGN}
	)
	if(NOT ARG_QUIET)
		message(STATUS "Try finding ${PREFIX} using pkg-config with module ${ARG_MODULE_SPEC}...")
	endif()
	# handle pkg-config
	if(NOT COMMAND pkg_check_modules)
		find_package(PkgConfig QUIET)
		if(NOT PkgConfig_FOUND)
			message(STATUS "pkg-config not found.")
			return()
		endif()
	endif()
	
	pkg_check_modules(_find_target_pkgconfig_${PREFIX}
		QUIET
		IMPORTED_TARGET
		GLOBAL
		${ARG_MODULE_SPEC}
	)
	if(TARGET PkgConfig::_find_target_pkgconfig_${PREFIX})
		set(${PREFIX}_FOUND True)
		list(APPEND ${PREFIX}_TARGETS PkgConfig::_find_target_pkgconfig_${PREFIX})
	endif()
	
	if(${PREFIX}_FOUND)
		if(NOT ARG_QUIET)
			message(STATUS "Module ${ARG_MODULE_SPEC} found.")
		endif()
		move_to_parent_scope(${PREFIX}_FOUND)
		move_to_parent_scope(${PREFIX}_TARGETS)
	elseif(NOT ARG_QUIET)
		message(STATUS "Module ${ARG_MODULE_SPEC} not found.")
	endif()
endfunction() # end use_pkgconfig

function(_find_target_use_subdirectory PREFIX)
	cmake_parse_arguments(ARG
		"QUIET;CONFIG_ONLY;EXCLUDE_FROM_ALL"
		""
		"PATH;PATH_VAR;TARGETS;OPTIONAL_TARGETS"
		${ARGN}
	)
	if(NOT DEFINED ARG_PATH AND NOT DEFINED ARG_PATH_VAR)
		message(FATAL_ERROR "PATH or PATH_VAR argument must be provided.")
	endif()
	if(DEFINED ARG_PATH_VAR)
		set(ARG_PATH "${${ARG_PATH_VAR}}")
	endif()
	
	if(NOT EXISTS "${ARG_PATH}/CMakeLists.txt")
		if(NOT ARG_QUIET)
			message(STATUS "Directory not found or not contain CMakeLists.txt.")
		endif()
		return()
	endif()
	
	file(SHA256 "${ARG_PATH}/CMakeLists.txt" FILE_HASH)
	string(SHA256 HASH "${FILE_HASH};${ARGN}")
	_find_target_contain_hash(${HASH} ISSKIP)
	if(ISSKIP)
		if(NOT ARG_QUIET)
			message(STATUS "Skip finding ${PREFIX} inside ${ARG_PATH}.")
			message(STATUS "Remove ${_FIND_TARGET_TMP_DIR}/skiphash/${hash} to disable skipping.")
		endif()
		return()
	endif()
	
	if(NOT ARG_QUIET)
		message(STATUS "Try finding ${PREFIX} inside ${ARG_PATH}...")
	endif()
	
	# handle add_subdirectory
	if(NOT ARG_CONFIG_ONLY AND NOT ARG_TARGETS)
		message(FATAL_ERROR "TARGETS argument need to be provided")
	endif()
	
	convert_to_blankable(ARG_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
	add_subdirectory("${ARG_PATH}" ${ARG_EXCLUDE_FROM_ALL})
	
	if(ARG_CONFIG_ONLY)
		_find_target_find_targets(
			OUT_VAR ${PREFIX}_FOUND
			OPTIONAL_TARGETS_VAR ${PREFIX}_OPTIONAL_TARGETS
			OPTIONAL_TARGETS
				${ARG_TARGETS}
				${ARG_OPTIONAL_TARGETS}
		)
	else()
		_find_target_find_targets(
			OUT_VAR ${PREFIX}_FOUND
			TARGETS_VAR ${PREFIX}_TARGETS
			TARGETS ${ARG_TARGETS}
			OPTIONAL_TARGETS_VAR ${PREFIX}_OPTIONAL_TARGETS
			OPTIONAL_TARGETS ${ARG_OPTIONAL_TARGETS}
		)
	endif()
	
	if(${PREFIX}_FOUND)
		if(NOT ARG_QUIET)
			message(STATUS "${PREFIX} found inside subdirectory.")
		endif()
		move_to_parent_scope(${PREFIX}_FOUND)
		if(${PREFIX}_TARGETS)
			move_to_parent_scope(${PREFIX}_TARGETS)
		endif()
		if(${PREFIX}_OPTIONAL_TARGETS)
			move_to_parent_scope(${PREFIX}_OPTIONAL_TARGETS)
		endif()
	else()
		# string(SHA256 MODE_ARGS_HASH "${ARG_CONFIG_ONLY};${MODE_ARGS}")
		_find_target_create_hash(${HASH})
		message(FATAL_ERROR
			"${ARG_PATH}/CMakeLists.txt found but required targets not found.\n"
			"Since add_subdirectory() was run. You need to reconfigure manual to skip "
			"this step\n"
			"This happend when dev provide wrong directory to be configurated."
			"Delete file ${_FIND_TARGET_TMP_DIR}/skiphash/${HASH} "
			"to disable skipping."
		)
	endif()
endfunction() # end use_subdirectory

function(_find_target_configure_git PREFIX)
	cmake_parse_arguments(ARG
		""
		"GIT_EXECUTABLE;CLONED_DIR_VAR"
		"REPOSITORY;TAG"
		${ARGN}
	)
	
	if(NOT ARG_REPOSITORY)
		message(FATAL_ERROR "REPOSITORY url must be provided.")
	endif()
	
	if(NOT ARG_GIT_EXECUTABLE AND NOT GIT_EXECUTABLE)
		find_package(Git QUIET)
		if(DEFINED GIT_EXECUTABLE)
			set(ARG_GIT_EXECUTABLE "${GIT_EXECUTABLE}")
			if(NOT ARG_QUIET)
				message(STATUS "Git found.")
			endif()
		else()
			if(NOT ARG_QUIET)
				message(STATUS "Git not found.")
			endif()
			return()
		endif()
	elseif(NOT ARG_GIT_EXECUTABLE)
		set(ARG_GIT_EXECUTABLE "${GIT_EXECUTABLE}")
	endif()
	
	convert_to_blankable(ARG_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
	foreach(GIT_PREFIX REPO_URL TAG IN ZIP_LISTS
		ARG_PREFIX ARG_REPOSITORY ARG_TAG)
	block()
		if(NOT DEFINED REPO_URL)
			break()
		endif()
		
		if(NOT ARG_QUIET)
			message(STATUS "Cloning repository ${REPO_URL} with tag ${TAG}...")
		endif()
		
		string(SHA256 URL_HASH ${REPO_URL})
		set(CLONE_DIR "${_FIND_TARGET_TMP_DIR}/gitclone/${URL_HASH}")
		
		if(EXISTS "${CLONE_DIR}" AND NOT IS_DIRECTORY "${CLONE_DIR}")
			if(NOT ARG_QUIET)
				message(STATUS "Couldn't clone if file ${CLONE_DIR} exist.")
				message(STATUS "Remove file...")
			endif()
			file(REMOVE "${CLONE_DIR}")
			if(EXISTS "${CLONE_DIR}")
				if(NOT ARG_QUIET)
					message(WARNING "Couldn't remove file ${CLONE_DIR}.")
					message(STATUS "Skip clone ${REPO_URL}.")
				endif()
				continue()
			endif()
		elseif(IS_DIRECTORY "${CLONE_DIR}")
			execute_process(
				COMMAND ${ARG_GIT_EXECUTABLE}
					remote
					get-url
					origin
					--
				WORKING_DIRECTORY
					"${CLONE_DIR}"
				RESULT_VARIABLE RET
				OUTPUT_VARIABLE OLD_REPO_URL
			)
			string(STRIP "${OLD_REPO_URL}" OLD_REPO_URL)
			if(NOT RET EQUAL 0 OR NOT OLD_REPO_URL STREQUAL REPO_URL)
				if(NOT ARG_QUIET)
					message(STATUS "${CLONE_DIR} exist but not from ${REPO_URL}.")
					message(STATUS "Remove clone directory...")
				endif()
				file(REMOVE_RECURSE "${CLONE_DIR}")
				if(NOT EXISTS "${CLONE_DIR}")
					if(NOT ARG_QUIET)
						message(STATUS "Removed.")
					endif()
				else()
					if(NOT ARG_QUIET)
						message(WARNING "Couldn't remove directory ${CLONE_DIR}.")
						message(STATUS "Skip clone ${REPO_URL}.")
					endif()
					continue()
				endif()
			else()
				execute_process(
					COMMAND ${ARG_GIT_EXECUTABLE}
						fetch
						--
					WORKING_DIRECTORY
						"${CLONE_DIR}"
					RESULT_VARIABLE RET
				)
				if(NOT RET EQUAL 0)
					if(NOT ARG_QUIET)
						message(STATUS "Couldn't fetch in the cloned repo.")
						message(STATUS "Remove clone directory...")
					endif()
					file(REMOVE_RECURSE "${CLONE_DIR}")
					if(NOT EXISTS "${CLONE_DIR}")
						if(NOT ARG_QUIET)
							message(STATUS "Removed.")
						endif()
					elseif(NOT ARG_QUIET)
						message(WARNING "Couldn't remove directory ${CLONE_DIR}.")
						message(STATUS "Skip clone ${REPO_URL}.")
						continue()
					endif()
				endif()
			endif() # check if repo's url the same as REPO_URL
		endif() # check if clone directory is exist
		unset(RET)
		
		if(NOT IS_DIRECTORY "${CLONE_DIR}")
			execute_process(
				COMMAND ${ARG_GIT_EXECUTABLE}
					clone
					--no-checkout
					--config advice.detachedHead=false
					${REPO_URL}
					"${CLONE_DIR}"
					--
				RESULT_VARIABLE RET
			)
			if(NOT RET EQUAL 0)
				if(NOT ARG_QUIET)
					message(STATUS "Failed to clone repository ${REPO_URL}.")
					message(STATUS "Cleaning up cloned directory...")
				endif()
				file(REMOVE_RECURSE "${CLONE_DIR}")
				if(NOT ARG_QUIET)
					message(STATUS "Cleaned up.")
				endif()
				continue()
			endif()
		endif()
		unset(RET)
		
		# checkout tag
		execute_process(
			COMMAND ${ARG_GIT_EXECUTABLE}
				checkout ${TAG}
				--
			WORKING_DIRECTORY
				"${CLONE_DIR}"
			RESULT_VARIABLE RET
		)
		if(NOT RET EQUAL 0)
			if(NOT ARG_QUIET)
				message(STATUS "Failed to checkout repository ${REPO_URL}.")
			endif()
			continue()
		endif()
		unset(RET)
		
		message(STATUS "Clone repository ${REPO_URL} successfully.")
		set(${ARG_CLONED_DIR_VAR} "${CLONE_DIR}" PARENT_SCOPE)
		break()
		
	endblock()
	endforeach()
	
	move_to_parent_scope(${ARG_CLONED_DIR_VAR})
	
endfunction() # end use_git

function(_find_target_configure_archive PREFIX)
	cmake_parse_arguments(MODE_ARG
		"EXCLUDE_FROM_ALL"
		""
		"PATH;TARGETS;OPTIONAL_TARGETS"
		${MODE_ARGS}
	)
	# handle download/extract archive
endfunction() # end use_archive

function(find_target PREFIX)
	set(ARGUMENTS ${ARGN})
	
	set(FUNC_ARGS "")
	while(ARGUMENTS)
		list(POP_FRONT ARGUMENTS ARG)
		if(${ARG} STREQUAL "--")
			break()
		endif()
		list(APPEND FUNC_ARGS ${ARG})
	endwhile()
	unset(ARG)
	
	cmake_parse_arguments(ARG
		"QUIET;REQUIRED"
		""
		""
		${FUNC_ARGS}
	)
	# handle function arguments
	
	# set(${PREFIX}_FOUND False)
	# set(${PREFIX}_TARGETS "")
	
	# string(HASH FUNC_ARGS_HASH ${ARGN})
	
	set(MODE_ARGS "")
	foreach(ARG ${ARGUMENTS})
		if(NOT ${ARG} STREQUAL "--")
			list(APPEND MODE_ARGS ${ARG})
		else()
			list(POP_FRONT MODE_ARGS MODE)
			
			# handle each mode
			if(${MODE} STREQUAL "USE_FIND_PACKAGE") ############################# FIND PACKAGE
				_find_target_use_find_package(${PREFIX} ${MODE_ARGS})
			elseif(${MODE} STREQUAL "USE_PKGCONFIG") ######################### PKGCONFIG
				_find_target_use_pkgconfig(${PREFIX} ${MODE_ARGS})
			elseif(${MODE} STREQUAL "USE_SUBDIRECTORY") ############################### SUBDIRECTORY
				_find_target_use_subdirectory(${PREFIX} ${MODE_ARGS})
			elseif(${MODE} STREQUAL "CONFIGURE_GIT")
				_find_target_configure_git(${PREFIX} ${MODE_ARGS})
				message(STATUS "")
			elseif(${MODE} STREQUAL "CONFIGURE_ARCHIVE")
				_find_target_configure_archive(${PREFIX} ${MODE_ARGS})
			else()
				message(FATAL_ERROR "Unknowed ${MODE} mode")
			endif()
			set(MODE_ARGS "")
			
			if(${PREFIX}_FOUND)
				break()
			endif()
			
			# continue()
		endif()
	endforeach()
	
	if(${PREFIX}_FOUND)
		if(NOT ARG_QUIET)
			message(STATUS "${PREFIX} found.")
		endif()
		move_to_parent_scope(${PREFIX}_FOUND)
		if(${PREFIX}_TARGETS)
			move_to_parent_scope(${PREFIX}_TARGETS)
		endif()
		if(${PREFIX}_OPTIONAL_TARGETS)
			move_to_parent_scope(${PREFIX}_OPTIONAL_TARGETS)
		endif()
	elseif(ARG_REQUIRED)
		message(FATAL_ERROR "${PREFIX} not found.")
	endif()
endfunction()
