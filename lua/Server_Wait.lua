require 'lua.Player'

players = {}

local Server_Wait = Gamestate:addState('Server_Wait')

function Server_Wait:enterState()
   udp = socket.udp()
   udp:settimeout(0)
   udp:setsockname('*', 4444)

   table.insert(players, Player:new(1, '127.0.0.1', 4444))
   if player_name ~= '' then
      players[1].name = player_name
   end

   ui = panel:new(0, 0, 1280, 800)
   ui.name = ""
   ui.color_bg = color(.2,.2,.2)

   p1_panel = panel:new(390, 50, 500, 100)
   p1_panel.name = players[1].name
   p1_panel.color_bg = color(.3,.8,.3)

   p2_panel = panel:new(390, 170, 500, 100)
   p2_panel.name = "Player 2"
   p2_panel.color_bg = color(.5,.4,.3)

   function p2_panel.onupdate(s)
      if players[2] then
	 s.name = players[2].name
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
      if players[3] then
	 s.name = players[3].name
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
      if players[4] then
	 s.name = players[4].name
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
      if players[5] then
	 s.name = players[5].name
	 s.color_bg = color(.3,.8,.3)
      else
	 s.name = "Player 5"
	 s.color_bg = color(.5,.4,.3)
      end
   end

   start_button = panel:new(390, 650, 500, 100)
   start_button.name = "Start"
   start_button.color_bg = color(.2,.4,.4)

   function start_button.onclick(s, x, y, btn)
      if #players > 1 then
	 for i=2,#players do
	    udp:sendto('start '..i, players[i].ip, players[i].port)
	 end

	 self:gotoState('Server')
      else
	 start_button.name = "Not enough players"
      end
   end

   ui:add(p1_panel)
   ui:add(p2_panel)
   ui:add(p3_panel)
   ui:add(p4_panel)
   ui:add(p5_panel)
   ui:add(start_button)

   print("Created Server")

end

function Server_Wait:exitState()
   ui = nil
   player_name = ''
end

dtotal = 0
function Server_Wait:update(dt)
   dtotal = dtotal + dt

   if dtotal >= (1/24) then
      dtotal = dtotal - (1/24)
      ui:update(dt)
   end

   local data, ip, port = udp:receivefrom()
   local cmd
   if data then
      self.ip = ip
      self.port = port
      print("Data: "..data)
      cmd = data:match('(%a+)')
   end
   if cmd == "joining" then
      local name = data:match('%a+ (%a+)')

      table.insert(players, Player:new(#players+1, self.ip, self.port))
      if name ~= nil then
	 players[#players].name = name
      end

      udp:sendto('init '..#players, players[#players].ip, players[#players].port)

      local names = {}
      for i,v in ipairs(players) do
	 names[#names+1] = v.name
      end

      for i=2,#players do
	 udp:sendto('update '..#players..' '..table.concat(names,','), players[i].ip, players[i].port)
      end

      start_button.name = "Start"

   elseif cmd == "leaving" then

      index = data:match('%a+ (%d)')
      table.remove(players, index)

      local names = {}
      for i,v in ipairs(players) do
	 names[#names+1] = v.name
      end

      for i=2,#players do
	 udp:sendto('init '..i, players[i].ip, players[i].port)
	 udp:sendto('update '..#players.. ' '..table.concat(names,','), players[i].ip, players[i].port)
      end

   elseif cmd == "status" then

      udp:sendto('room '..#players, self.ip, self.port)

   end

   socket.sleep(0.01)
end

function Server_Wait:draw()
   ui:draw()
   love.graphics.print('Waiting for connections. '..
		       'Listening on port 4444.', 0, 0)
end

function Server_Wait:mousepressed(x, y, btn)
   ui:click(x, y, btn)
end

function Server_Wait:keypressed(k)
   if k=='escape' then
      for i=2,#players do
	 udp:sendto('exit', players[i].ip, players[i].port)
      end
      print("Server left the game.")
      self:gotoState('Menu')
   end
end