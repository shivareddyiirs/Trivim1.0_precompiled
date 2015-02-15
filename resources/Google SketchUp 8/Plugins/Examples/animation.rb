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

# This is an example of a simple animation that spins the model around

class ViewSpinner

def initialize
    # save the center of rotation
    model = Sketchup.active_model
    view = model.active_view
    camera = view.camera
    @target = model.bounds.center
    @up = Geom::Vector3d.new(0, 0, 1)
    @distance = camera.eye.distance @target
    @zmin = @target.z
    @zmax = @zmin + @distance
    @dz = @distance / 300
    @z = @zmin
    @angle = 0
    @frame = 0;
    @startTime = Time.now
    Sketchup::set_status_text($exStrings.GetString("FPS"), 1)
end

# The only required method for an animation is nextFrame.  It is called 
# whenever you need to show the next frame of the animation.
def nextFrame(view)
    @frame = @frame + 1
    totalTime = Time.now - @startTime
    fps = 1
    if( totalTime > 0.001 )
        fps = @frame / totalTime
    end
    fps = fps.to_i
    Sketchup::set_status_text(fps, 2)
    
    # Compute the eye point for this frame
    a = @angle * Math::PI / 180.0
    x = @target.x + (@distance * Math::sin(a))
    y = @target.y + (@distance * Math::cos(a))
    eye = Geom::Point3d.new(x, y, @z)
    view.camera.set(eye, @target, @up)
    @angle = (@angle+1)%360
    view.show_frame
    
        # make the camera move up and down
    @z += @dz
    if( @z > @zmax )
        @z = @zmax
        @dz = -@dz
    elsif( @z < @zmin )
        @z = @zmin
        @dz = -@dz
    end
    
    # If nextFrame returns false, the animation will stop
    # Uncommenting the next line will cuase th animation to
    # stop after one revolution.
    # return @frame < 360
    return true
end

# The stop method will be called when SketchUp wants an animation to stop
# this method is optional.
def stop
    # clear the stuff we displayed on the status line
    Sketchup::set_status_text("", 1)
    Sketchup::set_status_text("", 2)
end

end # class ViewSpinner

# This is just a function that starts spinning the active view
def spinview
    Sketchup.active_model.active_view.animation = ViewSpinner.new
end

#-----------------------------------------------------------------------------

# Add an Animations sub-menu to the Camera menu
if( not file_loaded?("animation.rb") )
    #Note: We don't translate the Menu names - the Ruby API assumes you are 
    #using English names for Menus.
    add_separator_to_menu("Camera")
    animation_menu = UI.menu("Camera").add_submenu($exStrings.GetString("Animations"))
    animation_menu.add_item($exStrings.GetString("Spin View")) {spinview}
    animation_menu.add_item($exStrings.GetString("Stop Spinning")) {
        Sketchup.active_model.active_view.animation = nil
    }
end

file_loaded("animation.rb")
