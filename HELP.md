find_target(<prefix>
	QUIET
	REQUIRED
	CONFIG_ONLY
	--
	<
		<mode>
		<mode_options>
		<mode_arguments>
		--
	>...
)

<prefix> is use to set some output variable which have <prefix> as its prefix
<mode> is one of the following modes:
- USE_FIND_PACKAGE
- USE_PKGCONFIG
- USE_SUBDIRECTORY
- CONFIGURE_GIT
- CONFIGURE_ARCHIVE

USE_FIND_PACKAGE options:
- PACKAGE <package>: the name of package will be used to find using find_package()
- COMPONENTS <component>...:
	components will be used to parsed to find_package()
- OPTIONAL_COMPONENTS <component>...:
	optional components will be used to parsed to find_package()
- TARGETS <target>...: required targets to be found
- OPTIONAL_TARGETS <target>...: optional targets to be found

USE_PKGCONFIG options:
- MODULE_SPEC <moduleSpec>...:
	the name of module with spec will be parsed to pkg_check_modules()

USE_SUBDIRECTORY options:
- PATH <path>: <path> will be parsed to add_subdirectory()
- VPATH <variable>: <variable>'s content will be parsed to add_subdirectory()
- TARGETS <target>...: required targets to be found
- OPTIONAL_TARGETS <target>...: optional targets to be found
- EXCLUDE_FROM_ALL: if provided, exclude from all target

CONFIGURE_GIT options:
- REPOSITORY <url>...:
	<url> to the git repository
- TAG <tag>...:
	cloned repository will be checked out to <tag>
	<tag> maybe tag, branch or commit hash
* Note:
	+ A pair is retrieved in REPOSITORY and TAG in list order
	will be cloned
- GIT_EXECUTABLE <path>:
	use git executable from <path>
- CLONED_DIR_VAR: 
	a variable that can be use with USE_* if supported

USE_ARCHIVE options:
- URL < <url> <hash> >...: <url> to the archive. 
- FILE < <path> <hash> >...: <path> to the archive. <path> must be explicit full path
- PATTERNS <pattern>...
* Note:
	+ URL have higher priority than FILE.
	+ A url or a file path will be ignore if the hash doesn't match.
	+ parse "" to <hash> argument to disable checking hash
- TARGETS <target>...: required targets to be found
- OPTIONAL_TARGETS <target>...: optional targets to be found
- EXCLUDE_FROM_ALL: exclude from all target