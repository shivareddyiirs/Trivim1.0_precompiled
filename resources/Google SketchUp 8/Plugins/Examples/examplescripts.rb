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

#-----------------------------------------------------------------------------
# box.rb is an example of how to create simple geometry using Ruby.
# It also shows how to create a dialog box to prompt for user input
# and how to add an item to a menu.

require 'examples/box.rb'

#-----------------------------------------------------------------------------
# selection.rb has a number of examples of how to traverse the model and
# select things in Ruby.

require 'examples/selection.rb'

#-----------------------------------------------------------------------------
# contextmenu.rb shows how you can add new choices to context menus.  It
# adds an item to the context menu for arcs and circles to create a
# point at the center of the arc.

require 'examples/contextmenu.rb'

#-----------------------------------------------------------------------------
# linetool.rb shows how you can create tools that respond to mouse event
# in Ruby.  It defines a simple tool that behave similar to the pencil
# tool in SketchUp except that it creates finite length construction lines
# instead of regular SketchUp edges

require 'examples/linetool.rb'

#-----------------------------------------------------------------------------
# animation.rb has an example of how you can create animations in Ruby.
# It creates a simple animation that spins the view around.

require 'examples/animation.rb'

# attributes.rb shows how to attach arbitrary application specific attribute
# data to SketchUp Entities.

require 'examples/attributes.rb'

#=============================================================================
# This will set the layer of everything that is selected to
# a layer with the given name.  It will create a new layer if needed
def setLayer(layerName)

    model = Sketchup.active_model
    ss = model.selection
    if( ss.empty? ) 
        return nil
    end

    # If there is alread a Layer with the given name, the add method on the
    # Layers object will return the existing Layer.  Otherwise it will
    # create a new one and return it.
    layer = model.layers.add(layerName)
    
    # now iterate through everything that is selected and set its layer
    for ent in ss
        ent.layer = layer
    end
    
    # Here is another way that you could do the same thing
    #ss.each {|ent| ent.layer = layer}
    
end

#-------------------------------------------------------------------------
# compute the total area of all faces
def totalArea
    area = 0
    
    model = Sketchup.active_model
    
    # this shows a different syntax for iterating through the model
    model.entities.each { |ent| area += ent.area if( ent.is_a? Sketchup::Face ) }
    
    # here is a different way you could do it
#    for ent in model.entities
#        if( ent.is_a? Sketchup::Face )
#            area += ent.area
#        end
#    end

    area
end

#-------------------------------------------------------------------------
# Get the perimeter of the selected faces
def perimeter

    length = 0
    edges = []
    
    # First collect all of the edges that bound all of the selected faces.
    model = Sketchup.active_model
    ss = model.selection
    for ent in ss
        if( ent.is_a? Sketchup::Face )
            edges.concat ent.edges
        end
    end
    
    # remove duplicate edges
    edges.uniq!
    
    # sum the lengths of all of the edges
    edges.each {|e| length += e.length}
    
    length
end

#-----------------------------------------------------------------------------
# SketchUp sets up Ruby to look for files in its plugins directory when you
# use the load command.  You can add additional directories to its search path.
# This can be useful when you are developing new scripts because it can
# make it easier to load them during testing.
# This command adds your home directory to the search path.  Note that this
# only works if the environment variable HOME is defined.
# $: is a special system variable in Ruby that defines the search path.
if( ENV["HOME"] )
    homedir = File.expand_path("~")
    $:.push homedir
end
