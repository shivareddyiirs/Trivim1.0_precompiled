require 'sketchup.rb'
require 'extensions.rb'


# Add a menu item to launch our plugin.
UI.menu("PlugIns").add_item("Generate Buildings from Data_Auto"){
	#show panel for error detection
	# temp_display_file = File.open("C:\\pSApp\\tempFiles\\temp_for_display.txt","a")
	Sketchup.send_action "showRubyPanel:"
	# tempfile = "C:\\pSApp\\tempFiles\\temp.txt"
	
	drr = Dir.chdir('.\..\..')
	drr = Dir.getwd
	temp_display_file = File.open(drr+"/bin/3d-modelling/temp_for_display.txt","w")	
	tempfile = drr+"/bin/3d-modelling/temp.txt"
	
	base_address = IO.readlines(tempfile)
	#Dir.chdir("C:/pSApp/input")
	Dir.chdir(base_address[0])
	count = 0
	x = Dir.pwd
	y = Dir.entries(x)
	for i in 2..y.length
		if(File::directory?(y[i].to_s))
			for j in 2..y.length
				if(y[i].to_s == "build#{j-1}")
					count = count + 1
				end
			end		
		end
	end
	UI.messagebox "There are "+count.to_s+" buildings to be made..."
	
	for i in 1..count
		h_file = base_address[0].to_s+"\\build#{i}\\heights.txt"
		b_file = base_address[0].to_s+"\\build#{i}\\build#{i}.txt"
		list = parameters_file(h_file,b_file)
		
		floors = list[2].to_i
	    f = list[2] + 1                     #floor number
		x = list[2+f]
		y = list[3+f]
		ht = 0.0
		f = f.to_int
		list1 = [0.0,x,y]
		# Create a series of "points", each a 3-item array containing x, y, and z. # keep points in any one plane  # and pull along the plane whose coordinate is zero
		iterator = list[0].to_i
		for j in 1..iterator
			temp = [list[2*j+1+f],list[2*j+f]]
			latlong = Geom::LatLong.new(temp)
			list[2*j+f] = latlong.to_utm.x
			list[1+2*j+f] = latlong.to_utm.y
		end
		for j in 1..floors
			pic_address = base_address[0].to_s+"\\build#{i}\\build#{i}_#{j}.jpg"
			if(!File::exist?(pic_address))
				pic_address = base_address[0].to_s+"\\build#{i}\\build#{i}_#{j}.png"
				if(!File::exist?(pic_address))
					pic_address = base_address[0].to_s+"\\build#{i}_#{j}.bmp"		### keep file format jpg or png or bmp onllyyy
				end
			end
			#UI.messagebox("list is")
			#UI.messagebox(list)
			model = drawBuilding(list,list[2+j],ht,f,pic_address)
			assignGeoData_shadow(model,list1)
			
			output_address = IO.readlines(drr+"/bin/curr_proj.txt")[0]+"/output/build"
			name = output_address+i.to_s+'_' + j.to_s + '.kmz'
			exportBuilding(model,name)
			#UI.messagebox("model is")
			#UI.messagebox(model)
			#exportBuilding(model,name)
			ht = ht + list[2+j]
			Sketchup.active_model.entities.clear!
			Sketchup.active_model.materials.remove "face-pic"
		end
		temp_display_file.syswrite("\ndone build#{i}......")
	end
	UI.messagebox "Finished Model Generation\nExit sketchup without saving anything..."
	
}


