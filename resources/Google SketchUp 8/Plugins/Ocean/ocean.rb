# Copyright 2012, Trimble Navigation Limited

# This script enables placing a model in Google Earth relative to the ocean floor,
# instead of relative to ground (sea level).

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------

def is_on_floor_bottom
  return Sketchup.active_model.get_attribute("GeoReference", "onOceanFloor") == "true";
end

def toggle_ocean
  on_floor = !is_on_floor_bottom()
  puts on_floor
  if on_floor
    Sketchup.active_model.set_attribute "GeoReference", "onOceanFloor", on_floor.to_s;
  else
    Sketchup.active_model.attribute_dictionary("GeoReference").delete_key "onOceanFloor";
  end
end

menu = UI::menu("Plugins");
menu.add_separator;
item = menu.add_item($oceanStrings.GetString("Model on the Ocean Floor")) { toggle_ocean }
menu.set_validation_proc(item) {
  is_on_floor_bottom() ? MF_CHECKED : MF_UNCHECKED;
}
