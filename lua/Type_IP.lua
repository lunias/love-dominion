local connected = false

local Type_IP = Gamestate:addState('Type_IP')

function Type_IP:enterState()
   connected = false

   --self.ip_address = '68.2.86.236'
   --self.ip_address = '127.0.0.1'
   love.keyboard.setKeyRepeat(500, 50)

   ui = panel:new(0, 0, 1280, 800)
   ui.name = ""
   ui.color_bg = color(.2,.2,.2)

   ip_panel = panel:new(390, 400, 500, 250)
   ip_panel.name = ""
   ip_panel.color_bg = color(.5,.4,.3)
   ip_panel.font = 24

   text_panel = panel:new(395, 500, 490, 50)
   text_panel.name = ""
   text_panel.color_bg = color(.1,.1,.1)
   text_panel.font = 24

   ui:add(ip_panel)
   ui:add(text_panel)
end

function Type_IP:exitState()
   love.keyboard.setKeyRepeat(0, 0)
   ui = nil

   if love.filesystem.remove("settings.dat") then
      local settings = love.filesystem.newFile("settings.dat")
      settings:open('w')
      settings:write(player_name.."\n")
      settings:write(self.ip_address)
      settings:close()
   end
end

function Type_IP:update(dt)
   if connected then
      local data = udp:receive()
      local cmd
      if data then
	 cmd = data:match('(%a+)')
	 print(data)
      end
      if cmd == 'room' then

	 players = tonumber(data:match('%a+ (%d)'))
	 if players < 5 then
	    self:gotoState('Client_Wait')
	 else
	    self:gotoState('Menu')
	 end

      end
   end

   socket.sleep(0.01)
end

function Type_IP:draw()
   love.graphics.reset()
   love.graphics.setColorMode('replace')

   ui:draw()
   love.graphics.draw(imgs["logo"], 469, 100, 0, 1, 1)

   love.graphics.print('Type in the the server\'s IP address:', 395, 402)
   love.graphics.print(self.ip_address, 400, 510)
end


function Type_IP:keypressed(k, u)
   if k=='backspace' then
      self.ip_address = string.sub(self.ip_address, 1, self.ip_address:len()-1)
   elseif (u>=48 and u<=57) or --0-9
   u==46 or u==58 then --. :
      self.ip_address = self.ip_address..string.char(u)
   end

   if k=='return' or k=='kpenter' then
      udp = socket.udp()
      udp:settimeout(0)
      udp:setpeername(self.ip_address, 4444)
      connected = true
      udp:send('status', self.ip_address)
   elseif k=='escape' then
      self:gotoState('Menu')
   end
end