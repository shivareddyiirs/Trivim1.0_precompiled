# Copyright 2012, Trimble Navigation Limited

# This extension enables placing a model in Google Earth relative to the ocean floor,
# instead of relative to ground (sea level).

# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$oceanStrings = LanguageHandler.new("ocean.strings")

oceanExtension = SketchupExtension.new $oceanStrings.GetString("Ocean Modeling"), "ocean/ocean.rb"

oceanExtension .description=$oceanStrings.GetString("Adds the ability to model on the ocean floor after using Add Location to import ocean terrain.")

Sketchup.register_extension oceanExtension, false
