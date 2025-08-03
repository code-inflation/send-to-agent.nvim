-- Global objects
globals = {
  "vim",
}

-- Redefine builtins
read_globals = {
  "vim",
}

-- Don't report unused self arguments of methods
self = false

-- Neovim specific
exclude_files = {
  "lua/send-to-agent/health.lua",
}

ignore = {
  "212/_.*",  -- unused argument, for vars with "_" prefix
  "214",      -- used variable with unused hint ("_" prefix)
  "121",      -- setting read-only global variable 'vim'
  "122",      -- setting read-only field of global variable 'vim'
}