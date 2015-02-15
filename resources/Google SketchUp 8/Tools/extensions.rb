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

#=============================================================================
# Base class for SketchUp Ruby extensions.

class SketchupExtension

    attr_accessor :name, :description, :version, :creator, :copyright

    def initialize(name, filePath)
      @name = name
      @description = description
      @path = filePath

      @version = "1.0"
      @creator = "SketchUp"
      @copyright = "2012, Trimble Navigation Limited"
      @loaded = false
      @registered = false

      # When an extension is registered with Sketchup.register_extension,
      # SketchUp will then update this setting if the user makes changes
      # in the Preferences > Extensions panel.
      @load_on_start = false
    end

    # Loads the extension, which is the equivalent of checking its checkbox
    # in the Preferences > Extension panel.
    def check
      # If we're already registered, reregister to initiate the load.
      if @registered
        Sketchup.register_extension self, true
      else
        # If we're not registered, just require the implementation file.
        success = Sketchup::require @path
        if success
          @loaded = true
          return true
        else
          return false
        end
      end
    end

    # Unloads the extension, which is the equivalent of unchecking its checkbox
    # in the Preferences > Extension panel.
    def uncheck
      # If we're already registered, reregister to initiate the unload.
      if @registered
        Sketchup.register_extension self, false
      end
    end

    # Get whether this extension has been loaded.
    def loaded?
      return @loaded
    end

    # Get whether this extension is set to load on start of SketchUp.
    def load_on_start?
      return @load_on_start
    end

    # Get whether this extension has been registered with SketchUp via the
    # Sketchup.register_extension method.
    def registered?
      return @registered
    end

    # This method is called by SketchUp when the extension is registered via the
    # Sketchup.register_extension method. NOTE: This is an internal method that
    # should not be called from Ruby.
    def register_from_sketchup()
      @registered = true
    end

    # This is called by SketchUp when the extension is unloaded via the UI.
    # NOTE: This is an internal method that should not be called from Ruby.
    def unload()
      @load_on_start = false
    end

    # This is called by SketchUp when the extension is loaded via the UI.
    # NOTE: This is an internal method that should not be called from Ruby.
    def load()
      success = Sketchup::require @path
      if success
        @load_on_start = true
        @loaded = true
        return true
      else
        return false
      end
    end
end
