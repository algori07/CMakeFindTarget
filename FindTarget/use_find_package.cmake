get_property(_is_defined GLOBAL PROPERTY _find_target_use_find_package_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_use_find_package_defined)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/skip_hash_func.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/find_targets.cmake)

macro(_find_target_use_find_package PREFIX)
	cmake_parse_arguments(__ARG
		"CONFIG_ONLY;QUIET"
		"PACKAGE_NAME"
		"TARGETS;OPTIONAL_TARGETS;ADDITIONAL_ARGUMENTS"
		${ARGN}
	)
	
	if(NOT __ARG_PACKAGE_NAME)
		message(FATAL_ERROR "PACKAGE_NAME argument need to be provided")
	endif()
	if(NOT __ARG_CONFIG_ONLY AND NOT __ARG_TARGETS)
		message(FATAL_ERROR "TARGETS argument need to be provided")
	endif()
	
	if(${__ARG_PACKAGE_NAME} STREQUAL ${PREFIX})
		message(FATAL_ERROR "Both PREFIX and PACKAGE_NAME must to be different.")
	endif()
	
	list(APPEND __LIST_TO_HASH "ARGN_HASH;${ARGN}")
	list(APPEND __LIST_TO_HASH "MODULE_PATH;${CMAKE_MODULE_PATH}")
	
	list(APPEND __LIST_TO_HASH "PACKAGE_NAME_ROOT;${${__ARG_PACKAGE_NAME}_ROOT}")
	list(APPEND __LIST_TO_HASH "PACKAGE_NAME_DIR;${${__ARG_PACKAGE_NAME}_DIR}")
	list(APPEND __LIST_TO_HASH "PREFIX_PATH;${CMAKE_PREFIX_PATH}")
	if(APPLE)
		list(APPEND __LIST_TO_HASH "FRAMEWORK_PATH;${CMAKE_FRAMEWORK_PATH}")
		list(APPEND __LIST_TO_HASH "APPBUNDLE_PATH;${CMAKE_APPBUNDLE_PATH}")
	endif()
	
	list(APPEND __LIST_TO_HASH "ENV_PACKAGE_NAME_ROOT;$ENV{${__ARG_PACKAGE_NAME}_ROOT}")
	list(APPEND __LIST_TO_HASH "ENV_PACKAGE_NAME_DIR;$ENV{${__ARG_PACKAGE_NAME}_DIR}")
	list(APPEND __LIST_TO_HASH "ENV_PREFIX_PATH;$ENV{CMAKE_PREFIX_PATH}")
	if(APPLE)
		list(APPEND __LIST_TO_HASH "ENV_FRAMEWORK_PATH;$ENV{CMAKE_FRAMEWORK_PATH}")
		list(APPEND __LIST_TO_HASH "ENV_APPBUNDLE_PATH;$ENV{CMAKE_APPBUNDLE_PATH}")
	endif()
	
	list(APPEND __LIST_TO_HASH "ENV_SYSTEM_PREFIX_PATH;$ENV{CMAKE_SYSTEM_PREFIX_PATH}")
	if(APPLE)
		list(APPEND __LIST_TO_HASH "ENV_SYSTEM_FRAMEWORK_PATH;$ENV{CMAKE_SYSTEM_FRAMEWORK_PATH}")
		list(APPEND __LIST_TO_HASH "ENV_SYSTEM_APPBUNDLE_PATH;$ENV{CMAKE_SYSTEM_APPBUNDLE_PATH}")
	endif()
	
	list(APPEND __LIST_TO_HASH "ENV_PATH;$ENV{PATH}")
	
	string(SHA256 __HASH "${__LIST_TO_HASH}")
	unset(__LIST_TO_HASH)
	
	_find_target_contain_hash(${__HASH} __ISCONTAIN)
	if(__ISCONTAIN)
		_find_target_read_list_hash(${__HASH} __FILE_PATH)
		list(POP_FRONT __FILE_PATH __FILE_OLD_HASH)
		if(EXISTS "${__FILE_PATH}")
			file(SHA256 "${__FILE_PATH}" __FILE_HASH)
			if(${__FILE_OLD_HASH} STREQUAL ${__FILE_HASH})
				set(__ISSKIP True)
			else()
				_find_target_remove_hash(${__HASH})
			endif()
		endif()
		unset(__FILE_PATH)
		unset(__FILE_HASH)
		unset(__FILE_OLD_HASH)
	endif()
	if(NOT __ARG_QUIET)
		message(STATUS "Try finding ${PREFIX} using find_package with package ${__ARG_PACKAGE_NAME}...")
	endif()
	unset(__IS_CONTAIN)
	
	if(NOT __IS_SKIP)
		find_package(${__ARG_PACKAGE_NAME}
			COMPONENTS ${__ARG_COMPONENTS}
			OPTIONAL_COMPONENTS ${__ARG_OPTIONAL_COMPONENTS}
			QUIET
			GLOBAL
			${__ARG_ADDITIONAL_ARGUMENTS}
		)
	endif()
	
	if(__IS_SKIP OR NOT ${__ARG_PACKAGE_NAME}_FOUND)
		# do nothing
	elseif(__ARG_CONFIG_ONLY)
		_find_target_find_targets(
			OUT_VAR ${PREFIX}_FOUND
			OPTIONAL_TARGETS_VAR ${PREFIX}_OPTIONAL_TARGETS
			OPTIONAL_TARGETS
				${__ARG_TARGETS}
				${__ARG_OPTIONAL_TARGETS}
		)
	else()
		_find_target_find_targets(
			OUT_VAR ${PREFIX}_FOUND
			TARGETS_VAR ${PREFIX}_TARGETS
			TARGETS ${__ARG_TARGETS}
			OPTIONAL_TARGETS_VAR ${PREFIX}_OPTIONAL_TARGETS
			OPTIONAL_TARGETS ${__ARG_OPTIONAL_TARGETS}
		)
	endif()
	
	if(__IS_SKIP)
		if(NOT __ARG_QUIET)
			message(STATUS "Skip finding ${PREFIX} by find_package with package ${__ARG_PACKAGE_NAME}.")
			message(STATUS "Remove ${_FIND_TARGET_TMP_DIR}/skiphash/${__HASH} to disable skipping.")
		endif()
	elseif(NOT ${__ARG_PACKAGE_NAME}_FOUND)
		message(STATUS "Package ${__ARG_PACKAGE_NAME} not found.")
	elseif(${PREFIX}_FOUND)
		if(NOT __ARG_QUIET)
			message(STATUS "Package ${__ARG_PACKAGE_NAME} found.")
		endif()
	elseif(${__ARG_PACKAGE_NAME}_FOUND)
		file(SHA256 "${${__ARG_PACKAGE_NAME}_CONFIG}" __FILE_HASH)
		_find_target_create_hash(${__HASH}
			"${__FILE_HASH}\n${${__ARG_PACKAGE_NAME}_CONFIG}"
		)
		message(FATAL_ERROR
			"Package ${__ARG_PACKAGE_NAME} found but required target not found.\n"
			"Since find_package() was runned, you need to reconfigure manual to skip this step.\n"
			"This happend when wrong package was provided to be found.\n"
			"Delete file ${_FIND_TARGET_TMP_DIR}/skiphash/${__HASH} to disable skipping."
		)
	elseif(NOT __ARG_QUIET)
		message(STATUS "Package ${__ARG_PACKAGE_NAME} not found.")
	endif()
	
	unset(__HASH)
	unset(__IS_SKIP)
	
	unset(__ARG_CONFIG_ONLY)
	unset(__ARG_QUIET)
	unset(__ARG_PACKAGE_NAME)
	unset(__ARG_TARGETS)
	unset(__ARG_OPTIONAL_TARGETS)
	
endmacro() # end use_find_package