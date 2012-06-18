local Menu = Gamestate:addState('Menu')

player_name = ''

function Menu:enterState()
   if udp then
      udp:close()
   end

   udp = nil
   player = nil
   players = {}
   player_name = ''

   local l_count = 1
   if love.filesystem.exists("settings.dat") then
      for line in love.filesystem.lines("settings.dat") do
	 if l_count == 1 then
	    player_name = line
	    l_count = l_count + 1
	 else
	    self.ip_address = line
	 end
      end
   else
      local settings = love.filesystem.newFile("settings.dat")
      settings:open('w')
      settings:write(" \n")
      settings:write("127.0.0.1")
      self.ip_address = "127.0.0.1"
      settings:close()
   end

   ui = panel:new(0, 0, 1280, 800)
   ui.name = ""
   ui.color_bg = color(.2,.2,.2)

   name_panel = panel:new(395, 300, 490, 50)
   name_panel.name = "Enter Player Name"
   name_panel.color_bg = color(.1,.1,.1)
   name_panel.font = 24

   if player_name ~= '' then
      name_panel.name = ''
   end

   host_button = panel:new(390, 400, 500, 100)
   host_button.name = "Host Game"
   host_button.color_bg = color(.5,.4,.3)
   host_button.font = 24

   function host_button.onclick(s, x, y, btn)
      self:gotoState('Server_Wait')
   end

   join_button = panel:new(390, 550, 500, 100)
   join_button.name = "Join Game"
   join_button.color_bg = color(.5,.4,.3)
   join_button.font = 24

   function join_button.onclick(s, x, y, btn)
      self:gotoState('Type_IP')
   end

   ui:add(name_panel)
   ui:add(host_button)
   ui:add(join_button)
end

function Menu:exitState()
   ui = nil

   if love.filesystem.remove("settings.dat") then
      local settings = love.filesystem.newFile("settings.dat")
      settings:open('w')
      settings:write(player_name.."\n")
      settings:write(self.ip_address)
      settings:close()
   end
end

function Menu:draw()
   ui:draw()
   love.graphics.draw(imgs["logo"], 469, 100, 0, 1, 1)

   love.graphics.print(player_name, 405, 310)
end

function Menu:mousepressed(x, y, btn)
   ui:click(x, y, btn)
end

function Menu:keypressed(k, u)
   if k=='escape' then
      love.event.push('q')
   end

   if k=='backspace' then
      player_name = string.sub(player_name, 1, player_name:len()-1)
      name_panel.name = ""
   elseif (u > 64 and u < 91) or (u > 96 and u < 123) and player_name:len() < 15 then
      player_name = player_name..string.char(u)
      name_panel.name = ""
   end
end