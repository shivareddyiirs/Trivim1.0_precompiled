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
# Name        :   Match Photo Extension
# Description :   
#
#    create_box:    Creates a cube whose side is defined by the arg.
#    make_pano_pm:  Creates a set of photo matched pages given a series
#                   of panoramic images.  Also creates a box (using
#                   create_box) which makes it easier to start sketching
#                   over top of the images.
#
# Menu Item   :   N/A
# Context Menu:   N/A
# Usage       :   N/A
# Date        :   10/16/2008
# Type        :   N/A
#-----------------------------------------------------------------------------
require 'sketchup.rb'
require 'LangHandler.rb'

# Using language handler makes sure that the string "Create Box" gets translated.
# This is important as this string is shown in undo menu. 
$make_pano_string = LanguageHandler.new("gettingstarted.strings");

# This function creates a cube. The size of the cube is passed in but
# defaults to 100.0.  One corner of the cube lies on the origin.

def create_box(d = 100.0)
  model = Sketchup.active_model

  # Create a transaction so the box is one undo
  model.start_operation $make_pano_string.GetString("Create Box")

  entities = model.active_entities
  group = entities.add_group
  entities = group.entities
 
  pts = []
  pts[0] = [0, 0, 0]
  pts[1] = [d, 0, 0]
  pts[2] = [d, d, 0]
  pts[3] = [0, d, 0]

  base = entities.add_face pts
  d = -d if (base.normal.dot(Z_AXIS) < 0)
  base.pushpull d

  model.commit_operation
  model.rendering_options["ModelTransparency"] = true

end

# This function takes in the following args:
# - Size of the cube
# - Full path name for each image.  Any of them can be nil, but normally
#   you would supply at least the first four.
#
def make_pano_pm(box_side,
                 front_image = nil,
                 right_image = nil,
                 back_image = nil,
                 left_image = nil,
                 top_image = nil,
                 bottom_image = nil)
  create_box(box_side)
  d2 = box_side / 2

  eye = [d2, d2, d2]
  #Three axis
  x = [1, 0, 0]
  y = [0, 1, 0]
  z = [0, 0, 1]

  # Access the model
  model = Sketchup.active_model
  pages = model.pages

  #Front Image
  target = [d2, d2+1, d2]
  up = z
  # camera eye, target, up_direction and prespective = true|false fov =90
  camera1 = Sketchup::Camera.new(eye, target, up, true, 90)
  page = pages.add_matchphoto_page(front_image, camera1, "Front")

  #Right Image
  if right_image != nil
    target = [d2+1, d2, d2]
    camera2 = Sketchup::Camera.new(eye, target, up, true, 90)
    page = pages.add_matchphoto_page(right_image, camera2, "Right")
  end

  #Back Image
  if back_image != nil
    target = [d2, d2-1, d2]
    camera3 = Sketchup::Camera.new(eye, target, up, true, 90)
    page = pages.add_matchphoto_page(back_image, camera3, "Back")
  end

  #Left Image
  if left_image != nil
    target = [d2-1, d2, d2]
    camera4 = Sketchup::Camera.new(eye, target, up, true, 90)
    page = pages.add_matchphoto_page(left_image, camera4, "Left")
  end

  # Top Umage
  if top_image != nil
    target = [d2, d2, d2+1]
    up = x
    camera5 = Sketchup::Camera.new(eye, target, up, true, 90)
    page = pages.add_matchphoto_page(top_image, camera5, "Top")
  end

  # Bottom Image
  if bottom_image != nil
    target = [d2, d2, d2-1]
    up = [-1, 0, 0]
    camera6 = Sketchup::Camera.new(eye, target, up, true, 90)
    page = pages.add_matchphoto_page(bottom_image, camera6, "Bottom")
  end

  pages.selected_page = page
end

