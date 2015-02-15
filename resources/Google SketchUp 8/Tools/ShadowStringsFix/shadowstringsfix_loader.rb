#!/usr/bin/ruby
#
# Copyright 2012, Trimble Navigation Limited
# License:: All Rights Reserved.
# Original Author:: Tyler Miller
#
# This file provides a toolbar with a button for toggling the "shadow strings
# bug fix" on and off in SketchUp 8 M1 and above. This bug is particularly
# prevelant on machines with an Nvidia card, while the camera is within a
# shadow volume.  Turning the experimental fix on will help eliminate the
# shadow strings, but may result in other visual artifacts.
#
require 'sketchup.rb'
require 'LangHandler.rb'

# Set up the UI hooks.
if (not $ssf_loaded)
  # Create our toolbar.
  toolbar = UI::Toolbar.new $ssf_strings.GetString("Shadow Strings Fix")
  path = "Tools/ShadowStringsFix"

  # Toggle Shadow Strings Fix command.
  name = $ssf_strings.GetString("Toggle Shadow Strings Fix")
  shadow_strings_fix_command = UI::Command.new(name) {
    Sketchup.fix_shadow_strings = !Sketchup.fix_shadow_strings?
  }
  cursor_path = Sketchup.find_support_file("stringsfixtoggle.png", path)
  small_cursor_path = Sketchup.find_support_file("stringsfixtoggle_small.png",
    path)
  shadow_strings_fix_command.large_icon = cursor_path
  shadow_strings_fix_command.small_icon = small_cursor_path
  shadow_strings_fix_command.tooltip = name
  shadow_strings_fix_command.set_validation_proc {
    if Sketchup.fix_shadow_strings?
      MF_CHECKED
    else
      MF_ENABLED
    end
  }
  toolbar.add_item shadow_strings_fix_command

  # Show toolbar if it was open when we shutdown.
  state = toolbar.get_last_state
  if (state == TB_VISIBLE)
    toolbar.restore
    # Per bug 2902434, adding a timer call to restore the toolbar. This
    # fixes a toolbar resizing regression on PC as the restore() call
    # does not seem to work as the script is first loading.
    UI.start_timer(0.1, false) {
      toolbar.restore
    }
  end

  $ssf_loaded = true
end
