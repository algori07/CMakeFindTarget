get_property(_is_defined GLOBAL PROPERTY _find_target_use_add_subdirectory_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_use_add_subdirectory_defined)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/find_targets.cmake)

macro(_find_target_use_add_subdirectory PREFIX)
	cmake_parse_arguments(__ARG
		"QUIET;CONFIG_ONLY;USE_VARIABLE;EXCLUDE_FROM_ALL;SYSTEM"
		"PATH"
		"TARGETS;OPTIONAL_TARGETS"
		${ARGN}
	)
	
	if(NOT DEFINED __ARG_PATH)
		message(FATAL_ERROR "PATH argument must be provided.")
	endif()
	
	if(NOT __ARG_CONFIG_ONLY AND NOT DEFINED __ARG_TARGETS)
		message(FATAL_ERROR "TARGETS argument must be provided.")
	endif()
	
	if(__ARG_USE_VARIABLE)
		string(CONFIGURE "${__ARG_PATH}" __TMP @ONLY)
		set(__ARG_PATH ${__TMP})
		unset(__TMP)
	endif()
	
	
	if(NOT __ARG_QUIET)
		message(STATUS "Try finding ${PREFIX} inside ${__ARG_PATH}...")
	endif()
	
	if(NOT EXISTS "${__ARG_PATH}/CMakeLists.txt")
		if(NOT __ARG_QUIET)
			message(STATUS "Directory not found or not contain CMakeLists.txt.")
		endif()
		set(__ISRETURN 1)
	else()
		file(SHA256 "${__ARG_PATH}/CMakeLists.txt" __FILE_HASH)
		string(SHA256 __HASH "${__FILE_HASH};${ARGN}")
		_find_target_contain_hash(${__HASH} __ISRETURN)
		if(__ISRETURN AND NOT __ARG_QUIET)
			message(STATUS "Skip finding ${PREFIX} inside ${__ARG_PATH}.")
			message(STATUS "Remove ${_FIND_TARGET_TMP_DIR}/skiphash/${hash} to disable skipping.")
		endif()
	endif()
	
	
	
	if(NOT __ISRETURN)
		string(SHA256 __PATH_HASH "${__ARG_PATH}")
		get_property(__IS_CONFIGURED GLOBAL PROPERTY _find_target_add_subdirectory_${__PATH_HASH} DEFINED
		)
		if(NOT __IS_CONFIGURED)
			_find_target_convert_to_blankable(__ARG_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
			_find_target_convert_to_blankable(__ARG_SYSTEM SYSTEM)
			add_subdirectory(
				"${__ARG_PATH}"
				"${_FIND_TARGET_TMP_DIR}/subbuild/${__PATH_HASH}"
				${__ARG_EXCLUDE_FROM_ALL}
				${__ARG_SYSTEM}
			)
			define_property(GLOBAL PROPERTY _find_target_add_subdirectory_${__PATH_HASH})
		endif()
		unset(__PATH_HASH)
	endif()
	
	if(__IS_RETURN)
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
	
	if(__ISRETURN)
		# do nothing
	elseif(${PREFIX}_FOUND)
		if(NOT __ARG_QUIET)
			message(STATUS "${PREFIX} found inside subdirectory ${__ARG_PATH}.")
		endif()
	else()
		_find_target_create_hash(${__HASH})
		message(FATAL_ERROR
			"${__ARG_PATH}/CMakeLists.txt found but required targets not found."
			"Since add_subdirectory() was run. You need to reconfigure manual to skip this step."
			"This happend when dev provide wrong directory to be configurated."
			"Delete file ${_FIND_TARGET_TMP_DIR}/skiphash/${__HASH} "
			"to disable skipping."
		)
	endif()
	
	unset(__HASH)
	unset(__ISRETURN)
	
	unset(__ARG_QUIET)
	unset(__ARG_CONFIG_ONLY)
	unset(__ARG_USE_VARIABLE)
	unset(__ARG_EXCLUDE_FROM_ALL)
	unset(__ARG_SYSTEM)
	unset(__ARG_PATH)
	unset(__ARG_TARGETS)
	unset(__ARG_OPTIONAL_TARGETS)
endmacro() # end use_subdirectory