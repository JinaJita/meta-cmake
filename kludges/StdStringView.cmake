check_cxx_source_compiles("
#include <string_view>
int main() {
    return 0;
}"
META_HAS_STRING_VIEW)

if (META_HAS_STRING_VIEW)
  target_compile_definitions(compiler-kludges INTERFACE
    -DMETA_HAS_STRING_VIEW)

  check_cxx_source_compiles("
  #include <string_view>
  int main() {
      const std::string_view sv = \"hello world\";
      return 0;
  }"
  META_HAS_STD_STRING_VIEW)

  if (META_HAS_STD_STRING_VIEW)
    target_compile_definitions(compiler-kludges INTERFACE
      -DMETA_HAS_STD_STRING_VIEW)
  else()
    check_cxx_source_compiles("
    #include <string_view>
    int main() {
        const std::experimental::string_view sv = \"hello world\";
        return 0;
    }"
    META_HAS_EXPERIMENTAL_STRING_VIEW)
  endif()
else()
  check_cxx_source_compiles("
  #include <experimental/string_view>
  int main() {
      const std::experimental::string_view sv = \"hello world\";
      return 0;
  }"
  META_HAS_EXPERIMENTAL_STRING_VIEW)
endif()

if (META_HAS_EXPERIMENTAL_STRING_VIEW)
  target_compile_definitions(compiler-kludges INTERFACE
    -DMETA_HAS_EXPERIMENTAL_STRING_VIEW)
endif()
