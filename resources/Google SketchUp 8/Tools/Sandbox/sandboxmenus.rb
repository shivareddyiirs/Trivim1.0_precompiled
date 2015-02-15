# Copyright 2012, Trimble Navigation Limited

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   Sandbox Menus
# Description :   The governing menu creation script for the Sketchup Sandbox Tools
# Menu Item   :   None
# Context Menu:   None
# Usage       :   None - Loads the Sandbox tools one by one and adds their menu items
# Date        :   10/20/04
# Type        :   Loader
#-----------------------------------------------------------------------------

require 'sketchup.rb'

Sketchup::require 'Sandbox/GeometryHelpers'

$sandboxDefaults = DefaultManager.new

Sketchup::require 'Sandbox/FromContours'
Sketchup::require 'Sandbox/FromScratch'
Sketchup::require 'Sandbox/SmooveTool'
Sketchup::require 'Sandbox/StampTool'
Sketchup::require 'Sandbox/DrapeTool2'
Sketchup::require 'Sandbox/DetailTool'
Sketchup::require 'Sandbox/FlipEdgeTool'

tb = UI::Toolbar.new($tStrings.GetString("Sandbox"))

#------------Draw ---------------------

if( not $draw_terrain_submenu_loaded ) 
    add_separator_to_menu("Draw")
    $draw_terrain_submenu = UI.menu("Draw").add_submenu($tStrings.GetString("Sandbox"))
    $draw_terrain_submenu_loaded = true
end

if( not $terrain_CreateFromContours_loaded )
    cmd = UI::Command.new($tStrings.GetString("From Contours")) { Sketchup::active_model.select_tool FromContoursTool.new }
    cmd.small_icon = "Images/tbContoursSmall.png"
    cmd.large_icon = "Images/tbContoursLarge.png"
    cmd.tooltip = $tStrings.GetString("From Contours")
    cmd.status_bar_text = $tStrings.GetString("Create a Sandbox from contours")
    cmd.menu_text = $tStrings.GetString("From Contours")
    $draw_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)    
    $terrain_CreateFromContours_loaded = true
end

if( not $terrain_CreateFlat_loaded )
    cmd = UI::Command.new($tStrings.GetString("From Scratch")) { Sketchup::active_model.select_tool FromScratchTool.new }
    cmd.small_icon = "Images/tbFlatTerrainSmall.png"
    cmd.large_icon = "Images/tbFlatTerrainLarge.png"
    cmd.tooltip = $tStrings.GetString("From Scratch")
    cmd.status_bar_text = $tStrings.GetString("Create a Sandbox from scratch")
    cmd.menu_text = $tStrings.GetString("From Scratch")
    $draw_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)
    $terrain_CreateFlat_loaded = true
end

tb.add_separator

#------------Tools ---------------------

if( not $tools_terrain_submenu_loaded )
    add_separator_to_menu("Tools")
    $tools_terrain_submenu = UI.menu("Tools").add_submenu($tStrings.GetString("Sandbox"))
    $tools_terrain_submenu_loaded = true
end

if( not $terrain_Smoover_loaded )
    cmd = UI::Command.new($tStrings.GetString("Smoove")) { Sketchup::active_model.select_tool SmooveTool.new }
    cmd.small_icon = "Images/tbSmooverSmall.png"
    cmd.large_icon = "Images/tbSmooverLarge.png"
    cmd.tooltip = $tStrings.GetString("Smoove")
    cmd.status_bar_text = $tStrings.GetString("Smoove")
    cmd.menu_text = $tStrings.GetString("Smoove")
    $tools_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)
    $terrain_Smoover_loaded = true
end

if( not $terrain_Stamper_loaded )
    cmd = UI::Command.new($tStrings.GetString("Stamp")) { Sketchup::active_model.select_tool StampTool.new }
    cmd.small_icon = "Images/tbStamperSmall.png"
    cmd.large_icon = "Images/tbStamperLarge.png"
    cmd.tooltip = $tStrings.GetString("Stamp")
    cmd.status_bar_text = $tStrings.GetString("Stamp")
    cmd.menu_text = $tStrings.GetString("Stamp")
    $tools_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)
    $terrain_Stamper_loaded = true
end

if( not $terrain_Drape3_loaded )
    cmd = UI::Command.new($tStrings.GetString("Drape")) { Sketchup::active_model.select_tool DrapeTool.new }
    cmd.small_icon = "Images/tbDrapeSmall.png"
    cmd.large_icon = "Images/tbDrapeLarge.png"
    cmd.tooltip = $tStrings.GetString("Drape")
    cmd.status_bar_text = $tStrings.GetString("Drape")
    cmd.menu_text = $tStrings.GetString("Drape")
    $tools_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)
    $terrain_Drape3_loaded = true
end

$tools_terrain_submenu.add_separator

if( not $terrain_Detailer_loaded )
    cmd = UI::Command.new($tStrings.GetString("Add Detail")) { Sketchup::active_model.select_tool AddDetailTool.new }
    cmd.small_icon = "Images/tbDetailerSmall.png"
    cmd.large_icon = "Images/tbDetailerLarge.png"
    cmd.tooltip = $tStrings.GetString("Add Detail")
    cmd.status_bar_text = $tStrings.GetString("Add Detail")
    cmd.menu_text = $tStrings.GetString("Add Detail")
    $tools_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)
    $terrain_Detailer_loaded = true
end

if( not $terrain_Flipper_loaded )
    cmd = UI::Command.new($tStrings.GetString("Flip Edge")) { Sketchup::active_model.select_tool FlipEdgeTool.new }
    cmd.small_icon = "Images/tbFlipperSmall.png"
    cmd.large_icon = "Images/tbFlipperLarge.png"
    cmd.tooltip = $tStrings.GetString("Flip Edge")
    cmd.status_bar_text = $tStrings.GetString("Flip Edge")
    cmd.menu_text = $tStrings.GetString("Flip Edge")
    $tools_terrain_submenu.add_item(cmd)
    tb.add_item(cmd)
    $terrain_Flipper_loaded = true
end

state = tb.get_last_state 
if (state == TB_VISIBLE)
    tb.restore
    # Per bug 2902434, adding a timer call to restore the toolbar. This
    # fixes a toolbar resizing regression on PC as the restore() call
    # does not seem to work as the script is first loading.
    UI.start_timer(0.1, false) {
      tb.restore
    }
end
