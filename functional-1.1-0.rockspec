package = "functional"
version = "1.1-0"
source = {
  url = "git://github.com/wqferr/functional",
  tag = "v1.1.0"
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
  type = "builtin",
  modules = {
    functional = "init.lua",
    -- TODO find out how to add the .d.tl
  },
  copy_directories = {"doc"}
}
