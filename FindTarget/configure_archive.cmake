get_property(_is_defined GLOBAL PROPERTY _find_target_configure_archive_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_configure_archive_defined)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)

function(_find_target_configure_archive PREFIX)
	set(__ARGS ${ARGN})
	set(__FUNC_ARGS "")
	while(__ARGS)
		list(POP_FRONT __ARGS __TMP)
		if(__TMP STREQUAL "URL")
			list(PREPEND __ARGS ${__TMP})
			break()
		endif()
		list(APPEND __FUNC_ARGS ${__TMP})
	endwhile()
	
	
	if(__ARGS)
		cmake_parse_arguments(__ARG
			"QUIET"
			"EXTRACTED_DIR_VAR"
			""
			${__FUNC_ARGS}
		)
	else()
		message(FATAL_ERROR "You need provided at least 1 URL.")
	endif()
	
	set(__URL_ARGS "")
	foreach(__ARG ${__ARGS} URL)
	block(PROPAGATE __URL_ARGS)
		if(NOT __URL_ARGS)
		elseif(__ARG STREQUAL "URL")
			cmake_parse_arguments(__URL_ARG
				""
				"URL;TYPE;EXPIRED_TIMEOUT"
				"HASH"
				${__URL_ARGS}
			)
			
			
			string(SHA256 __URL_HASH ${__URL_ARG_URL})
			set(__PATH "${_FIND_TARGET_TMP_DIR}/archive/${__URL_HASH}")
			set(__FILE "${__PATH}/archive.${ARG_TYPE}")
			set(__EXTRACTED_DIR "${__PATH}/extracted")
			
			if(DEFINED __URL_ARG_EXPIRED_TIMEOUT)
				math(EXPR __URL_ARG_EXPIRED_TIMEOUT "${__URL_ARG_EXPIRED_TIMEOUT}")
			endif()
			
			if(NOT __ARG_QUIET)
				message(STATUS "Downloading ${__URL_ARG_URL} ...")
			endif()
			
			if(__URL_ARG_HASH)
				list(POP_BACK __URL_ARG_HASH __HASH_TYPE)
			endif()
			
			# check if downloaded file is valid
			if(EXISTS "${__FILE}")
				if(__URL_ARG_HASH)
					file(${__HASH_TYPE} "${__FILE}" __FILE_HASH)
					if(NOT __FILE_HASH STREQUAL __URL_ARG_HASH)
						file(REMOVE_RECURSE "${__PATH}")
					endif()
				elseif(__URL_ARG_EXPIRED_TIMEOUT)
					if(EXISTS "${__PATH}/time")
						file(READ "${__PATH}/time" __OLD_TIME)
						string(TIMESTAMP __CURRENT_TIME "%s")
						math(EXPR __DTIME "${__CURRENT_TIME} - ${__OLD_TIME}")
						if(__DTIME STRGREATER __URL_ARG_EXPIRED_TIMEOUT)
							file(REMOVE_RECURSE "${__PATH}")
						endif()
					else()
						file(REMOVE_RECURSE "${__PATH}")
					endif()
				else()
					file(REMOVE_RECURSE "${__PATH}")
				endif()
			endif()
			
			if(NOT EXISTS "${__FILE}")
				file(DOWNLOAD "${__URL_ARG_URL}" "${__FILE}"
					STATUS __OUTPUT_MESSAGE
					
					${__URL_ARG_UNPARSED_ARGUMENTS}
				)
				string(TIMESTAMP __CURRENT_TIME "%s")
				file(WRITE "${__PATH}/time" "${__CURRENT_TIME}")
				list(POP_FRONT __OUTPUT_MESSAGE __RETURN_VALUE)
				if(NOT __RETURN_VALUE EQUAL 0)
					if(NOT __ARG_QUIET)
						message(STATUS "Couldn't download ${url}.")
						message(STATUS "Process return ${__RETURN_VALUE} with error: ${__OUTPUT_MESSAGE}")
					endif()
					file(REMOVE_RECURSE "${__PATH}")
					set(__URL_ARGS "")
					continue()
				endif()
				if(__URL_ARG_HASH)
					file(${__HASH_TYPE} "${__FILE}" __FILE_HASH)
					if(NOT __FILE_HASH STREQUAL __URL_ARG_HASH)
						if(NOT __ARG_QUIET)
							message(STATUS "Downloaded file's hash not match.")
						endif()
						file(REMOVE_RECURSE "${__PATH}")
						set(__URL_ARGS "")
						continue()
					endif()
				endif()
			endif()
			
			if(NOT __ARG_QUIET)
				message(STATUS "Extracting...")
			endif()
			file(ARCHIVE_EXTRACT INPUT "${__FILE}" DESTINATION "${__EXTRACTED_DIR}")
			
			if(__ARG_EXTRACTED_DIR_VAR)
				set(${__ARG_EXTRACTED_DIR_VAR} ${__EXTRACTED_DIR} PARENT_SCOPE)
			endif()
			
			break()
		endif()
		list(APPEND __URL_ARGS ${__ARG})
	endblock()
	endforeach()
	
	if(__ARG_EXTRACTED_DIR_VAR AND ${__ARG_EXTRACTED_DIR_VAR})
		_find_target_move_to_parent_scope(${__ARG_EXTRACTED_DIR_VAR})
	endif()
	
endfunction() # end use_archive