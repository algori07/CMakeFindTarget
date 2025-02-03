cmake_minimum_required(VERSION 3.30)
project(test LANGUAGES CXX)
add_executable(test main.cpp)

include(FindTarget.cmake)
macro(ftfunc)
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
		CONFIGURE_ARCHIVE
		EXTRACTED_DIR_VAR archive_gh_fmtlib_fmt
		URL https://github.com/fmtlib/fmt/archive/refs/heads/master.zip
		EXPIRED_TIMEOUT "60 * 1"
		--
		USE_SUBDIRECTORY
		PATH "@archive_gh_fmtlib_fmt@/fmt-master"
		USE_VARIABLE
		TARGETS fmt::fmt
		EXCLUDE_FROM_ALL
		--
	)
endmacro()
ftfunc()

message("Found target: ${ftFMT_TARGETS}")

target_link_libraries(test
	PRIVATE
		${ftFMT_TARGETS}
		${ftFMT_OPTIONAL_TARGETS}
)