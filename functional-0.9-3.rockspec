package = 'functional'
version = '0.9-3'
source = {
  url = 'git://github.com/wqferr/lua-func',
  tag = 'v0.9.3'
}

description = {
  summary = 'Functional programming utilities implemented in pure lua.',
  detailed = [[
    This module seeks to provide some utility functions
    and structures which are too verbose in vanilla lua,
    in particular with regards to iteration and inline
    function definition.
  ]],
  homepage = 'https://wqferr.github.io/lua-func/',
  license = 'MIT'
}

build = {
  type = 'builtin',
  modules = {
    functional = 'func.lua'
  }
}
