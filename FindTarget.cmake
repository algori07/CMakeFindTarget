get_property(_is_defined GLOBAL PROPERTY _find_target_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_defined)

set(_FIND_TARGET_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/FindTarget")
set(_FIND_TARGET_TMP_DIR "${CMAKE_BINARY_DIR}/_find_target")

include(${_FIND_TARGET_PREFIX_DIR}/use_find_package.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/use_pkgconfig.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/use_add_subdirectory.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/configure_git.cmake)
include(${_FIND_TARGET_PREFIX_DIR}/configure_archive.cmake)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)

macro(find_target PREFIX)
	set(__ARGUMENTS ${ARGN})
	
	set(FUNC_ARGS "")
	while(__ARGUMENTS)
		list(POP_FRONT __ARGUMENTS __ARG)
		if(${__ARG} STREQUAL "--")
			break()
		endif()
		list(APPEND FUNC_ARGS ${__ARG})
	endwhile()
	unset(__ARG)
	
	cmake_parse_arguments(__ARG
		"QUIET;REQUIRED"
		""
		""
		${FUNC_ARGS}
	)
	
	_find_target_convert_to_blankable(ARG_QUIET QUIET)
	
	unset(${PREFIX}_FOUND)
	unset(${PREFIX}_TARGETS)
	unset(${PREFIX}_OPTIONAL_TARGETS)
	set(__MODE_ARGS "")
	foreach(__ARG IN LISTS __ARGUMENTS)
		if(NOT ${__ARG} STREQUAL "--")
			list(APPEND __MODE_ARGS "${__ARG}")
		else()
			list(POP_FRONT __MODE_ARGS __MODE)
			
			
			# handle each mode
			if(${__MODE} STREQUAL "USE_FIND_PACKAGE")
				_find_target_use_find_package(${PREFIX} ${__ARG_QUIET} ${__MODE_ARGS})
				
			elseif(${__MODE} STREQUAL "USE_PKGCONFIG")
				_find_target_use_pkgconfig(${PREFIX} ${__ARG_QUIET} ${__MODE_ARGS})
				
			elseif(${__MODE} STREQUAL "USE_SUBDIRECTORY")
				_find_target_use_add_subdirectory(${PREFIX} ${__ARG_QUIET} ${__MODE_ARGS})
				
			elseif(${__MODE} STREQUAL "CONFIGURE_GIT")
				_find_target_configure_git(${PREFIX} ${__ARG_QUIET} ${__MODE_ARGS})
				
			elseif(${__MODE} STREQUAL "CONFIGURE_ARCHIVE")
				_find_target_configure_archive(${PREFIX} ${__ARG_QUIET} ${__MODE_ARGS})
				
			else()
				message(FATAL_ERROR "Unknowed ${__MODE} mode")
			endif()
			set(__MODE_ARGS "")
			unset(__MODE)
			
			if(${PREFIX}_FOUND)
				break()
			endif()
		endif()
	endforeach()
	unset(__MODE_ARGS)
	
	if(${PREFIX}_FOUND)
		if(NOT ARG_QUIET)
			message(STATUS "${PREFIX} found.")
		endif()
	elseif(ARG_REQUIRED)
		message(FATAL_ERROR "${PREFIX} not found.")
	endif()
	
	unset(__ARG_QUIET)
	unset(__ARG_REQUIRED)
endmacro()
