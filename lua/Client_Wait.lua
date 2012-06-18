require 'lua.Player'

num_players = 1
player_index = 0
names = {}

local Client_Wait = Gamestate:addState('Client_Wait')

function Client_Wait:enterState()
   udp:send('joining '..player_name, self.ip_address)

   ui = panel:new(0, 0, 1280, 800)
   ui.name = ""
   ui.color_bg = color(.2,.2,.2)

   p1_panel = panel:new(390, 50, 500, 100)
   p1_panel.name = "Player 1"
   p1_panel.color_bg = color(.3,.8,.3)

   function p1_panel.onupdate(s)
      if names[1] then
	 s.name = names[1]
      else
	 s.name = "Player 1"
      end
   end

   p2_panel = panel:new(390, 170, 500, 100)
   p2_panel.name = "Player 2"
   p2_panel.color_bg = color(.5,.4,.3)

   function p2_panel.onupdate(s)
      if names[2] then
	 s.name = names[2]
	 s.color_bg = color(.3,.8,.3)
      else
	 s.name = "Player 2"
	 s.color_bg = color(.5,.4,.3)
      end
   end

   p3_panel = panel:new(390, 290, 500, 100)
   p3_panel.name = "Player 3"
   p3_panel.color_bg = color(.5,.4,.3)

   function p3_panel.onupdate(s)
      if names[3] then
	 s.name = names[3]
	 s.color_bg = color(.3,.8,.3)
      else
	 s.name = "Player 3"
	 s.color_bg = color(.5,.4,.3)
      end
   end

   p4_panel = panel:new(390, 410, 500, 100)
   p4_panel.name = "Player 4"
   p4_panel.color_bg = color(.5,.4,.3)

   function p4_panel.onupdate(s)
      if names[4] then
	 s.name = names[4]
	 s.color_bg = color(.3,.8,.3)
      else
	 s.name = "Player 4"
	 s.color_bg = color(.5,.4,.3)
      end
   end

   p5_panel = panel:new(390, 530, 500, 100)
   p5_panel.name = "Player 5"
   p5_panel.color_bg = color(.5,.4,.3)

   function p5_panel.onupdate(s)
      if names[5] then
	 s.name = names[5]
	 s.color_bg = color(.3,.8,.3)
      else
	 s.name = "Player 5"
	 s.color_bg = color(.5,.4,.3)
      end
   end

   ui:add(p1_panel)
   ui:add(p2_panel)
   ui:add(p3_panel)
   ui:add(p4_panel)
   ui:add(p5_panel)

   print("Created Client")
end

function Client_Wait:exitState()
   ui = nil
   player_name = ''
end

function Client_Wait:update(dt)
   ui:update(dt)
   local data = udp:receive()
   local cmd
   if data then
      cmd = data:match('(%a+)')
   end

   if cmd == 'init' then

      player_index = tonumber(data:match('%a+ (%d)'))

   end
   if cmd == 'update' then

      num_players = tonumber(data:match('%a+ (%d)'))

      names = {}
      for i in string.gmatch(data:match('%a+ %d ([%a%p%s%d]+)'), "[^,]+") do
	 names[#names+1] = i
      end

   end
   if cmd == 'start' then

      self:gotoState('Client')

   end
   if cmd == 'exit' then

      print("Client kicked out")
      self:gotoState('Menu')

   end

   socket.sleep(0.01)
end

function Client_Wait:draw()
   love.graphics.reset()
   love.graphics.setColorMode('replace')

   ui:draw()

   love.graphics.print('Waiting for players. ', 0, 0)
end

function Client_Wait:keypressed(k, u)
   if k=='escape' then
      udp:send('leaving '..player_index, self.ip_address)
      print("Client left the game.")
      self:gotoState('Menu')
   end
end