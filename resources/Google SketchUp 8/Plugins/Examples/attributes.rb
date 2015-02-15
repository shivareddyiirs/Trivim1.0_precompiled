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
# This example shows how you can attach arbitrary attribute data to entities
# and then do queries based on those attributes.

# In this example, there is a method to attach a cost estimate attribute to
# selected faces.  You can then do a query on the model and get the total
# cost estimate.

# This is a global variable that keeps track of the last value entered
$cost_per_sq_ft = 1.00 if not $cost_per_sq_ft

# This method prompts for a cost estimate and attaches it to all selected faces
def attach_cost_estimate

    # See if there is anything selected
    ss = Sketchup.active_model.selection
    return if ss.empty?
    
    # First prompt the user for the cost per sq foot
    prompts = [$exStrings.GetString("Cost per sq. foot")]
    values = [$cost_per_sq_ft]
    results = inputbox prompts, values, $exStrings.GetString("Cost Estimate")
    return if not results
    
    # Now attach this as an attribute to all selected Faces
    $cost_per_sq_ft = results[0]
    ss.each do |e|
        if( e.kind_of? Sketchup::Face )
            # An attributes are stored with named values in a named dictionary
            # In this example, the dictionary name is 'skpex'.
            # The attribute value is named 'cpsf'.
            # Note that you can use any name that you want for the dictionary
            # and the attributes.  The attributes names are currently stored 
            # on every entity that the attribute is attached to however, so
            # it is generally a good idea to keep the name short to avoid
            # using a lot of extra memory storing the attributes.
            e.set_attribute 'skpex', 'cpsf', $cost_per_sq_ft
        end
    end

end

# This method assigns a cost estimate to a Material.  You can then paint
# faces with that material to get them to use that estimate
def assign_estimate_to_material
    # First get a list of all of the materials in the model
    model = Sketchup.active_model
    materials = model.materials
    names = materials.collect {|m| m.name}
    translatednames = materials.collect {|m| m.display_name}
    
    # Display a dialog to pick a material and cost
    prompts = [$exStrings.GetString("Material"), $exStrings.GetString("Cost per sq. foot")]
    values = [translatednames[0], $cost_per_sq_ft]
    enums = [translatednames.join("|")]
    results = inputbox prompts, values, enums, $exStrings.GetString("Cost By Material")
    return if not results
    $cost_per_sq_ft = results[1]
    
    # Get the selected Material
    index = translatednames.index(results[0])
    material = index ? materials[names[index]] : nil
    if( not material )
        UI.messagebox $exStrings.GetString("Could not find Material named") + " #{results[0]}"
        return
    end

    # And attach the cost estimate attribute
    material.set_attribute 'skpex', 'cpsf', $cost_per_sq_ft
end

# This method iterates through all faces in the model and computes the
# total cost estimate based on the the attributes attached to the faces.
# For purposes of this example, it does not look at faces that are inside
# Groups or Components.
def compute_cost_estimate
    total_cost = 0.0
    
    entities = Sketchup.active_model.entities
    entities.each do |e|
        next if not e.kind_of? Sketchup::Face
        
        # See if it has a cost estimate attribute  get_attribute will
        # return nil if there is no attribute matching the given names
        cost_per_sq_ft = e.get_attribute 'skpex', 'cpsf'
        
        # If there is a cost estimate attached directly to the Face
        # then that is used.  Otherwise, look to see if there is a cost
        # estimate attached to a Material for the Face.  This is a little
        # bit of a problem because a Face can have a front and back Material.
        # For this example, we use the cost estimates from both
        if not cost_per_sq_ft
            material = e.material
            if( material )
                cost_per_sq_ft = material.get_attribute 'skpex', 'cpsf'
            end
            material = e.back_material
            if( material )
                cpsf_back = material.get_attribute 'skpex', 'cpsf'
                if( cpsf_back )
                    if( cost_per_sq_ft )
                        cost_per_sq_ft += cpsf_back
                    else
                        cost_per_sq_ft = cpsf_back
                    end
                end
            end
        end
        
        # If there is not Material with a cost estimate on it, then
        # skip this Face.
        next if not cost_per_sq_ft
        
        # Compute the estimate for this face based on the area
        # The area is returned in square inches - convert to square feet
        area = e.area / 144.0
        cost = area * cost_per_sq_ft
        
        total_cost += cost
    end
    
    # Now display the results
    dollars = format("%.2f", total_cost)
    msg = $exStrings.GetString("Total Cost Estimate") + " = \$#{dollars}"
    UI.messagebox(msg, MB_OK, $exStrings.GetString("Cost Estimate"))
end

# Add some menu items to access this
if( not file_loaded?("attributes.rb") )
    #Note: We don't translate the Menu names - the Ruby API assumes you are 
    #using English names for Menus.
    plugins_menu = UI.menu("Plugins")
    cost_menu = plugins_menu.add_submenu($exStrings.GetString("Cost"))
    cost_menu.add_item($exStrings.GetString("Assign Estimate to Material")) { assign_estimate_to_material }
    cost_menu.add_item($exStrings.GetString("Assign Estimate to Faces")) { attach_cost_estimate }
    cost_menu.add_item($exStrings.GetString("Compute Estimate")) { compute_cost_estimate }
end

#-----------------------------------------------------------------------------
file_loaded("attributes.rb")
