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
# Name        :   Sandbox Extension Manager
# Description :   A script that loads the Sandbox Tools as an exptension to 
#                SketchUp
# Menu Item   :   N/A
# Context Menu:   N/A
# Usage       :   N/A
# Date        :   11/18/2004
# Type        :   N/A
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$tStrings = LanguageHandler.new("Sandbox.strings")

#Register the Sandbox Tools with SU's extension manager
meshToolsExtension = SketchupExtension.new $tStrings.GetString("Sandbox Tools"), "Sandbox/SandboxMenus.rb"
 
meshToolsExtension.description=$tStrings.GetString("Adds items to the Draw and Tools menus for creating and editing organic shapes such as terrain.")

meshToolsExtension.version="2.0"
                      
#Default on in pro and off in free                        
Sketchup.register_extension meshToolsExtension, Sketchup.is_pro?


