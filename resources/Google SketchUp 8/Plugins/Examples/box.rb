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

# This example shows how you can create a simple shape in a script.
# When you run this function, it will display a dialog box which prompts
# for the dimensions of a box, and then creates the box.

def create_box
    # First prompt for the dimensions.  This is done using the inputbox
    # method.  In this case, we will actually use a wrapper for UI.inputbox
    # that is defined in sketchup.rb which does some extra error checking
    
    # The first step is to create some arrays which contain the prompts
    # and default values.
    prompts = [$exStrings.GetString("Width"), $exStrings.GetString("Height"), $exStrings.GetString("Depth")]
    values = [6.feet, 5.feet, 4.feet]
    
    # Note that for the default values, we specify the values like "6.feet"
    # This says that the value is  Langth, and tells what the units of
    # the Length are.  When you display a Length value in an input box, it
    # will be formatted using your current units settings and it will parse
    # the values that you enter as a Length.
    
    # Now display the inputbox
    results = inputbox prompts, values, $exStrings.GetString("Box Dimensions")
    
    # The values that the user entered are returned in the results value.
    # If the user hit the "Cancel" button, then the function will return
    # nil.  Otherwise it is an array of values.  SKetchUp tries to match
    # the type of the returned values with the types of the default value
    # supplied, so in this case, since the default values were Lengths we
    # will get back an Array of Lengths
    return if not results # This means that the user canceld the operation
    
    width, height, depth = results
    
    # Now we can actually create the new geometry in the Model.  There are
    # a number of ways that we could actually create the geometry.  We will
    # show a couple of ways.
    
    # The first thing that we will do is bracket all of the entity creation
    # so that this looks like a single operation for undo.  If we didn't do this
    # you would get a whole bunch of separate undo items for each step
    # of the entity creation.
    model = Sketchup.active_model
    model.start_operation $exStrings.GetString("Create Box")
    
    # We will add the new entities to the "active_entities" collection.  If
    # you are not doing a component edit, this will be the main model.
    # if you are doing a component edit, it will be the open component.
    # You could also use model.entities which is the top level collection
    # regardless of whether or not you are doing a component edit.
    entities = model.active_entities

    # If you wanted the box to be created as simple top level entities
    # rather than a Group, you could comment out the following two lines.
    group = entities.add_group
    entities = group.entities
    
    # First we will create a rectangle for the base.  There are a few
    # variations on the add_face method.  This uses the version that
    # takes points and automatically creates the edges needed.
    pts = []
    pts[0] = [0, 0, 0]
    pts[1] = [width, 0, 0]
    pts[2] = [width, depth, 0]
    pts[3] = [0, depth, 0]
    base = entities.add_face pts
    
    # You could use a similar technique to crete the other faces of
    # the box.  For this example, we will use the pushpull method instead.
    # When you use pushpull, the direction is determined by the direction
    # of the fromnt of the face.  In order to control the direction and
    # get the pushpull to go in the direction we want, we first check the
    # direction of the face normal.  If it is not in the direction that
    # we want, we will reverse the sign of the distance.
    height = -height if( base.normal.dot(Z_AXIS) < 0 )
    
    # Now we can do the pushpull
    base.pushpull height
    
    # Now we are done and we can end the operation
    model.commit_operation
end

# This shows how you can add new items to the main menu from a Ruby script.
# This will add an item called "Box" to the Create menu.

# First check to see if we have already loaded this file so that we only 
# add the item to the menu once
if( not file_loaded?("box.rb") )

    # This will add a separator to the menu, but only once
    #Note: We don't translate the Menu names - the Ruby API assumes you are 
    #using English names for Menus.
    add_separator_to_menu("Draw")
    
    # To add an item to a menu, you identify the menu, and then
    # provide a title to display and a block to execute.  In this case,
    # the block just calls the create_box function
    UI.menu("Draw").add_item($exStrings.GetString("Box")) { create_box }

end

#-----------------------------------------------------------------------------
file_loaded("box.rb")
