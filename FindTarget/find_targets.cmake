get_property(_is_defined GLOBAL PROPERTY _find_target_find_targets_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_find_targets_defined)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)

function(_find_target_find_targets)
	cmake_parse_arguments(ARG
		""
		"TARGETS_VAR;OPTIONAL_TARGETS_VAR;OUT_VAR"
		"TARGETS;OPTIONAL_TARGETS"
		${ARGN}
	)
	# find targets
	if(ARG_TARGETS)
		foreach(TARGETS IN LISTS ARG_TARGETS)
			if(TARGET ${TARGETS})
				list(APPEND ${ARG_TARGETS_VAR} ${TARGETS})
			else()
				set(${ARG_OUT_VAR} False PARENT_SCOPE)
				return()
			endif()
		endforeach()
	endif()
	# find optional targets
	foreach(TARGETS IN LISTS ARG_OPTIONAL_TARGETS)
		if(TARGET ${TARGETS})
			list(APPEND ${ARG_OPTIONAL_TARGETS_VAR} ${TARGETS})
		endif()
	endforeach()
	# set output result
	set(${ARG_OUT_VAR} True PARENT_SCOPE)
	_find_target_move_to_parent_scope(
		${ARG_TARGETS_VAR}
		${ARG_OPTIONAL_TARGETS_VAR}
	)
endfunction()
