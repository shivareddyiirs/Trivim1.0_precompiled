#!/usr/bin/ruby -w
#
# Copyright 2012, Trimble Navigation Limited
#
# Initializer for Shadow Strings Fix Extension.

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

# Put translation object where the extension can find it.
$ssf_strings = LanguageHandler.new("shadowstringsfix.strings")

# Load the extension.
ssf_extension = SketchupExtension.new $ssf_strings.GetString(
  "Shadow Strings Fix Toolbar"), "ShadowStringsFix/shadowstringsfix_loader.rb"

ssf_extension.version =  '1.0.0'
ssf_extension.description = $ssf_strings.GetString("Provides a toolbar " +
  "button for toggling the experimental shadow strings bug fix on and off.  " +
  "While this may help eliminate shadow strings, it is possible that other " +
  "visual artifacts will appear.")

# Register the extension with Sketchup.
Sketchup.register_extension ssf_extension, true
