#!/usr/bin/ruby -w
#
# Copyright 2012, Trimble Navigation Limited
#
# Initializer for WebTextures Extension.

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

# Put translation object where the extension can find it.
$wt_strings = LanguageHandler.new("webtextures.strings")

# Load the extension.
wt_extension = SketchupExtension.new $wt_strings.GetString(
  "Photo Textures"), "WebTextures/webtextures_loader.rb"
wt_extension.version =  '1.0.0'
wt_extension.description = $wt_strings.GetString("Photo Textures" +
  " allows you to apply textures from online photo sources.")

# Register the extension with Sketchup.
Sketchup.register_extension wt_extension, true
