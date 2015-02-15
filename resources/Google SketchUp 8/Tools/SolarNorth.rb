#!/usr/bin/ruby -w
#
# Copyright 2012, Trimble Navigation Limited
#
# Initializer for Solar North Extension.

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'


# Put translation object where the extension can find it.
$sn_strings = LanguageHandler.new("solarnorth.strings")

# Load the extension.
sn_extension = SketchupExtension.new $sn_strings.GetString(
  "Solar North Toolbar"), "SolarNorth/solarnorth_loader.rb"
sn_extension.version =  '1.0.0'
sn_extension.description = $sn_strings.GetString("Provides a toolbar for displaying and " +
  "altering solar north in the model. Useful for customized shadow " +
  "studies.")

# Register the extension with Sketchup.
Sketchup.register_extension sn_extension, true