def drawBuilding(list,h_in,h,f,address)  
  
  # Get handles to our model and the Entities collection it contains.
  model = Sketchup.active_model
  if (! model)
	UI.messagebox "Failed to grab model"
  else
    ents = model.entities
	mats = model.materials
	
	#new material front
	mat_front = mats.add "face-pic"
	
	#add automated file name
	mat_front.texture = address
	
	iterator = list[0].to_i
	
	pts = Array.new
	#UI.messagebox("iterator")
	#UI.messagebox(iterator)
	for i in 1..iterator
	 pts[i-1] = [((list[2*i+f])-(list[2+f])).m, ((list[1+2*i+f])-(list[3+f])).m, h.m]
	end
	#UI.messagebox("Pts is")
	#UI.messagebox(pts)
	puts pts
	
	# Call methods on the Entities collection to draw stuff.
	new_face = ents.add_face pts
		
	#add footprint coordinates in a circular fashion...so that we donot get folded edge type models
	if(new_face.normal==[0,0,-1])
		h_curr_floor = -1*h_in.m
	else
		h_curr_floor = h_in.m
	end
	new_face.pushpull h_curr_floor
	
	#########
	pts1 = Array.new
	print pts1
	pts1[0] = [0.m,0.m,h.m]
	pts1[1] = [(list[4+f]-list[2+f]).m,(list[5+f]-list[3+f]).m,h.m]
	pts1[2] = [(list[4+f]-list[2+f]).m,(list[5+f]-list[3+f]).m,h.m+h_in.m]
	pts1[3] = [0.m,0.m,h.m+h_in.m]
	print pts1
	
	face1 = ents.add_face pts1
	
	pt_array = Array.new
	pt_array[0] = Geom::Point3d.new(0.m,0.m,h.m)
	pt_array[1] = Geom::Point3d.new(0,0,0)
	pt_array[2] = Geom::Point3d.new((list[4+f]-list[2+f]).m,(list[5+f]-list[3+f]).m,h.m)
	pt_array[3] = Geom::Point3d.new(1,0,0)
	pt_array[4] = Geom::Point3d.new((list[4+f]-list[2+f]).m,(list[5+f]-list[3+f]).m,h.m+h_in.m)
	pt_array[5] = Geom::Point3d.new(1,1,0)
	pt_array[6] = Geom::Point3d.new(0.m,0.m,h.m+h_in.m)
	pt_array[7] = Geom::Point3d.new(0,1,0)
		
	on_front = true
	face1.position_material mat_front, pt_array, on_front
	##########
  end
return model
end

#def parameters_file
def parameters_file( h_file,b_file)
	
    list = Array.new
	arr = IO.readlines(h_file,"r")   #reading height.txt
	arr_a = arr[0].split("\t")
	#UI.messagebox("arr_a is")
	#UI.messagebox(arr_a)
	num_floors = arr_a.length - 1
	#UI.messagebox("num_floors")
	#UI.messagebox(num_floors)
	arr_floor = Array.new	
	for i in 1..num_floors
		arr_floor[i-1] = arr_a[i].to_f        ##floor array arr_floor
	end 
	
	arr1 = IO.readlines(b_file,"r")
	arr_b = arr1[0].split("\t")
	arr_build = arr_b.collect{|i| i.to_f}    ##build array
	
	list[0] = arr_build[0]
	list[1] = 0.0
	list[2] = num_floors.to_f
	for i in 1..num_floors
		list[i+2] = arr_floor[i-1]
	end 
    for i in (2+1+list[2]).to_i..((2+1+list[2]).to_i+arr_build.length-1)
		list[i] = arr_build[i-(2+list[2]).to_i]
	end
    return list
end

def enterGeoData(a,b)
 prompts = ["GeoReferenceNorthAngle","Latitude","Longitude"]
 defaults = [0,a,b]
 input = UI.inputbox prompts, defaults, "Enter Location Parameters"
 return input
end


def assignGeoData_shadow(model,l)
 #l = enterGeoData(a,b)
 s = model.shadow_info
 s['NorthAngle']=l[0]
 s['Latitude']=l[2]
 s['Longitude']=l[1]
end

def exportBuilding(model,name)
 options_hash = { :triangulated_faces   => true,
                  :doublesided_faces    => true,
                  :edges                => false,
                  :materials_by_layer   => false,
                  :author_attribution   => false,
                  :texture_maps         => true,
                  :selectionset_only    => false,
                  :preserve_instancing  => true }
 status = model.export name
end


def Sketchup.exit
  # Find the SketchUp main window handle by its window title
  model_path = Sketchup.active_model.path
  if (model_path.empty?)
    model_name = "Untitled"
    # Warning:  This is likely to be language dependent!
    # Need to check Sketchup.os_language
  else
    model_name = File.basename(model_path)
  end
 
  if (Sketchup.app_name == "Google SketchUp Pro")
    sketchup_title = model_name + " - SketchUp Pro"
  else
    sketchup_title = model_name + " - SketchUp"
  end
 
  findWindow = Win32API.new("user32.dll", "FindWindow", ['P','P'], 'N')
  window_id = findWindow.call(0, sketchup_title)
 
  # Send the window a "WM_CLOSE" message (0x0010)
  sendMessage = Win32API.new("user32.dll", "SendMessage", ['N','N','N','P'], 'N')
  sendMessage.call(window_id, 0x0010, 0, "")
end
