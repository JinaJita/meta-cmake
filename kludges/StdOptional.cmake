check_cxx_source_compiles("
#include <optional>
int main() {
    return 0;
}"
META_HAS_OPTIONAL)

if (META_HAS_OPTIONAL)
  target_compile_definitions(compiler-kludges INTERFACE
    -DMETA_HAS_OPTIONAL)

  check_cxx_source_compiles("
  #include <optional>
  int main() {
      std::optional<int> x;
      return 0;
  }"
  META_HAS_STD_OPTIONAL)

  if (META_HAS_STD_OPTIONAL)
    target_compile_definitions(compiler-kludges INTERFACE
      -DMETA_HAS_STD_OPTIONAL)
  else()
    check_cxx_source_compiles("
    #include <optional>
    int main() {
        std::experimental::optional<int> x;
        return 0;
    }"
    META_HAS_EXPERIMENTAL_OPTIONAL)
  endif()
else()
  check_cxx_source_compiles("
  #include <experimental/optional>
  int main() {
      std::experimental::optional<int> x;
      return 0;
  }"
  META_HAS_EXPERIMENTAL_OPTIONAL)
endif()

if (META_HAS_EXPERIMENTAL_OPTIONAL)
  target_compile_definitions(compiler-kludges INTERFACE
    -DMETA_HAS_EXPERIMENTAL_OPTIONAL)
endif()
