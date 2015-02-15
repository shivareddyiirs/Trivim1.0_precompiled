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
# Name        :   Dynamic Components Extension
# Description :   A script that loads the Dynamic Components as an
#                 exptension to SketchUp
# Menu Item   :   N/A
# Context Menu:   N/A
# Usage       :   N/A
# Date        :   10/16/2008
# Type        :   N/A
#-----------------------------------------------------------------------------
require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$dc_strings = LanguageHandler.new("dynamiccomponents.strings")
$dc_extension = SketchupExtension.new $dc_strings.GetString("Dynamic Components"), 
  "DynamicComponents/ruby/dcloader.rb"
$dc_extension.version = '1.0'
$dc_extension.description = $dc_strings.GetString("Provides ability to " +
  "interact with specially-authored components. Dynamic Components can have " +
  "behaviors such as smart scaling, animation, and configuration. SketchUp " +
  "Pro users additionally are given the ability to create their own Dynamic " +
  "Components.")

Sketchup.register_extension $dc_extension, true
