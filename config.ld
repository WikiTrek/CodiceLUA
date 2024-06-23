-- config.ld

-- Project information
project = "Wikitrek Lua modules"
description = "Documentation for Lua modules in WikiTrek"
version = "1.0"

-- Output directory
dir = "docs"

-- Source files, leading ! excludes files and / or folders
file = {
  "!**/vendor/**",
  "!**/tests/**",
}

-- Additional configuration options
style = "plain"
format = "markdown"
