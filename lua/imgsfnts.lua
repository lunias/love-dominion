require "lua.utils"

local imgdir = "img/"
imgs = {}
local imgs_mt = {__index = function(s, k)
			      if type(k) ~= 'string' then return nil end
			      local I
			      if love.filesystem.exists(imgdir..k..".png") then
				 I = love.graphics.newImage(imgdir..k..".png")
			      elseif love.filesystem.exists(imgdir..k..".jpg") then
				 I = love.graphics.newImage(imgdir..k..".jpg")
			      else
				 error("could not load image 'img/"..tostring(k)..".(png/jpg)'!")
			      end
			      rawset(s, k, I)
			      return I
			   end
	      }setmetatable(imgs, imgs_mt)

fonts = {}
local fonts_mt = {__index = function(s, k)
			       if type(k) ~= 'number' then return nil end
			       local f = love.graphics.newFont(k)
			       rawset(s, k, f)
			       return f
			    end
	       }setmetatable(fonts, fonts_mt)
