require 'sketchup.rb'
require 'extensions.rb'

# Add a menu item to launch our plugin.
UI.menu("PlugIns").add_item("Generate Buildings from Data_Manual"){
	#show panel for error detection
	UI.messagebox(Dir.pwd())
	drr = Dir.chdir('.\..\..')
	drr = Dir.getwd
	#UI.messagebox("drr is")
	UI.messagebox(drr)
	temp_display_file = File.open(drr+"/bin/3d-modelling/temp_for_display.txt","w")
	#C:\3d-Model\bin\3d-modelling\temp_for_display.txt
	#temp_display_file = File.open("C:\\pSApp\\tempFiles\\temp_for_display.txt","a")
	Sketchup.send_action "showRubyPanel:"
	tempfile = drr+"/bin/3d-modelling/temp.txt"
	base_address = IO.readlines(tempfile)
	Dir.chdir(base_address[0])
	file_txt = Dir["*.txt"]
	if(file_txt.length>2)
		UI.messagebox("Extra files in build folder please check folder")
	end
	if(file_txt.length<2)
		UI.messagebox("Insufficient files in build folder please check folder")
	end
	
	h_file = base_address[0].to_s+"\\heights.txt"
	UI.messagebox("h_file is")
	UI.messagebox(h_file)
	if(file_txt[1]=="heights.txt")
		b_file = base_address[0].to_s+"\\"+file_txt[0].to_s
		UI.messagebox("B-file under if")
		UI.messagebox(b_file)
		i_file = File.basename( file_txt[0], ".*" )
		UI.messagebox("i_file is")
		UI.messagebox(i_file)
	else
		b_file = base_address[0].to_s+"\\"+file_txt[1].to_s
		UI.messagebox("B-file under else")
		UI.messagebox(b_file)
		i_file = File.basename( file_txt[1], ".*" )
		UI.messagebox("i_file is under else")
		UI.messagebox(i_file)
	end
	
	#list = parameters_file
	list = parameters_fileM(h_file,b_file)
	UI.messagebox("list is")
	UI.messagebox(list)
	floors = list[2].to_i
	f = list[2] + 1                     #floor number
	UI.messagebox("floor number is")
	UI.messagebox(f)
	x = list[2+f]
	y = list[3+f]
	ht = 0.0
	UI.messagebox("x is")
	UI.messagebox(x)
	UI.messagebox("y is")
	UI.messagebox(y)
	f = f.to_int
	list1 = [0.0,x,y]
	UI.messagebox("list1 is")
	UI.messagebox(list1)
	# Create a series of "points", each a 3-item array containing x, y, and z. # keep points in any one plane  # and pull along the plane whose coordinate is zero
	iterator = list[0].to_i
	for j in 1..iterator
		temp = [list[2*j+1+f],list[2*j+f]]
		latlong = Geom::LatLong.new(temp)
		list[2*j+f] = latlong.to_utm.x
		list[1+2*j+f] = latlong.to_utm.y
	end
	for j in 1..floors
		pic_address = base_address[0].to_s+"\\"+i_file+".jpg"
		UI.messagebox("pic_address is under for loop")
		UI.messagebox(pic_address)
		if(!File::exist?(pic_address))
			pic_address = base_address[0].to_s+"\\"+i_file+".png"
			UI.messagebox("pic_address is under for loop UNDER IF")
			UI.messagebox(pic_address)
			if(!File::exist?(pic_address))
				pic_address = base_address[0].to_s+"\\"+i_file+".bmp"		### keep file format jpg or png or bmp onllyyy
			end
		end
		UI.messagebox("Parameters before draw model list")
		UI.messagebox(list)
		UI.messagebox(list[2+j])
		UI.messagebox(ht)
		UI.messagebox(f)
		UI.messagebox(pic_address)
		model = drawBuildingM(list,list[2+j],ht,f,pic_address)
		assignGeoData_shadow(model,list1)
		#Dir.chdir(drr+"/bin")
		output_address = IO.readlines(drr+"/bin/curr_proj.txt")[0]+"/output/"
		name = output_address+i_file+'_' + j.to_s + '.kmz'
		#name = 'C:/pSApp/output/'+i_file+'_' + j.to_s + '.kmz'
		exportBuilding(model,name)
		ht = ht + list[2+j]
		Sketchup.active_model.entities.clear!
		Sketchup.active_model.materials.remove "face-pic"
	end
	#temp_display_file.syswrite("done "+i_file+"......\n")
	temp_display_file.puts("\ndone "+i_file+"......")
	UI.messagebox "Finished Model Generation\nExit sketchup without saving anything..."
	
}


def drawBuildingM(list,h_in,h,f,address)  
  
  # Get handles to our model and the Entities collection it contains.
  UI.messagebox("Inside drawBuilding")
  model = Sketchup.active_model
  if (! model)
	UI.messagebox "Failed to grab model"
  else
	UI.messagebox("Inside drawBuilding else")
    ents = model.entities
	mats = model.materials
	
	#new material front
	mat_front = mats.add "face-pic"
	
	#add automated file name
	mat_front.texture = address
	
	iterator = list[0].to_i
	pts = Array.new
	UI.messagebox("iterator is")
	UI.messagebox(iterator)
	for i in 1..iterator
	UI.messagebox("i is")
	UI.messagebox(i)
	UI.messagebox("for loop inside drawBuilding is working")
	 pts[i-1] = [((list[2*i+f])-(list[2+f])).m, ((list[1+2*i+f])-(list[3+f])).m, h.m]
	end
	UI.messagebox("pts is")
	UI.messagebox(pts)
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
def parameters_fileM( h_file,b_file)
	
    UI.messagebox("Inside parameters_file")
	list = Array.new
	UI.messagebox("h_file is")
	UI.messagebox(h_file)
	UI.messagebox("b_file is")
	UI.messagebox(b_file)
	arr = IO.readlines(h_file,"r")
	arr_a = arr[0].split("\t")
	UI.messagebox("arr_a is")
	UI.messagebox(arr_a)
	num_floors = arr_a.length - 1
	UI.messagebox("num_floors")
	UI.messagebox(num_floors)
	arr_floor = Array.new	
	for i in 1..num_floors
		UI.messagebox("for loop inside parameter is working")
		arr_floor[i-1] = arr_a[i].to_f        ##floor array arr_floor
	end 
	UI.messagebox("arr_floor is")
	UI.messagebox(arr_floor)
	arr1 = IO.readlines(b_file,"r")
	UI.messagebox("arr1 is")
	UI.messagebox(arr1)
	arr_b = arr1[0].split("\t")
	UI.messagebox("arr_b")
	UI.messagebox(arr_b)
	arr_build = arr_b.collect{|i| i.to_f}    ##build array
	UI.messagebox("arr_build is")
	UI.messagebox(arr_build)
	list[0] = arr_build[0]
	list[1] = 0.0
	list[2] = num_floors.to_f
	UI.messagebox("list[0]")
	UI.messagebox(list[0])
	UI.messagebox("list[2]")
	UI.messagebox(list[2])
	for i in 1..num_floors
		list[i+2] = arr_floor[i-1]
	end 
    for i in (2+1+list[2]).to_i..((2+1+list[2]).to_i+arr_build.length-1)
		list[i] = arr_build[i-(2+list[2]).to_i]
	end
	UI.messagebox("list is")
	UI.messagebox(list)
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
