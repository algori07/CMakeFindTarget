cmake_minimum_required(VERSION 3.30)
project(test LANGUAGES CXX)
add_executable(test main.cpp)

include(FindTarget2.cmake)
find_target(ftFMT
	REQUIRED
	--
	USE_FIND_PACKAGE
	PACKAGE_NAME fmt
	TARGETS fmt::fmt
	--
	USE_PKGCONFIG
	MODULE_SPEC fmt
	--
	CONFIGURE_GIT
	REPOSITORY https://github.com/fmtlib/fmt
	CLONED_DIR_VAR gh_fmtlib_fmt
	TAG 11.1.2
	--
	USE_SUBDIRECTORY
	PATH_VAR gh_fmtlib_fmt
	TARGETS fmt::fmt
	EXCLUDE_FROM_ALL
	--
)


target_link_libraries(test
	PRIVATE
		${ftFMT_TARGETS}
		${ftFMT_OPTIONAL_TARGETS}
)