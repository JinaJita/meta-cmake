check_cxx_source_compiles("
#include <optional>
int main() {
    return 0;
}"
META_HAS_OPTIONAL_HEADER)

if (META_HAS_OPTIONAL_HEADER)
  target_compile_definitions(compiler-kludges INTERFACE
    -DMETA_HAS_OPTIONAL_HEADER)

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

  if (META_HAS_EXPERIMENTAL_OPTIONAL)
    set(META_HAS_EXPERIMENTAL_OPTIONAL_HEADER TRUE)
    target_compile_definitions(compiler-kludges INTERFACE
      -DMETA_HAS_EXPERIMENTAL_OPTIONAL_HEADER)
  endif()
endif()

if (META_HAS_EXPERIMENTAL_OPTIONAL)
  target_compile_definitions(compiler-kludges INTERFACE
    -DMETA_HAS_EXPERIMENTAL_OPTIONAL)
endif()
