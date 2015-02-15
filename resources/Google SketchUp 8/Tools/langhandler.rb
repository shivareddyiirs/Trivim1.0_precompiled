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

class LanguageHandler

  def initialize(fileName)
    @strings = Hash.new;
    self.ParseLangFile(fileName)
  end

  def ParseLangFile(sub_path)
    full_file_path = Sketchup.get_resource_path(sub_path)

    if full_file_path==nil || full_file_path.length==0
      return false
    end

    langFile = File.open(full_file_path, "r")
    entryString = ""
    inComment = false

    langFile.each do |line|
      #ignore simple comment lines - BIG assumption the whole line is a comment
      if !line.include?("//")
        #also ignore comment blocks
        if line.include?("/*")
          inComment = true
        end

        if inComment==true
          if line.include?("*/")
            inComment=false
          end
        else
          entryString += line
        end
      end

      if entryString.include?(";")
        #parse the string into key and value
        
        #remove the white space
        entryString.strip!

        #pull out the key
        keyvalue = entryString.split("\"=\"")
        
        #strip the leading quotation out
        key = keyvalue[0][(keyvalue[0].index("\"")+1)..(keyvalue[0].length+1)]

        #pull out the value
        keyvalue[1].gsub!(";", "")
        value = keyvalue[1].gsub("\"", "") 

        #add to @strings
        @strings[key]=value

        entryString = ""
      end
    end

    return true
  end

  def GetString(key)
    #puts "GetString key = " + key.to_s
    retval = @strings[key]
    #puts "GetString retval = " + retval.to_s

    if retval!= nil
        retval.chomp!
    else
        retval = key
    end
    return retval
  end

  def GetStrings
    return @strings
  end

  def LanguageHandler::GetResourceSubPath()
    fullPath = Sketchup.get_resource_path("")
    startIndex = fullPath.index("Resources")
    subPath = fullPath[startIndex..fullPath.length]
    #puts "subPath=" + subPath.to_s
    return subPath
  end

end
