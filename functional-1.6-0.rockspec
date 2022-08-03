package = "functional"
version = "1.6-0"
source = {
  url = "git://github.com/wqferr/functional",
  tag = "v1.6.0"
}

description = {
  summary = "Functional programming utilities implemented in pure lua.",
  detailed = [[
    This module seeks to provide some utility functions
    and structures which are too verbose in vanilla lua,
    in particular with regards to iteration and inline
    function definition.
  ]],
  homepage = "https://wqferr.github.io/functional/",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, < 5.5"
}

build = {
  type = "make",
  copy_directories = {"docs"},
  build_variables = {
    -- This is just here so luarocks doesn't complain I didn't pass it.
    -- It's not used at all, the Makefile just copies the files over.
    CFLAGS="$(CFLAGS)",
  },
  install_variables = {
    SOURCES="functional.lua functional.d.tl",
    INST_PREFIX="$(PREFIX)",
    INST_BINDIR="$(BINDIR)",
    INST_LIBDIR="$(LIBDIR)",
    INST_LUADIR="$(LUADIR)",
    INST_CONFDIR="$(CONFDIR)",
  },
}
