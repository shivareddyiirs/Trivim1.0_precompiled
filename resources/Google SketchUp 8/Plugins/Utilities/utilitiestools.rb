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

# This funtion will create a face from the edges in the selection set.
# There must be at least three Edges selected.
# It will show an error message if a face couldn't be created from the edges.
def create_face_from_selection
    ss = Sketchup.active_model.selection
    
    # Get an Array of all of the selected Edges
    edges = ss.find_all { |e| e.kind_of?(Sketchup::Edge) }
    
    # We need at least 3 Edges
    if( edges.length < 3 )
        UI.messagebox($uStrings.GetString("You must select at least three Edges"))
        return nil
    end
    
    # Try to create a Face from the Edges in the active component
    face = nil
    begin
        face = Sketchup.active_model.active_entities.add_face edges
    rescue
    end
    
    # If a Face wasn't created, then there should be an error message
    # telling what the problem was
    if( not face )
        if( $! )
            msg = $!.message
        else
            msg = $uStrings.GetString("Create Face from Edges failed")
        end
        UI.messagebox msg
    end
    
    # Return the Face that was created
    face
end

#-------------------------------------------------------------------------
# This example show how you can write a simple tool in Ruby.  To implement
# a tool, you have to implement the methods that you want to handle.
# In this example the following methods are implementd:
# onMouseMove is called when a mouse move event is received.
# draw is handled to draw the tool

# This tool show coordinates of points and screen positions.
# It also shows lengths of selected Edges or areas of selected Faces.

# To see this tool in action, type the following in the Ruby console window:
# Sketchup.active_model.select_tool TrackMouseTool.new

class TrackMouseTool

# The activate method is called when a tool is first activated.  It is not
# required, but it is a good place to initialize stuff.
def activate
    @ip = Sketchup::InputPoint.new
    @iptemp = Sketchup::InputPoint.new
    @displayed = false
end

# onMouseMove is called whenever SketchUp gets a mouse move event.  It is called
# a lot, so you should try to make it as efficient as possible.
def onMouseMove(flags, x, y, view)
    # show the screen position in the VCB
    Sketchup::set_status_text("#{x}, #{y}", SB_VCB_VALUE)
    
    # get a position in the model and show it in a tooltip
    @iptemp.pick view, x, y
    if( @iptemp.valid? )
        changed = @iptemp != @ip
        @ip.copy! @iptemp
        pos = @ip.position;
        
        # get the text for the position
        msg = @ip.tooltip
        if( msg.length > 0 )
            msg << " "
        end
        #msg << pos.to_s
        msg << "( #{Sketchup.format_length(pos.x)},#{Sketchup.format_length(pos.y)},#{Sketchup.format_length(pos.z)} )"

        
        # See if it is on any special geometry
        if( @ip.vertex == nil )
            if( @ip.edge )
                if( @ip.depth > 0 )
                    length = @ip.edge.length(@ip.transformation)
                else
                    length = @ip.edge.length
                end
                msg <<  "\n       " + $uStrings.GetString("length") + " = #{Sketchup.format_length(length)}"
            elsif( @ip.face )
                if( @ip.depth > 0 )
                    area = @ip.face.area(@ip.transformation)
                else
                    area = @ip.face.area
                end
                msg << "\n       " + $uStrings.GetString("area") + " = #{Sketchup.format_area(area)}"
            end
        end

        msg2 = msg.gsub(/\n/,' ')
        Sketchup::set_status_text msg2
        
        # set the tooltip to show this message
        view.tooltip = msg
        
        # see if we need to update the display for this point
        if( changed and (@ip.display? or @displayed) )
            # This tells the view that we want it to update itself
            view.invalidate
        end
    end
    
end

# onLButtonDown is called when the user presses the left mouse button
def onLButtonDown(flags, x, y, view)
    Sketchup::set_status_text $uStrings.GetString("Left button down at") + " (#{x}, #{y})"
end

# onLButtonUp is called when the user releases the left mouse button
def onLButtonUp(flags, x, y, view)
    Sketchup::set_status_text $uStrings.GetString("Left button up at") + " (#{x}, #{y})"
end

# draw is optional.  It is called on the active tool whenever SketchUp
# needs to update the screen.
# in this case, we display an input point if needed
def draw(view)
    if( @ip.valid? && @ip.display? )
        @ip.draw view
        @displayed = true
    else
        @displayed = false
    end
end

def getInstructorContentDirectory
    "Query"
end

end

#-----------------------------------------------------------------------------
# Make selected components unique.
# This looks at all selected components.
def make_selected_components_unique

    # First get all selected components
    ss = Sketchup.active_model.selection
    components = ss.find_all {|e| e.kind_of?(Sketchup::ComponentInstance) }
    
    # Create a Hash.  The keys are the guids of all of the component definitions
    # for selected components.  The values are arrays of all of the component instances
    # that have that definition
    definitions = {}
    for component in components
        key = component.definition.guid
        a = definitions[key]
        if( a )
            a.push component
        else
            definitions[key] = [component]
        end
    end
    
    # Now make each collection of component instances have a new unique definition
    definitions.each_value do |a|
        # a is an array of component instances that all share the same definition
        # We will make the first one have a new unique definition, and all of the
        # other ones use that new definition
        definition = nil
        for component in a
            if( definition )
                # We already have a new definition.  Make this component use it
                component.definition = definition
            else
                # Make the component have a unique definition and save it
                component.make_unique
                definition = component.definition
            end
        end
    end

    true
end

#----------------------------------------------------------------------------
# Add things to the Utilities menu
if( not $utilities_menu_loaded )
    add_separator_to_menu("Tools")
    utilities_menu = UI.menu("Tools").add_submenu($uStrings.GetString("Utilities"))

    utilities_menu.add_item($uStrings.GetString("Create Face")) { create_face_from_selection }
    utilities_menu.add_item($uStrings.GetString("Query Tool")) { Sketchup.active_model.select_tool TrackMouseTool.new }
    #utilities_menu.add_item($uStrings.GetString("Fix Non-planar Faces")) { Sketchup.send_action "fixNonPlanarFaces:" }

    $utilities_menu_loaded = true
end
