get_property(_is_defined GLOBAL PROPERTY _find_target_skip_hash_func_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_skip_hash_func_defined)

macro(_find_target_create_hash hash)
	file(WRITE
		"${_FIND_TARGET_TMP_DIR}/skiphash/${hash}"
		${ARGN}
	)
	set_property(GLOBAL APPEND PROPERTY _find_target_recorded_hashs ${hash})
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
	get_property(__RECORDED_HASHS GLOBAL PROPERTY _find_target_recorded_hashs)
	list(REMOVE_ITEM __RECORDED_HASHS ${hash})
	set_property(GLOBAL PROPERTY _find_target_recorded_hashs ${__RECORDED_HASHS})
endmacro()

function(_find_target_auto_remove_deleted_hash hash1)
	file(GLOB __HASHS "${_FIND_TARGET_TMP_DIR}/skiphash/*")
	get_property(__RECORDED_HASHS GLOBAL PROPERTY _find_target_recorded_hashs)
	foreach(__HASH_FILE IN LISTS __HASHS)
		if(NOT ${__HASH_FILE} IN_LIST __RECORDED_HASHS)
			file(REMOVE_RECURSE ${__HASH_FILE})
		endif()
	endforeach()
endfunction()