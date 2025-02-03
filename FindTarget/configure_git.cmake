get_property(_is_defined GLOBAL PROPERTY _find_target_configure_git_defined DEFINED)
if(_is_defined)
	return()
endif()
define_property(GLOBAL PROPERTY _find_target_configure_git_defined)

include(${_FIND_TARGET_PREFIX_DIR}/utility_func.cmake)

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
	
	_find_target_convert_to_blankable(ARG_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
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
	
	_find_target_move_to_parent_scope(${ARG_CLONED_DIR_VAR})
	
endfunction() # end use_git
