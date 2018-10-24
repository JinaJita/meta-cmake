message("-- Looking for filesystem library")
# first, check if there exists a working std::filesystem without any
# experimental libraries whatsoever
check_cxx_source_compiles("
#include <filesystem>

int main()
{
      std::string path = \"/home/meta/tmp/123456\";
      const auto p1 = std::filesystem::u8path(path);
      std::filesystem::remove_all(p1);
      const auto str = p1.u8string();
      return 0;
}
"
META_HAS_STD_FILESYSTEM)

if (META_HAS_STD_FILESYSTEM)
  message("-- Found built-in support for std::filesystem")
  set(STD_FILESYSTEM_FOUND TRUE)
else()
  message("-- Looking for external std::{,experimental}::filesystem")

  # {,experimental::}filesystem is packaged as a separate static library in
  # GCC >= 5.3 as -lstdc++fs
  if (CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND NOT ENABLE_LIBCXX AND NOT WIN32))
    message("-- Locating libstdc++ filesystem library")
    find_library(STDCXX_FILESYSTEM
      NAMES stdc++fs
      HINTS ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES})

    if (STDCXX_FILESYSTEM)
      message("-- Found libstdc++ filesystem library: ${STDCXX_FILESYSTEM}")
      set(STD_FILESYSTEM_LIBRARIES ${STDCXX_FILESYSTEM})
      set(STD_FILESYSTEM_FOUND TRUE)
    else()
      message("-- Locating libstdc++ filesystem library - not found")
    endif()
  endif()

  if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND ENABLE_LIBCXX)
    # std::filesystem is packaged in a separate static library in
    # libc++ >= 7.0
    message("-- Locating libc++fs filesystem library")
    find_library(LIBCXX_FILESYSTEM
      NAMES c++fs
      HINTS ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES} ${LIBCXX_LIB_PATH})

    if (LIBCXX_FILESYSTEM)
      message("-- Found libc++fs filesystem library: ${LIBCXX_FILESYSTEM}")
      set(STD_FILESYSTEM_LIBRARIES ${LIBCXX_FILESYSTEM})
      set(STD_FILESYSTEM_FOUND TRUE)
    else()
      message("-- Locating libc++fs filesystem library - not found")
      # experimental::filesystem is packaged in a separate static library
      # in libc++ >= 3.9 as -lc++experimental
      message("-- Locating libc++experimental library")
      find_library(LIBCXX_EXPERIMENTAL
        NAMES c++experimental
        HINTS ${CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES} ${LIBCXX_LIB_PATH})

      if (LIBCXX_EXPERIMENTAL)
        message("-- Found libc++experimental library: ${LIBCXX_EXPERIMENTAL}")
        set(STD_FILESYSTEM_LIBRARIES ${LIBCXX_EXPERIMENTAL})
        set(STD_FILESYSTEM_FOUND TRUE)
      else()
        message("-- Locating libc++experimental library - not found")
      endif()
    endif()
  endif()

  # experimental::filesystem is available by default for MSVC 2015 and newer
  if (MSVC_VERSION AND NOT (MSVC_VERSION LESS 1900))
    set(STD_FILESYSTEM_FOUND TRUE)
  endif()

  if (STD_FILESYSTEM_LIBRARIES)
    set(CMAKE_REQUIRED_LIBRARIES "${CMAKE_REQUIRED_LIBRARIES} ${STD_FILESYSTEM_LIBRARIES}")
  endif()
endif()

if (META_HAS_STD_FILESYSTEM OR STD_FILESYSTEM_FOUND)
  message("-- Determining filesystem library capabilities")
  check_cxx_source_compiles("
  #include <filesystem>
  namespace fs = std::filesystem;
  int main()
  {
      std::string path = \"/home/meta/tmp/123456\";
      const auto p1 = fs::u8path(path);
      fs::remove_all(p1);
      const auto str = p1.u8string();
      return 0;
  }"
  META_FILESYSTEM_IS_STD)

  if (META_FILESYSTEM_IS_STD)
    set(META_STD_FILESYSTEM_HEADER "<filesystem>")
    set(META_STD_FILESYSTEM_NAMESPACE "std::filesystem")
    set(META_HAS_STD_FILESYSTEM TRUE)
  else()
    set(META_STD_FILESYSTEM_HEADER "<experimental/filesystem>")
    set(META_STD_FILESYSTEM_NAMESPACE "std::experimental::filesystem")
    set(META_FILESYSTEM_IS_EXPERIMENTAL TRUE)
    set(META_HAS_EXPERIMENTAL_FILESYSTEM TRUE)
  endif()

  check_cxx_source_compiles("
  #include ${META_STD_FILESYSTEM_HEADER}
  namespace fs = ${META_STD_FILESYSTEM_NAMESPACE};
  int main()
  {
      std::string path = \"/home/meta/tmp/123456\";
      const auto p1 = fs::u8path(path);
      fs::remove_all(p1);
      const auto str = p1.u8string();
      return 0;
  }"
  META_HAS_FILESYSTEM)

  if (META_HAS_FILESYSTEM)
    target_compile_definitions(compiler-kludges INTERFACE
      -DMETA_HAS_FILESYSTEM)

    if (META_FILESYSTEM_IS_STD)
      target_compile_definitions(compiler-kludges INTERFACE
        -DMETA_HAS_STD_FILESYSTEM)
    elseif (META_FILESYSTEM_IS_EXPERIMENTAL)
      target_compile_definitions(compiler-kludges INTERFACE
        -DMETA_HAS_EXPERIMENTAL_FILESYSTEM)
    endif()

    if (STD_FILESYSTEM_LIBRARIES)
      target_link_libraries(compiler-kludges INTERFACE
        ${STD_FILESYSTEM_LIBRARIES})
    endif()

    # experimental::filesystem::remove_all doesn't recurse properly as of GCC
    # 5.3.
    set(META_REMOVE_ALL_TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/meta-filesystem-test)
    file(MAKE_DIRECTORY ${META_REMOVE_ALL_TEST_DIR})
    file(MAKE_DIRECTORY ${META_REMOVE_ALL_TEST_DIR}/subdir)
    file(WRITE ${META_REMOVE_ALL_TEST_DIR}/subdir/file "Just some testing text")

    check_cxx_source_runs("
    #include ${META_STD_FILESYSTEM_HEADER}
    namespace fs = ${META_STD_FILESYSTEM_NAMESPACE};
    int main()
    {
        fs::remove_all(\"${META_REMOVE_ALL_TEST_DIR}\");
        return 0;
    }"
    META_HAS_WORKING_FILESYSTEM_REMOVE_ALL)

    if (META_HAS_WORKING_FILESYSTEM_REMOVE_ALL)
      target_compile_definitions(compiler-kludges INTERFACE
        -DMETA_HAS_WORKING_FILESYSTEM_REMOVE_ALL)
    endif()

    file(REMOVE_RECURSE ${META_REMOVE_ALL_TEST_DIR})
    unset(META_REMOVE_ALL_TEST_DIR)
  endif()
endif()

if (NOT META_HAS_FILESYSTEM)
  message("-- No suitable filesystem library found; must use fallback")
endif()
