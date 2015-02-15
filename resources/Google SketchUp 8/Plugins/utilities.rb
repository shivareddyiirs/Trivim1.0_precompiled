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

# This adds some useful functions to the Utilities menu in SketchUp
require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$uStrings = LanguageHandler.new("Utilities.strings")

utilitiesExtension = SketchupExtension.new $uStrings.GetString("Utilities Tools"), "Utilities/utilitiesTools.rb"
                    
utilitiesExtension.description=$uStrings.GetString("Adds Tools->Utilities to the SketchUp interface.  The Utilities submenu contains two tools: Create Face and Query Tool.")
                        
Sketchup.register_extension utilitiesExtension, false
