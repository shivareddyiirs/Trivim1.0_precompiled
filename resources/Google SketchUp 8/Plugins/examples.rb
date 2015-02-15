# Copyright 2012, Trimble Navigation Limited

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------

# This file includes a number of examples of how to use the Ruby interface
# to access a SketchUp model and perform various kinds of operations.

# To test the examples you must first load the files.
# There are two ways that you can do this.

# The first way is to manually load it from the Ruby console.  You can show
# the Ruby console by selecting View/Ruby Console. (This is actually added
# to the View menu when the Ruby script sketchup.rb is loaded.)  In the
# Ruby console, type the following line:
# load 'examples/examples.rb'
# If there are no syntax errors in the file, it will display "true" in the
# Ruby console.  Otherwise it will show error messages and information about
# the line on which errors were found.

# The second way to load this file is to copy it into the SketchUp plugins
# directory.  Any files with the extension .rb that are in the plugins
# directory are automatically loaded when you start SketchUp.

# The following line includes some common useful scripts.  The file
# sketchup.rb is automatically put in the SketchUp plugins directory
# when SketchUp is installed, so it should always get automatically
# loaded anyway, but it is good practice to explicitly require any
# files that you have dependencies on to make sure that they are loaded.
require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$exStrings = LanguageHandler.new("Examples.strings")

examplesExtension = SketchupExtension.new $exStrings.GetString("Ruby Script Examples"), "examples/exampleScripts.rb"
                    
examplesExtension.description=$exStrings.GetString("Adds examples of tools created in Ruby to the SketchUp interface.  The example tools are Draw->Box, Plugins->Cost and Camera->Animations.")
                        
Sketchup.register_extension examplesExtension, false
