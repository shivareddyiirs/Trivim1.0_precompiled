#!/usr/bin/ruby
#
# Copyright 2012, Trimble Navigation Limited
# License:: All Rights Reserved.
# Original Author:: Scott Lininger (mailto:scott@sketchup.com)
#
# This file declares the WebTextures class that provides hooks for showing
# a web dialog with UI to select a texture and push it down to SketchUp
# for auto-texturing of selected faces.
#
#     WebTextures          Self-contained object for showing dialog.
#
require 'sketchup.rb'
require 'LangHandler.rb'

# The WebTextures class. An instance of this class handles all of the
# dialog display and callbacks for grabbing and applying textures from
# the web. You'll find the code that creates the instance at the
# bottom of this file.
#
class WebTextures

  # Define some constants.
  WT_DIALOG_REGISTRY_KEY = 'WebTextures'
  WT_DIALOG_WIDTH = 400
  WT_DIALOG_HEIGHT = 700
  WT_DIALOG_MIN_WIDTH = 400
  WT_DIALOG_MIN_HEIGHT = 360
  WT_DIALOG_X = 10
  WT_DIALOG_Y = 100
  WT_DEFAULT_TEXTURE_WIDTH = 144
  WT_VERY_LARGE_NUMBER = 999999
  WT_REGISTRY_SECTION = "WebTextures"
  WT_REGISTRY_KEY = "AgreedToEula"
  WT_MAX_FACES_TO_PROCESS = 500

  # Creates a new WebTextures object.
  #
  #   Args:
  #     title: string title of the WebDialog to display
  #     strings: optional LanguageHandler object containing translated strings
  #
  #   Returns:
  #     Nothing
  #
  def initialize(title, strings = LanguageHandler.new("unknown.strings"))
    @strings = strings

    # PC Load paths will have a ':' after the drive letter.
    @is_mac = ($LOAD_PATH[0][1..1] != ":")

    # Cache the online state. We will only recheck if we're offline.
    @is_online = false

    # Find out if they've agreed to our EULA.
    @agreed_to_eula = Sketchup.read_default WT_REGISTRY_SECTION,
      WT_REGISTRY_KEY, false

    # Remember the last lat/lng we passed up from the shadow_info.
    # If it changes, we'll tell the webdialog to reset.
    @last_shadow_info_json = false

    # Create our dialog.
    keys = {
      :dialog_title => title,
      :scrollable => false,
      :preferences_key => WT_DIALOG_REGISTRY_KEY,
      :height => WT_DIALOG_HEIGHT,
      :width => WT_DIALOG_WIDTH,
      :min_height => WT_DIALOG_MIN_HEIGHT,
      :min_width => WT_DIALOG_MIN_WIDTH,
      :left => WT_DIALOG_X,
      :top => WT_DIALOG_Y,
      :resizable => true,
      :mac_only_use_nswindow => true}
    @dialog = UI::WebDialog.new(keys)

    @dialog.set_background_color('000000')
    @dialog.set_html('<body bgcolor="#FF0000"></body>')

    # Attach all of our callbacks.
    @dialog.add_action_callback("grab") { |d, p| grab(p) }
    @dialog.add_action_callback("agree_to_eula") { |d, p| agree_to_eula(p) }
    @dialog.add_action_callback("store_ui_state") { |d, p| store_ui_state(p) }
    @dialog.add_action_callback("pull_ui_state") { |d, p| pull_ui_state(p) }
    @dialog.add_action_callback("get_flash") { |d, p| get_flash(p) }
    @dialog.add_action_callback("pull_selected_shape") { |d,p|
      pull_selected_shape(p)
    }
    @dialog.add_action_callback("open_url") { |d, p| open_url(p) }
    @dialog.add_action_callback("open_eula") { |d, p| open_eula() }

    # A hash to store arbitrary state about the WebDialog's embedded html UI.
    @ui_state = {}

    # Version string that will be written as an attribute onto any created
    # material.
    @version_ruby = "1.0.0"

    # Place where we will save the texture to.
    if @is_mac
      @image_path = temp_directory + '/temp.jpg'
    else
      @image_path = temp_directory + '\\temp.jpg'
    end

    # Where to load the url from.
    # TODO(scottlininger): Replace the default URL with the live one
    # once it's live.
    @url = Sketchup.get_datfile_info 'WEB_TEXTURES',
        'http://sketchup.google.com/3dwarehouse/skptextures'
    @dialog.set_url(@url)
    show()
  end


  # A callback that opens a url in the default browser.
  #
  #   Args:
  #     url: The URL
  #
  #   Returns:
  #     Nothing
  #
  def open_url(url)
    UI.openURL(url)
  end


  # A callback that opens the SketchUp EULA in the default browser.
  #
  #   Args:
  #     None
  #
  #   Returns:
  #     Nothing
  #
  def open_eula()
    if Sketchup.is_pro?
      url = Sketchup.get_datfile_info 'EULA_PRO',
        'http://sketchup.com/intl/' + Sketchup.get_locale + '/redirects/gsu8/eula_pro.html'
    else
      url = Sketchup.get_datfile_info 'EULA',
        'http://sketchup.com/intl/' + Sketchup.get_locale + '/redirects/gsu8/eula.html'
    end
    UI.openURL(url)
  end


  # A callback that allows javascript to get a string describing the shape
  # of the currently selected face. If anything but a single face is selected,
  # then a simple rectangle will be sent. By default, it replies to the
  # javascript by setting a global js variable called 'shapeString', but
  # if an optional param called oncomplete is passed, then it will call
  # that function instead.
  #
  #   Args:
  #     params: The params string that was sent as part of the callback. It
  #             may have an optional "oncomplete" param.
  #
  #   Returns:
  #     Nothing
  #
  def pull_selected_shape(params)
    params = query_to_hash(params)

    # Figure out how many faces are selected.
    selection = Sketchup.active_model.selection
    faces = []
    for entity in selection
      faces.push entity if entity.typename == "Face"
    end

    # Generate a string describing the shape if only one is selected.
    # Otherwise just describe a rectangle shape.
    uv_strings = []
    if faces.length == 1
      corners, vertex_uvs = get_uvs(faces[0])
      for uv in vertex_uvs
        uv_strings.push(uv['u'].to_s + ',' + uv['v'].to_s)
      end
    else
      uv_strings.push('0,0')
      uv_strings.push('1,0')
      uv_strings.push('1,1')
      uv_strings.push('0,1')
    end
    shape_string = uv_strings.join(':');

    # Figure out the width and height if only one face is selected.
    # Otherwise just describe a square.
    if corners.to_s != ""
      width = corners[0].distance corners[1]
      height = corners[1].distance corners[2]
    else
      width = 1
      height = 1
    end

    # Walk the selection and build a string describing the geometry. This
    # will be encoded as a nested JSON array of x, y, z locations, like this:
    #
    # [
    #   [{x:0, y:0, z:0}, {x:1, y:1, z:0}, {x:1, y:0, z:1}],   // face 1
    #   [{x:0, y:0, z:2}, {x:1, y:1, z:2}, {x:1, y:0, z:3}],   // face 2
    #   [{x:0, y:0, z:4}, {x:1, y:1, z:4}, {x:1, y:0, z:5}]   // etc...
    # ]
    bb = Geom::BoundingBox.new()
    geometry_json = '['
    if faces.length <= WT_MAX_FACES_TO_PROCESS
      loop_strings = []
      for face in faces
        vertex_strings = []
        for vertex in face.outer_loop.vertices
          bb.add(vertex.position)
          loc = vertex.position
          vertex_strings.push('{x:' + clean_for_json(loc.x.to_f) + ',' +
              'y:' + clean_for_json(loc.y.to_f) + ',' +
              'z:' + clean_for_json(loc.z.to_f) + '}')
        end
        loop_strings.push(vertex_strings.join(','))
      end
      geometry_json += loop_strings.join(',');
    end
    geometry_json += ']'

    # Calculate the latlng center of our selection.
    latlng = Sketchup.active_model.point_to_latlong(bb.center)

    # Execute a JS command to reply.
    if params['oncomplete'] != nil
      cmd = params['oncomplete'] + '("' + shape_string +
        '", ' + width.to_f.to_s + ', ' + height.to_f.to_s + ', "", ' +
        clean_for_json(latlng[1].to_f) + ', ' +
        clean_for_json(latlng[0].to_f) + ', ' +
        geometry_json + ')'
    else
      cmd = "shapeString = '" + shape_string + "'"
    end
    @dialog.execute_script(cmd)

  end


  # A callback that tells SketchUp that the user has agreed to our EULA. This
  # will set a registry value to record that fact as a unix timestamp.
  #
  #   Args:
  #     params: The params string that was sent as part of the callback. It
  #             may have an optional "oncomplete" param.
  #
  #   Returns:
  #     Nothing
  #
  def agree_to_eula(params)
    params = query_to_hash(params)
    Sketchup.write_default WT_REGISTRY_SECTION, WT_REGISTRY_KEY, Time.now.to_i
    @agreed_to_eula = true
  end


  # A callback that allows the web dialog's Javascript to send down an
  # arbitrary JSON state string that will be sent back up to the dialog
  # should it be closed and reopened.
  #
  # Each JSON string is stored by key in the @ui_state hash. This allows for
  # different sections of the WebDialog UI to store different states
  # without clobbering each other. For example, Street View might want
  # to store the current yaw, pan, and zoom, while a Picasa photo
  # picker might want to store the current photo URL being viewed.
  #
  #   Args:
  #     params: The params string that was sent as part of the callback. It is
  #             expected to contain a param called "key" and "state" that has
  #             the JSON string we care to store.
  #
  #   Returns:
  #     Nothing
  #
  def store_ui_state(params)
    params = query_to_hash(params)
    @ui_state[params['key']] = params['state']
  end

  # A callback that allows the web dialog's Javascript to request the
  # JSON state that was sent down to Ruby via store_state.
  #
  #   Args:
  #     params: The params string that was sent as part of the callback.
  #
  #   Returns:
  #     Nothing
  #
  def pull_ui_state(params)
    params = query_to_hash(params)

    json = generate_ui_state_json()

    # Execute a JS command to reply.
    if params['oncomplete'] != nil
      cmd = params['oncomplete'] + '(' + json + ')'
    else
      cmd = "uiState = " + json
    end
    @dialog.execute_script(cmd)
  end


  # A callback that tells the user they need to install flash. This has
  # different behavior mac vs. pc. On mac, we show them some messages
  # and send them to Adobe to run the install. On PC, we tell them what's
  # happening and to expect an ActiveX install box.
  #
  #   Args:
  #     params: The params string that was sent as part of the callback.
  #             It could contain 'message' or 'message2', which defines what
  #             messages to show the user, and 'url' which defines where to open
  #             the user's browser on Mac to should they click the 'yes' option.
  #             If none of these is passed down, we use default values.
  #
  #   Returns:
  #     Nothing
  #
  def get_flash(params)
    params = query_to_hash(params)

   if @is_mac

      # Show a Yes/No message box.
      if params['message'] != nil
        msg = params['message']
      else
        msg = @strings.GetString("Photo Textures requires the latest" +
          " version of the Flash player. Would you like to install it now?")
      end
      response = UI.messagebox(msg, MB_YESNO);

      # If they said yes, open the install URL in their default browser.
      if response == 6 # YES
        if params['message2'] != nil
          msg = params['message2']
        else
          msg = @strings.GetString("We will now send you to an installation" +
            " page for Flash player. Once you are done with the install," +
            " please restart SketchUp.")
        end
        response = UI.messagebox(msg, MB_OKCANCEL);

        if response == 1 # OK
          if params['url'] != nil
            url = params['url']
          else
            url = Sketchup.get_datfile_info 'INSTALL_FLASH',
              'http://get.adobe.com/flashplayer/'
          end
          UI.openURL url
        end
      end
      @dialog.close()
    else
      if params['message'] != nil
        msg = params['message']
      else
        msg = @strings.GetString("Photo Textures requires the latest" +
          " version of the Flash player. An installation box for this should" +
          " appear shortly. (If it does not, please visit www.flash.com to" +
          " install.) Once you have agreed to the installation, you may need" +
          " to restart SketchUp.")
      end
      UI.messagebox(msg)
    end
  end

  # Generates a JSON string representing the current shadow_info
  #
  #   Args:
  #     None
  #
  #   Returns:
  #     json: string representing our current shadow_info.
  #
  def generate_shadow_info_json()
    shadow_info = Sketchup.active_model.shadow_info
    return '"shadow_info":{ ' +
      '"city": "' + shadow_info["City"] + '", ' +
      '"country":"' + shadow_info["Country"] + '", ' +
      '"lat": "' + shadow_info["Latitude"].to_s + '", ' +
      '"lng": "' + shadow_info["Longitude"].to_s + '" '
  end


  # Generates a JSON string representing our complete UI state.
  #
  # Since many of our web textures UI ideas involve some notion of geolocation,
  # this callback will always report on the that info inside a key called
  # 'shadow_info'. By default, it replies to the JavaScript by setting a global
  # js variable called 'uiState', but if an optional param called oncomplete
  # is passed, then it will call that function instead.
  #
  #   Args:
  #     None
  #
  #   Returns:
  #     json: string representing our current ui state.
  #
  def generate_ui_state_json()

    # Build out a JSON string of all of our state info.
    json = '{'

    if @agreed_to_eula
      json += '"agreedToEula":"' + @agreed_to_eula.to_s + '",';
    end

    # Figure out the lat/lng of the center point of the current selection.
    # This will be passed up to the WebDialog so we can use it to improve
    # pose guessing.
    selection = Sketchup.active_model.selection
    if selection.length > 0 && selection.length <= WT_MAX_FACES_TO_PROCESS
      bb = Geom::BoundingBox.new()
      faces = []
      for entity in selection
        if entity.typename == "Face"
          faces.push entity
          for vertex in entity.vertices
            bb.add(vertex.position)
          end
        end
      end
      latlng = Sketchup.active_model.point_to_latlong(bb.center)
      json += '"selectionLat":"' + clean_for_json(latlng[1].to_f) + '",';
      json += '"selectionLng":"' + clean_for_json(latlng[0].to_f) + '",';
      json += '"selectionAlt":"' + clean_for_json(latlng[2].to_f) + '",';

      # If a single face is selected, calculate a lat/lng that is 50'
      # in front of the face. This gives much better Street View
      # pose guesses for looking at faces that are along the "sides"
      # of buildings.
      if faces.length == 1
        vector = faces.first.normal
        vector.length = 12.0 * 50.0
        offset_pt = bb.center.offset vector
        latlng = Sketchup.active_model.point_to_latlong(offset_pt)
        json += '"selectionOffsetLat":"' + clean_for_json(latlng[1].to_f) + '",';
        json += '"selectionOffsetLng":"' + clean_for_json(latlng[0].to_f) + '",';
        json += '"selectionOffsetAlt":"' + clean_for_json(latlng[2].to_f) + '",';
      end
    end



    for key in @ui_state.keys
      json += '"' + key + '":' + @ui_state[key] + ','
    end
    shadow_info_json = generate_shadow_info_json()

    # Store the last lat/lng so we know if the user resets them we can
    # reset the WebDialog's view.
    if shadow_info_json != @last_shadow_info_json
      json += shadow_info_json + ', "hasChanged": 1}}'
    else
      json += shadow_info_json + '}}'
    end

    @last_shadow_info_json = shadow_info_json
    return json
  end

  # A callback that allows the web dialog to tell SketchUp to take a screen
  # grab of the current dialog and apply that texture to selected faces.
  #
  # It expects a param called region that defines four x,y corners of the
  # pixel region to map to the currently selected face(s). Each of these
  # interior corners will be UV mapped onto the 4 geometric corners of the
  # Face. (In the case of a non-rectangular face, it will calculate "virtual"
  # corners that bound the face and map to those instead.)
  #
  # The string will be four x,y local texture coordinates separated by colons.
  # A typical string might look like this... '10,90:120,100:120,5:10,5'
  #
  # The first corner in the list (c0) is the bottom left, and they go
  # counter-clockwise from there. The x,y origin (0,0) is located at the top
  # left of the texture image.
  #
  #   c3----------c2
  #   |           |
  #   c0----      |
  #         ------c1
  #
  #   Args:
  #     params: The params string that was sent as part of the callback.
  #
  #   Returns:
  #     Nothing, but it does call a Javascript method called onGrabComplete()
  #     when it is complete.
  #
  def grab(params)
    begin
      params = query_to_hash(params)

      # Make a list of the faces to texture.
      faces_to_texture = []
      selection = Sketchup.active_model.selection
      for face in selection
        if face.typename == "Face"
          faces_to_texture.push(face)
        end
      end

      # Bail out if there are no selected faces.
      if faces_to_texture.length == 0
        UI.messagebox(@strings.GetString("Please select one or more faces" +
          " in your SketchUp model that you would like to photo texture" +
          " and try again."))
        if params['oncomplete'] != nil
          @dialog.execute_script(params['oncomplete'])
        end
        return
      end

      op = @strings.GetString("Apply Photo Texture")
      Sketchup.active_model.start_operation op, true

      # Capture the screen and create the material.
      if params['compression'] == nil
        params['compression'] = 75
      end
      if params['top_left_x'] == nil
        @dialog.write_image(@image_path, params['compression'].to_i)
      else
        @dialog.write_image(@image_path, params['compression'].to_i,
          params['top_left_x'].to_i,
          params['top_left_y'].to_i,
          params['bottom_right_x'].to_i,
          params['bottom_right_y'].to_i)
      end


      file = @image_path.gsub(/\\/, '/')
      materials = Sketchup.active_model.materials
      m = materials.add @strings.GetString("Photo Texture")
      m.texture = file
      texture = m.texture

      if params['texture_width'] == nil
        texture.size = WT_DEFAULT_TEXTURE_WIDTH
      else
        texture.size = params['texture_width'].to_f
      end

      pixel_width = texture.image_width.to_f
      pixel_height = texture.image_height.to_f

      # Attach some attributes to the material so we can view on 3D Warehouse.
      m.set_attribute "web_textures", "version_ruby", @version_ruby
      m.set_attribute "web_textures", "ui_state", generate_ui_state_json()
      m.set_attribute "web_textures", "created", Time.now.to_i

      # If a region param was passed that defines some UV mapping info, then
      # do UV mapping. Otherwise, just paint all faces with the untransformed
      # texture.
      if params['region'] != nil
        uvs = []
        corners = params['region'].split(':')
        for corner in corners
          u, v = corner.split(',')
          u = u.to_f
          v = v.to_f
          u = u / pixel_width
          v = (pixel_height - v) / pixel_height
          uvs.push(u.to_s + ',' + v.to_s)
        end

        if faces_to_texture.length == 1
          # Apply the texture to the side of the face the camera is looking at.
          # TODO(scottlininger): Could be better to rewrite to use the plane
          # equation. See http://mondrian.corp.google.com/file/11865235 for
          # commentary.
          face = faces_to_texture[0]
          camera_direction = Sketchup.active_model.active_view.camera.direction
          angle = face.normal.angle_between camera_direction
          if angle.radians < 90
            uv_texture(face, m, uvs, false, true)
          else
            uv_texture(face, m, uvs, true, false)
          end
        else
          # Apply the texture to the front of all selected faces.
          for face in faces_to_texture
            uv_texture(face, m, uvs, true, false)
          end
        end

      else
        # Paint the texture onto all selected faces.
        for face in faces_to_texture
          face.material = m
        end
      end

      if params['oncomplete'] != nil
        @dialog.execute_script(params['oncomplete'])
      end

      # Delete the temporary jpg file.
      File.delete(file)

      Sketchup.active_model.commit_operation

    rescue Exception => e
      puts "#{e.class}: #{e.message}"
      UI.messagebox(
          @strings.GetString("There was an error pulling in the texture.") +
          "\n" +
          @strings.GetString("Please try again.") + "\n\n" +
          "#{e.class}: #{e.message}")
      if params['oncomplete'] != nil
        @dialog.execute_script(params['oncomplete'])
      end
    end
  end


  # UV Textures a face, meaning it applies a texture and positions it to match
  # four coordinate pairings passed in. Each "corner" of the face will
  # get a corresponding u,v coordinate local to the texture itself, and
  # SketchUp will scale and skew the texture so that the u,v location matches
  # with each corner.
  #
  #   Args:
  #     face:     The face to texture.
  #     material: The Material object to apply. It must already contain the
  #               texture.
  #     uvs:      An 4-element array of strings. Each string is a single u,v
  #               coordinate such as "0,0" or ".25,1.0"
  #     do_front: If true, apply to front of face.
  #     do_back:  If true, apply to back of face.
  #
  #   Returns:
  #     Nothing
  def uv_texture(face, material, uvs, do_front=true, do_back=false)
    corners, vertex_uvs = get_uvs(face)
    pts = []
    for i in 0..3
      pts << corners[i].to_a
      uv = uvs[i].split(',')
      pts << [uv[0].to_f,uv[1].to_f]
    end
    if do_front
      face.position_material material, pts, true
    end
    if do_back
      back_pts = []
      back_pts[0] = pts[2]
      back_pts[1] = pts[1]
      back_pts[2] = pts[0]
      back_pts[3] = pts[3]
      back_pts[4] = pts[6]
      back_pts[5] = pts[5]
      back_pts[6] = pts[4]
      back_pts[7] = pts[7]
      face.position_material material, back_pts, false
    end
  end


  # Turns a query string into a hash. So something like "x=100&z=2" will be
  # translated into { x:"100", z:"2" }.
  #
  #   Args:
  #     data: The string to process.
  #
  #   Returns:
  #     param_hash: The nice name/value paired hash.
  def query_to_hash(data)
    param_pairs = data.to_s.split('&')
    param_hash = {}
    for param in param_pairs
      name, value = param.split('=')
      param_hash[name] = value
    end
    return param_hash
  end


  # Pops open the dialog.
  #
  #   Args:
  #     None.
  #
  #   Returns:
  #     Nothing
  def show(force_refresh = false)

    # If we don't think we're connected, or if it's the first time we've
    # launched the dialog, then ask SketchUp if we're online.
    if @is_online == false
      @is_online = Sketchup.is_online
    end

    # If we're still offline, show a message.
    if @is_online == false
      UI.messagebox(@strings.GetString("Photo Textures requires a connection " +
        "to the internet and yours appears to be down. Please reset " +
        "your connection and try again."))
      return
    end

    # If the geo location has changed, force a refresh of the dialog.
    if @dialog.visible?
      if force_refresh == true
        @dialog.execute_script('refresh()');
      end
    end

    if @dialog.visible? == false
      if @is_mac
        # Mac has refresh issues with flash, so reset URL.
        @dialog.set_url(@url)
        @dialog.show_modal
      else
        @dialog.show
      end
    end

    if @is_mac
      # Force focus on the mac.
      @dialog.bring_to_front
    end

  end


  # There are two things that we calculate in this function: first, the
  # 4 "corners" in model space that define a rectangular bounding poly of the
  # underlying face. Second, an array of the uv points for each vertex in the
  # face, relative to that bounding poly.
  #
  #   Args:
  #     face: the face to calculate corners and vertex uvs for
  #
  #   Returns:
  #     corners:    An Array of Point3d objects describing the four "corners"
  #                 surrounding the face. These may or may not be vertices. For
  #                 example, a circular face or a diamond will have 4 corners
  #                 where none of them match up with a vertex. A square face
  #                 will have all 4 corners overlap with a vertex.
  #     vertex_uvs: An Array of hashes. Each hash contains a "u" and a "v"
  #                 member, so that you'll get something like this:
  #                 [ {u:0,v:1}, {u:0.75,v:.25}, {u:0.25,v:.75}, {u:0.25,v:.75}]
  #
  def get_uvs(face)

    # Get the axes for a plane that the face is on, with
    # the x axis parallel to the ground plane and the z axis
    # corresponding to the face normal.
    xaxis, yaxis, zaxis = face.normal.axes

    # Calculate points that define a "bottom" and a "left"
    # direction, as would be viewed by a person looking from
    # the camera toward the face with their feet pointing
    # downward. (In the case of a face that is parallel to
    # the ground, this method will return "bottom" as being
    # in the negative y direction.)
    far_left = xaxis.reverse
    far_left.length = WT_VERY_LARGE_NUMBER
    left = face.vertices[0].position
    left.offset! far_left

    far_bottom = yaxis.reverse
    far_bottom.length = WT_VERY_LARGE_NUMBER
    bottom = face.vertices[0].position
    bottom.offset! far_bottom

    # Figure out which face vertices define the 4 edges of
    # our bounding poly. Assume it's the first one for the moment.
    left_most_pt = face.vertices[0].position
    right_most_pt = face.vertices[0].position
    top_most_pt = face.vertices[0].position
    bottom_most_pt = face.vertices[0].position

    # Look at each vertex and decide if it's a better fit for
    # being a bounding point.
    for i in 1..(face.vertices.length-1)
      pt = face.vertices[i].position

      if pt.distance(left) < left_most_pt.distance(left)
        left_most_pt = pt
      elsif pt.distance(left) > right_most_pt.distance(left)
        right_most_pt = pt
      end

      if pt.distance(bottom) < bottom_most_pt.distance(bottom)
        bottom_most_pt = pt
      elsif pt.distance(bottom) > top_most_pt.distance(bottom)
        top_most_pt = pt
      end
    end

    # Now that we have all four bounding edges, calculate
    # the 4 corners of our bounding poly.
    left_line = [left_most_pt, yaxis]
    right_line = [right_most_pt, yaxis]
    top_line = [top_most_pt, xaxis]
    bottom_line = [bottom_most_pt, xaxis]

    corners = []
    corners << Geom.intersect_line_line(left_line, bottom_line)
    corners << Geom.intersect_line_line(right_line, bottom_line)
    corners << Geom.intersect_line_line(right_line, top_line)
    corners << Geom.intersect_line_line(left_line, top_line)

    # Now that we've calculated a perfect "bounding rectangle" for the
    # face, we can calculate u,v coordinates within that little
    # coordinate space. The "bottom left" corner of the rectangle is
    # at uv point 0,0 and the "top right" is at 1,1. Therefore, all of
    # the vertex u,v coordinates will lie between 0 and 1.
    uvs = []
    w = right_most_pt.distance_to_line(left_line)
    h = top_most_pt.distance_to_line(bottom_line)
    for vertex in face.outer_loop.vertices
      uv = {}
      uv['u'] = vertex.position.distance_to_line(left_line) / w
      uv['v'] = vertex.position.distance_to_line(bottom_line) / h
      uvs.push uv
    end

    return corners, uvs
  end


  # Cleans up strings to inclusion inside JSON string values
  #
  #   Args:
  #      value: a string that we want escaped
  #
  #   Returns:
  #      string: a JSON-friendly version suitable for parsing in javascript
  def clean_for_json(value)
    value = value.to_s
    value = value.gsub(/\\/,'&#92;')
    value = value.gsub(/\"/,'&quot;')
    value = value.gsub(/\n/,'\n')
    if value.index(/e-\d\d\d/) == value.length-5
      value = "0.0";
    end
    return value
  end


  # Returns the system's temporary directory.
  #
  #   Args:
  #      none
  #
  #   Returns:
  #      string: the pull path to the temp directory.
  def temp_directory
    if @temp_dir
      return @temp_dir
    end
    tmp = '.'
    for dir in [ENV['TMPDIR'], ENV['TMP'], ENV['TEMP'],
        ENV['USERPROFILE'], '/tmp']
      if dir and File.directory?(dir) and File.writable?(dir)
        tmp = dir
        break
      end
    end
    @temp_dir = File.expand_path(tmp)
    return @temp_dir
  end
end


#
# Set up the UI hooks for the standard grab texture functionality.
#
#
#
#
#
if (not $wt_loaded)

  # Create the context menu item.
  UI.add_context_menu_handler do |context_menu|
    selection = Sketchup.active_model.selection
    has_faces = false
    for entity in selection
      if entity.typename == "Face"
        has_faces = true
        break
      end
    end
    if has_faces
      context_menu.add_separator
      context_menu.add_item($wt_strings.GetString("Add Photo Texture")) {
        if not $wt_instance
          $wt_instance = WebTextures.new($wt_strings.GetString("Photo Textures"),
            $wt_strings)
        else
          $wt_instance.show(true)
        end
      }
    end
  end

  # Create the Windows > Web Textures menu item.
  menu = UI.menu("Windows")
  menu_text = $wt_strings.GetString("Photo Textures")
  cmd = UI::Command.new(menu_text) {
    if not $wt_instance
      $wt_instance = WebTextures.new($wt_strings.GetString("Photo Textures"),
        $wt_strings)
    else
      $wt_instance.show()
    end
  }
  cmd.tooltip = menu_text
  menu.add_item(cmd)
  $wt_loaded = true
end
