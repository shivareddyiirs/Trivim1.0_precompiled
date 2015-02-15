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

require 'sketchup.rb'

#-----------------------------------------------------------------------------

# This example shows how you can add new menu items to context
# menus from Ruby.  It will add an item to the context menu to create
# a point at the center of an arc or circle when you right click on it.

# First we will define a couple of functions to determine if an arc is
# selcted and to do the actual work.

# This function checks to see if the selection contains a single arc.  If
# so it returns the arc, otherwise it returns nil
def selected_arc
    ss = Sketchup.active_model.selection
    return nil if not ss.is_curve?
    edge = ss.first
    return nil if not edge.kind_of? Sketchup::Edge
    curve = edge.curve
    return nil if not curve.kind_of? Sketchup::ArcCurve
    curve
end

# Create a construction point at the center of a selected arc
def create_point_at_selected_arc_center
    point = nil
    arc = selected_arc
    if( arc )
        point = Sketchup.active_model.active_entities.add_cpoint arc.center
    end
    point
end

# Now add a new context menu handler.  You supply UI.add_context_menu_handler
# with a block that takes a menu as its only argument.  The handler can add
# new items to the menu as needed.
# Make sure that we add the handler only once.
if( not file_loaded?("arccontextmenu.rb") )
    UI.add_context_menu_handler do |menu|
        if( selected_arc )
            menu.add_separator
            menu.add_item($exStrings.GetString("Point at Center")) { create_point_at_selected_arc_center }
        end
    end
end
    
file_loaded("arccontextmenu.rb")
