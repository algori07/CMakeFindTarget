get_property(_is_defined GLOBAL PROPERTY _find_target_use_pkgconfig_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_use_pkgconfig_defined)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)

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
		_find_target_move_to_parent_scope(${PREFIX}_FOUND)
		_find_target_move_to_parent_scope(${PREFIX}_TARGETS)
	elseif(NOT ARG_QUIET)
		message(STATUS "Module ${ARG_MODULE_SPEC} not found.")
	endif()
endfunction() # end use_pkgconfig
