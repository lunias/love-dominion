require 'lua.Panel'
require 'lua.Player'
require 'lua.Cards'

local game_over = false
local game_end = false
active_player = 1
local player
play_area = {}
play_area_info = {}
supply1 = {}
supply2 = {}
supply1_counts = {}
supply2_counts = {}
local last_bought = {}
revealed = {}
wait_count = 0
choosing = false
waiting = false
players_reacting = 0
already_played = false
gaining = false
gain_type = 'any'
gain_type2 = 'any'
gain = 0
local sound = false

local Client = Gamestate:addState('Client')

function Client:enterState()
   local tmp

   local found = 0

   --CREATE PLAYER
   player = Player:new(player_index, '127.0.0.1', '4444')
   player:start()

   --SETUP SUPPLY
   supply2[1] = cards:newcard(cards.set["Copper"])
   supply2_counts[1] = 60
   supply2[2] = cards:newcard(cards.set["Silver"])
   supply2_counts[2] = 40
   supply2[3] = cards:newcard(cards.set["Gold"])
   supply2_counts[3] = 30
   supply2[4] = cards:newcard(cards.set["Potion"])
   supply2_counts[4] = 16
   supply2[5] = cards:newcard(cards.set["Estate"])
   if num_players > 2 then
      supply2_counts[5] = 12
   else
      supply2_counts[5] = 8
   end
   supply2[6] = cards:newcard(cards.set["Duchy"])
   if num_players > 2 then
      supply2_counts[6] = 12
   else
      supply2_counts[6] = 8
   end
   supply2[7] = cards:newcard(cards.set["Province"])
   if num_players == 2 then
      supply2_counts[7] = 8
   elseif num_players > 4 then
      supply2_counts[7] = 15
   else
      supply2_counts[7] = 12
   end
   supply2[8] = cards:newcard(cards.set["Curse"])
   if num_players == 2 then
      supply2_counts[8] = 10
   elseif num_players == 3 then
      supply2_counts[8] = 20
   elseif num_players == 4 then
      supply2_counts[8] = 30
   else
      supply2_counts[8] = 40
   end

   supply1_counts[1] = 10
   supply1_counts[2] = 10
   supply1_counts[3] = 10
   supply1_counts[4] = 10
   supply1_counts[5] = 10
   supply1_counts[6] = 10
   supply1_counts[7] = 10
   supply1_counts[8] = 10
   supply1_counts[9] = 10
   supply1_counts[10] = 10

   --INIT UI
   ui = panel:new(0, 0, 1280, 800)
   ui.name = ""
   ui.color_bg = color(.2,.2,.2)

   --PASS PANEL
   pass_panel = panel:new(0, 600, 100, 200)
   pass_panel.name = "End Turn"
   pass_panel.color_bg = color(.2,.6,.5)

   function pass_panel.onupdate(s)
      if active_player == player_index then
	 s.color_bg = color(.2,.6,.5)
      else
	 s.color_bg = color(.6,.2,.5)
      end
   end

   function pass_panel.onclick(s, x, y, btn)
      if active_player == player_index and not choosing and not waiting then

	 --END OF TURN CARDS
	 table.sort(player.played, function(a,b) return a.name<b.name end)

	 for i,v in ipairs(player.played) do
	    if v.name == "Herbalist" then
	       v:onend(player, i)
	       break
	    elseif v.name == "Alchemist" then
	       v:onend(player, i)
	       break
	    elseif v.name == "Treasury" then
	       v:onend(player, i)
	       break
	    elseif v.name == "Walled Village" then
	       v:onend(player, i)
	       break
	    end
	 end

	 if not choosing then
	    player.outpost_block = false

	    for i=#player.hand, 1, -1 do
	       player:discard(i)
	    end

	    for i=#player.played, 1, -1 do
	       player.discard_pile[#player.discard_pile+1] = table.remove(player.played, i)
	    end

	    if not player.outpost then
	       player:drawcard(5)
	    else
	       player.outpost_block = true
	       player:drawcard(3)
	    end

	    player.coins = 0
	    player.potions = 0
	    player.buys = 1
	    player.actions = 1
	    player.action_count = 0
	    player.victory_count = 0
	    player.coppersmith = 0
	    player.crossroads = false

	    play_area = {}
	    play_area_info = {}
	    last_bought = {}


	    gain = 0
	    gaining = false

	    if not player.outpost then
	       udp:send('cleanup', self.ip_address)
	    else
	       udp:send('cleanup outpost', self.ip_address)
	    end
	 end
      end
   end

   --HAND PANEL
   hand_panel = panel:new(100, 600, 1180, 200)
   hand_panel.name = ""
   hand_panel.color_bg = color(.0,.6,.3)

   for i=0,7 do
      tmp = panel:new(i*120+10, 10, 120, 185)
      tmp.name = "Card#"..i+1
      tmp.align = 'center'
      function tmp:card() return player.hand[i+1], i+1 end

      function tmp.ondraw(s)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.draw(img, 0, 0, 0, .4, .4)
	 end
      end

      function tmp.onclick(s, x, y, btn)
	 if s:card() and active_player == player_index and not choosing and not waiting then
	    local c, i = s:card()
	    if btn == 'l' and c.type ~= 'victory' then
	       if player.actions > 0 or c.type == 'treasure' or c.type == 'tv' then

		  udp:send('played '..c.image..",".."P", self.ip_address)

		  if c.type == 'action' or c.type == 'attack' or c.type == 'reaction' or c.type == 'av' then
		     player.actions = player.actions - 1
		     player.action_count = player.action_count + 1
		  end

		  if c.type == 'treasure' or c.type == 'tv' then
		     player.actions = 0
		  end
		  player:play(c, i)
	       end
	    end
	 end
      end

      function tmp.magnify(s, x, y)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.draw(img, x, y-380, 0, .8, .8)
	 end
      end

      hand_panel:add(tmp)
   end

   --HAND SCROLL PANEL
   scroll_panel = panel:new(1085, 675, 50, 50)
   scroll_panel.name = "<"
   scroll_panel.color_bg = color(.3,.3,.3,.5)

   function scroll_panel.onupdate(s)
      if #player.hand > 7 then
	 s.color_txt = color(.9,.1,.1)
	 s.name = #player.hand - 7
      else
	 s.name = "<"
	 s.color_txt = color(.9,.9,.9)
      end
   end

   function scroll_panel.onclick(s, x, y, btn)
      player.hand[#player.hand] = table.remove(player.hand, 1)
   end

   --DECK PANEL
   deck_panel = panel:new(1145, 610, 120, 185)
   deck_panel.name = ""

   function deck_panel.ondraw(s)
      love.graphics.draw(imgs["back"], 0, 0, 0, .4, .4)
      love.graphics.setColorMode('modulate')
      love.graphics.setColor(color(.1,.2,.2, .8))
      love.graphics.rectangle('fill', 0, 45, 117, 30)
      love.graphics.rectangle('fill', 0, 105, 117, 30)
      love.graphics.setColor(color(.9,.9,.0))
      love.graphics.setFont(fonts[32])
      love.graphics.printf(#player.deck, 0, 42, 125, 'center')
      love.graphics.setColor(color(.9,.0,.0))
      love.graphics.printf(#player.discard_pile, 0, 102, 125, 'center')
      love.graphics.setColorMode('replace')
   end

   function deck_panel.onclick(s, x, y, btn)
      if btn == 'l' and game_over then
	 player:drawcard(1)
      end
   end

   --INFO BAR
   --PLAYER
   player_panel = panel:new(50, 570, 156, 30)
   player_panel.name = names[player_index]
   player_panel.color_bg = color(.8,.2,.2)

   --COINS
   coins_panel = panel:new(306, 570, 156, 30)
   coins_panel.name = "Coins: "..player.coins
   coins_panel.color_bg = color(.6,.4,.0)

   function coins_panel.onupdate(s)
      s.name = "Coins: "..player.coins
   end

   function coins_panel.onclick(s, x, y, btn)
      if btn == 'l' and active_player == player_index and not choosing and not waiting then
	 player.actions = 0
	 for i=#player.hand, 1, -1 do
	    if player.hand[i].type == 'treasure' or player.hand[i].type == 'tv' then

	       udp:send('played '..player.hand[i].image..",".."P", self.ip_address)

	       player:play(player.hand[i], i)
	    end
	 end
      end
   end

   --POTIONS
   potions_panel = panel:new(562, 570, 156, 30)
   potions_panel.name = "Potions: "..player.potions
   potions_panel.color_bg = color(.3,.2,.3)

   function potions_panel.onupdate(s)
      s.name = "Potions: "..player.potions
   end

   --ACTIONS
   actions_panel = panel:new(818, 570, 156, 30)
   actions_panel.name = "Actions: "..player.actions
   actions_panel.color_bg = color(.3,.2,.6)

   function actions_panel.onupdate(s)
      s.name = "Actions: "..player.actions
   end

   --BUYS
   buys_panel = panel:new(1074, 570, 156, 30)
   buys_panel.name = "Buys: "..player.buys
   buys_panel.color_bg = color(.2,.5,.5)

   function buys_panel.onupdate(s)
      s.name = "Buys: "..player.buys
   end

   --SUPPLY PANEL
   supply_panel1 = panel:new(0, 420, 1280, 150)
   supply_panel1.name = ""
   supply_panel1.color_bg = color(.3,.2,.2)

   for i=0,10 do
      tmp = panel:new(i*100+20, 5, 90, 140)
      tmp.name = "Supply 1 Card#"..i+1
      tmp.align = 'center'
      function tmp:card() return supply1[i+1], i+1 end

      function tmp.ondraw(s)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.setColorMode('modulate')
	    if not gaining then
	       if player.coins < s:card().cost.gold or player.potions < s:card().cost.potion or player.buys == 0 or active_player ~= player_index or supply1_counts[i+1] == 0 then
		  love.graphics.setColor(color(.4,.4,.4))
	       else
		  love.graphics.setColor(color(1,1,1))
	       end
	    else
	       if (gain_type ~= 'any' and (gain_type ~= s:card().type and gain_type2 ~= s:card().type)) or gain < s:card().cost.gold or s:card().cost.potion > 0 or active_player ~= player_index or supply1_counts[i+1] == 0 then
		  love.graphics.setColor(color(.4,.4,.4))
	       else
		  love.graphics.setColor(color(1,1,1))
	       end
	    end
	    love.graphics.draw(img, 0, 0, 0, .3, .3)
	    love.graphics.setColor(color(.9,.9,.0))
	    love.graphics.setFont(fonts[24])
	    love.graphics.printf(supply1_counts[i+1], 0, 65, 93, 'center')
	    love.graphics.setColorMode('replace')
	 end
      end

      function tmp.onclick(s, x, y, btn)
	 if s:card() and active_player == player_index and not choosing and not waiting then
	    local c, i = s:card()
	    if btn == 'l' then
	       if not gaining then
		  if supply1_counts[i] ~= 0 and player.coins >= c.cost.gold and player.potions >= c.cost.potion and player.buys > 0 then
		     love.audio.play(buy_sound)
		     player.discard_pile[#player.discard_pile+1] = c
		     player.buys = player.buys - 1
		     player.coins = player.coins - c.cost.gold
		     player.potions = player.potions - c.cost.potion
		     player.actions = 0

		     if c.type == 'victory' or c.type == 'av' or c.type == 'tv' then
			player.victory_count = player.victory_count + 1
		     end

		     udp:send('boughtone '..i, self.ip_address)
		     udp:send('lastbought '..c.name, self.ip_address)
		     udp:send('played '..c.image..",".."B", self.ip_address)
		  end
	       else
		  if supply1_counts[i] ~= 0 and (gain_type == 'any' or gain_type == c.type or gain_type2 == c.type) and gain >= c.cost.gold and c.cost.potion == 0 then
		     love.audio.play(buy_sound)
		     player.discard_pile[#player.discard_pile+1] = c

		     if player.last_played.name == "Ironworks" then
			if c.type == 'treasure' or c.type == 'tv' then
			   player.coins = player.coins + 1
			end
			if c.type == 'action' or c.type == 'av' then
			   player.actions = player.actions + 1
			end
			if c.type == 'victory' or c.type == 'av' then
			   player:drawcard()
			end
		     end

		     udp:send('boughtone '..i, self.ip_address)
		     udp:send('lastbought '..c.name, self.ip_address)

		     udp:send('played '..c.image..",".."G", self.ip_address)

		     gain = 0
		     gain_type = 'any'
		     gain_type2 = 'any'
		     gaining = false
		  end
	       end
	    end
	 end
      end

      function tmp.magnify(s, x, y)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.draw(img, x, y-380, 0, .8, .8)
	 end
      end

      supply_panel1:add(tmp)
   end

   supply_panel2 = panel:new(0, 270, 1280, 150)
   supply_panel2.name = ""
   supply_panel2.color_bg = color(.3,.4,.3)

   for i=0,8 do
      tmp = panel:new(i*100+20, 5, 90, 140)
      tmp.name = "Supply 2 Card#"..i+1
      tmp.align = 'center'
      function tmp:card() return supply2[i+1], i+1 end

      function tmp.ondraw(s)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.setColorMode('modulate')
	    if not gaining then
	       if player.coins < s:card().cost.gold or player.buys == 0 or active_player ~= player_index or supply2_counts[i+1] == 0 then
		  love.graphics.setColor(color(.4,.4,.4))
	       else
		  love.graphics.setColor(color(1,1,1))
	       end
	    else
	       if (gain_type ~= 'any' and (gain_type ~= s:card().type and gain_type2 ~= s:card().type)) or gain < s:card().cost.gold or active_player ~= player_index or supply2_counts[i+1] == 0 then
		  love.graphics.setColor(color(.4,.4,.4))
	       else
		  love.graphics.setColor(color(1,1,1))
	       end
	    end
	    love.graphics.draw(img, 0, 0, 0, .3, .3)
	    love.graphics.setColor(color(.9,.9,.0))
	    love.graphics.setFont(fonts[24])
	    love.graphics.printf(supply2_counts[i+1], 0, 65, 93, 'center')
	    love.graphics.setColorMode('replace')
	 end
      end

      function tmp.onclick(s, x, y, btn)
	 if s:card() and active_player == player_index and not choosing and not waiting then
	    local c, i = s:card()
	    if btn == 'l' then
	       if not gaining then
		  if supply2_counts[i] ~= 0 and player.coins >= c.cost.gold and player.potions >= c.cost.potion and player.buys > 0 then
		     love.audio.play(buy_sound)
		     player.discard_pile[#player.discard_pile+1] = c
		     player.buys = player.buys - 1
		     player.coins = player.coins - c.cost.gold
		     player.actions = 0

		     if c.type == 'victory' or c.type == 'av' or c.type == 'tv' then
			player.victory_count = player.victory_count + 1
		     end

		     udp:send('boughtdos '..i, self.ip_address)
		     udp:send('lastbought '..c.name, self.ip_address)

		     udp:send('played '..c.image..",".."B", self.ip_address)
		  end
	       else
		  if supply2_counts[i] ~= 0 and (gain_type == 'any' or gain_type == c.type or gain_type2 == c.type) and gain >= c.cost.gold then
		     love.audio.play(buy_sound)
		     if player.last_played.name == "Mine" then
			player.hand[#player.hand+1] = c
		     else
			player.discard_pile[#player.discard_pile+1] = c
		     end


		     if player.last_played.name == "Ironworks" then
			if c.type == 'treasure' or c.type == 'tv' then
			   player.coins = player.coins + 1
			end
			if c.type == 'action' or c.type == 'av' then
			   player.actions = player.actions + 1
			end
			if c.type == 'victory' or c.type == 'av' then
			   player:drawcard()
			end
		     end

		     udp:send('boughtdos '..i, self.ip_address)
		     udp:send('lastbought '..c.name, self.ip_address)

		     udp:send('played '..c.image..",".."G", self.ip_address)

		     gain = 0
		     gain_type = 'any'
		     gain_type2 = 'any'
		     gaining = false
		  end
	       end
	    end
	 end
      end

      function tmp.magnify(s, x, y)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.draw(img, x, y, 0, .8, .8)
	 end
      end

      supply_panel2:add(tmp)
   end

   --TRASH PANEL
   trash_panel = panel:new(821, 275, 88, 140)
   trash_panel.name = "Trash"
   trash_panel.bg_color = color(.5,.4,.3)

   function trash_panel.onclick(s, x, y, btn)
      if btn == 'l' then
	 print("Clicked on trash. "..#player.trash)
      end
   end

   --PLAYED PANEL
   played_panel = panel:new(0, 0, 1280, 270)
   played_panel.name = ""
   played_panel.color_bg = color(.2,.3,.3)

   for i=0,12 do
      for j=0,1 do
	 tmp = panel:new(i*90+20, j*124+16, 75, 120)
	 tmp.name = "Played Card#"..(i+1)+(j*13)
	 tmp.align = 'center'
	 function tmp:card() return play_area[(i+1)+(j*13)], (i+1)+(j*13) end

	 function tmp.ondraw(s)
	    if s:card() and play_area_info[(i+1)+(j*12)] then
	       local img = imgs[s:card()]
	       love.graphics.draw(img, 0, 0, 0, .25, .25)

	       love.graphics.setColorMode('modulate')
	       love.graphics.setColor(color(.1,.2,.2, .8))
	       love.graphics.rectangle('fill', 0, 35, 88, 30)
	       love.graphics.setColor(color(.9,.9,.0))
	       love.graphics.setFont(fonts[24])
	       love.graphics.printf(play_area_info[(i+1)+(j*12)], 0, 38, 85, 'center')
	       love.graphics.setColorMode('replace')
	    end
	 end

	 function tmp.onclick(s, x, y, btn)
	    if s:card() then
	       local c, i = s:card()
	       if btn == 'l' then

	       end
	    end
	 end

	 function tmp.magnify(s, x, y)
	    if s:card() then
	       local img = imgs[s:card()]
	       if x > 1000 then
		  love.graphics.draw(img, x-235, y, 0, .8, .8)
	       else
		  love.graphics.draw(img, x, y, 0, .8, .8)
	       end
	    end
	 end

	 played_panel:add(tmp)
      end
   end

   ui:add(pass_panel)
   ui:add(hand_panel)
   ui:add(scroll_panel)
   ui:add(deck_panel)

   ui:add(player_panel)
   ui:add(coins_panel)
   ui:add(potions_panel)
   ui:add(actions_panel)
   ui:add(buys_panel)

   ui:add(supply_panel1)
   ui:add(supply_panel2)
   ui:add(trash_panel)
   ui:add(played_panel)

end

function Client:exitState()
   ui = nil

   game_over = false
   active_player = 1
   play_area = {}
   play_area_info = {}
   supply1 = {}
   supply2 = {}
   supply1_counts = {}
   supply2_counts = {}
   last_bought = {}
   revealed = {}
   choosing = false
   waiting = false
   already_played = false
   gaining = false
   gain_type = 'any'
   gain_type2 = 'any'
   gain = 0
   names = {}
   sound = false
end

dtotal = 0
function Client:update(dt)
   dtotal = dtotal + dt

   if dtotal >= (1/10) then
      dtotal = dtotal - (1/10)
      ui:update(dt)
   end

   if active_player ~= player_index and choosing and not sound then
      sound = true
      love.audio.play(attack_sound)
   end

   if not choosing then
      sound = false
   end

   local data, msg = udp:receive()
   local cmd
   if data then
      cmd = data:match('(%a+)')
   end

   local to_draw
   if cmd == "draw" then
      to_draw = tonumber(data:match('%a+ (%d+)'))
      player:drawcard(to_draw)
   end

   if cmd == "discardtop" then
      player.discard_pile[#player.discard_pile+1] = table.remove(player.deck, #player.deck)
   end

   if cmd == "canreact" then
      if player:can_react() then
	 udp:send('reacting', self.ip_address)
	 player:react()
      else
	 udp:send('donechoosing', self.ip_address)
      end
   end

   if cmd == "reactingcount" then
      num = tonumber(data:match('%a+ (%d+)'))
      players_reacting = num
   end

   if cmd == 'witch' then
      udp:send('boughtdos '..8, self.ip_address)
      player.discard_pile[#player.discard_pile+1] = supply2[8]
   end

   if cmd == 'minion' then
      if #player.hand > 4 then
	 for i=#player.hand, 1, -1 do
	    player:discard(i)
	 end
	 player:drawcard(4)
      end
   end

   if cmd == 'cutpurse' then
      for i,v in ipairs(player.hand) do
	 if v.name == 'Copper' then
	    player.discard_pile[#player.discard_pile+1] = table.remove(player.hand, i)
	    return
	 end
      end
   end

   if cmd == 'played' then
      for i in string.gmatch(data:match('%a+ ([%a%p%s%d]+)'), "[^,]+") do
	 if #i == 1 then
	    play_area_info[#play_area_info+1] = i
	 else
	    play_area[#play_area+1] = i
	 end
      end
   end

   if cmd == 'boughtone' then
      index = tonumber(data:match('%a+ (%d+)'))
      supply1_counts[index] = supply1_counts[index] - 1
   end

   if cmd == 'boughtdos' then
      index = tonumber(data:match('%a+ (%d+)'))
      supply2_counts[index] = supply2_counts[index] - 1
   end

   if cmd == 'lastbought' then
      local card = data:match('%a+ ([%a%s]+)')
      last_bought[#last_bought+1] = card
   end

   if cmd == 'torturer' then

      choosing = true

      choice_panel = panel:new(333, 50, 615, 500)
      choice_panel.name = ""
      choice_panel.color_bg = color(.2,.2,.2)

      title_panel = panel:new(0, 0, 615, 30)
      title_panel.name = "Choose"
      title_panel.color_bg = color(.4,.4,.4)

      card_panel = panel:new(30, 60, 240, 380)
      card_panel.name = ""
      card_panel.align = 'center'

      function card_panel.ondraw(s)
	 local img = imgs['torturer']
	 love.graphics.draw(img, 0, 0, 0, .8, .8)
      end

      c1_panel = panel:new(285, 66, 300, 40)
      c1_panel.name = "Discard 2 Cards"

      function c1_panel.onclick(s, x, y, btn)
	 if btn == 'l' then
	    ui:remove(choice_panel)

	    choice_panel = panel:new(140, 50, 1000, 500)
	    choice_panel.name = ""
	    choice_panel.color_bg = color(.2,.2,.2)

	    title_panel = panel:new(0, 0, 1000, 30)
	    title_panel.name = "Discard 2"
	    title_panel.color_bg = color(.4,.4,.4)

	    card_panel = panel:new(30, 60, 240, 380)
	    card_panel.name = ""
	    card_panel.align = 'center'

	    function card_panel.ondraw(s)
	       local img = imgs['torturer']
	       love.graphics.draw(img, 0, 0, 0, .8, .8)
	    end

	    local tmp
	    local discard_count = 0

	    for i=0,6 do
	       for j=0,2 do
		  tmp = panel:new(i*90+285, j*124+66, 75, 120)
		  tmp.name = "Choice Card#"..(i+1)+(j*7)
		  tmp.align = 'center'
		  function tmp:card() return player.hand[(i+1)+(j*7)], (i+1)+(j*7) end

		  function tmp.ondraw(s)
		     if s:card() then
			local img = imgs[s:card().image]
			love.graphics.draw(img, 0, 0, 0, .25, .25)
		     end
		  end

		  function tmp.onclick(s, x, y, btn)
		     if s:card() then
			local c, i = s:card()
			if btn == 'l' then
			   if discard_count < 2 then
			      player:discard(i)
			      discard_count = discard_count + 1
			   end
			end
		     end
		  end

		  function tmp.magnify(s, x, y)
		     if s:card() then
			local img = imgs[s:card().image]
			if x > 1000 then
			   love.graphics.draw(img, x-235, y, 0, .8, .8)
			else
			   love.graphics.draw(img, x, y, 0, .8, .8)
			end
		     end
		  end

		  choice_panel:add(tmp)
	       end
	    end


	    done_panel = panel:new(450, 440, 100, 40)
	    done_panel.name = "Done ("..discard_count..")"
	    done_panel.color_bg = color(.8,.2,.2)

	    function done_panel.onupdate(s)
	       done_panel.name = "Done ("..discard_count..")"
	       if discard_count == 2 or #player.hand == 0 then
		  done_panel.color_bg = color(.0,.6,.3)
	       end
	    end

	    function done_panel.onclick(s, x, y, btn)
	       if discard_count == 2 or #player.hand == 0 then
		  udp:send('donechoosing', self.ip_address)
		  ui:remove(choice_panel)
		  choosing = false
	       end
	    end

	    choice_panel:add(title_panel)
	    choice_panel:add(card_panel)
	    choice_panel:add(done_panel)
	    ui:add(choice_panel)
	 end
      end

      c2_panel = panel:new(285, 126, 300, 40)
      c2_panel.name = "Gain a Curse"

      function c2_panel.onclick(s, x, y, btn)
	 if btn == 'l' then
	    if supply2_counts[8] > 0 then
	       udp:send('boughtdos '..8, self.ip_address)
	       player.hand[#player.hand+1] = supply2[8]

	       udp:send('donechoosing', self.ip_address)
	       ui:remove(choice_panel)
	       choosing = false
	    end
	 end
      end

      choice_panel:add(c1_panel)
      choice_panel:add(c2_panel)
      choice_panel:add(title_panel)
      choice_panel:add(card_panel)
      ui:add(choice_panel)
   end

   if cmd == 'bureaucrat' then
      choosing = true

      choice_panel = panel:new(140, 50, 1000, 500)
      choice_panel.name = ""
      choice_panel.color_bg = color(.2,.2,.2)

      title_panel = panel:new(0, 0, 1000, 30)
      title_panel.name = "Choose"
      title_panel.color_bg = color(.4,.4,.4)

      card_panel = panel:new(30, 60, 240, 380)
      card_panel.name = ""
      card_panel.align = 'center'

      function card_panel.ondraw(s)
	 local img = imgs['bureaucrat']
	 love.graphics.draw(img, 0, 0, 0, .8, .8)
      end

      choices = {}
      for i,v in ipairs(player.hand) do
	 if v.type == 'victory' or v.type == 'av' or v.type == 'tv' then
	    choices[#choices+1] = {card = v, hand_index = i}
	 end
      end

      local tmp
      if next(choices) ~= nil then
	 for i=0,6 do
	    for j=0,2 do
	       tmp = panel:new(i*90+285, j*124+66, 75, 120)
	       tmp.name = "Choice Card#"..(i+1)+(j*7)
	       tmp.align = 'center'
	       function tmp:card()
		  if choices[(i+1)+(j*7)] then
		     return choices[(i+1)+(j*7)].card, choices[(i+1)+(j*7)].hand_index
		  else
		     return nil
		  end
	       end

	       function tmp.ondraw(s)
		  if s:card() then
		     local img = imgs[s:card().image]
		     love.graphics.draw(img, 0, 0, 0, .25, .25)
		  end
	       end

	       function tmp.onclick(s, x, y, btn)
		  if s:card() then
		     local c, i = s:card()
		     if btn == 'l' then
			ui:remove(choice_panel)
			player.deck[#player.deck+1] = table.remove(player.hand, i)
			udp:send('played '..c.image..",".."R", self.ip_address)
			udp:send('donechoosing', self.ip_address)
			choosing = false
		     end
		  end
	       end

	       function tmp.magnify(s, x, y)
		  if s:card() then
		     local img = imgs[s:card().image]
		     if x > 1000 then
			love.graphics.draw(img, x-235, y, 0, .8, .8)
		     else
			love.graphics.draw(img, x, y, 0, .8, .8)
		     end
		  end
	       end
	       choice_panel:add(tmp)
	    end
	 end
      else
	 tmp = panel:new(305, 225, 150, 50)
	 tmp.name = "No Options"
	 tmp.color_bg = color(.8,.2,.2)

	 function tmp.onclick(s, x, y, btn)
	    ui:remove(choice_panel)
	    udp:send('donechoosing', self.ip_address)
	    choosing = false
	 end
	 choice_panel:add(tmp)
      end

      choice_panel:add(title_panel)
      choice_panel:add(card_panel)
      ui:add(choice_panel)
   end

   if cmd == 'reveal' then
      local card = data:match('%a+ (%a+)')
      local index = data:match('%a+ %a+ (%d)')

      if active_player == player.id then
	 revealed[index] = card
	 self:donespying()
      end
   end

   if cmd == 'tributecards' then

   end

   if cmd == 'spy' then
      local card = player:revealtop()
      if card then
	 if player.id ~= active_player then
	    udp:send('reveal '..card.image..' '..player.id, self.ip_address)
	 else
	    revealed[player.id] = card.image
	    self:donespying()
	 end
	 udp:send('played '..card.image..","..player.id, self.ip_address)
      else
	 if player.id ~= active_player then
	    udp:send('reveal back '..player.id, self.ip_address)
	 else
	    revealed[player.id] = 'back'
	    self:donespying()
	 end
      end
   end

   if cmd == 'militia' then
      choosing = true

      local discard_count = 0
      local discard_target = #player.hand - 3

      if discard_target < 1 then
	 udp:send('donechoosing', self.ip_address)
	 choosing = false
	 return
      end

      choice_panel = panel:new(140, 50, 1000, 500)
      choice_panel.name = ""
      choice_panel.color_bg = color(.2,.2,.2)

      title_panel = panel:new(0, 0, 1000, 30)
      title_panel.name = "Discard"
      title_panel.color_bg = color(.4,.4,.4)

      card_panel = panel:new(30, 60, 240, 380)
      card_panel.name = ""
      card_panel.align = 'center'

      function card_panel.ondraw(s)
	 local img = imgs['militia']
	 love.graphics.draw(img, 0, 0, 0, .8, .8)
      end

      local tmp
      if #player.hand > 0 then
	 for i=0,6 do
	    for j=0,2 do
	       tmp = panel:new(i*90+285, j*124+66, 75, 120)
	       tmp.name = "Choice Card#"..(i+1)+(j*7)
	       tmp.align = 'center'
	       function tmp:card() return player.hand[(i+1)+(j*7)], (i+1)+(j*7) end

	       function tmp.ondraw(s)
		  if s:card() then
		     local img = imgs[s:card().image]
		     love.graphics.draw(img, 0, 0, 0, .25, .25)
		  end
	       end

	       function tmp.onclick(s, x, y, btn)
		  if s:card() then
		     local c, i = s:card()
		     if btn == 'l' then
			if discard_count < discard_target then
			   player:discard(i)
			   discard_count = discard_count + 1
			end
		     end
		  end
	       end

	       function tmp.magnify(s, x, y)
		  if s:card() then
		     local img = imgs[s:card().image]
		     if x > 1000 then
			love.graphics.draw(img, x-235, y, 0, .8, .8)
		     else
			love.graphics.draw(img, x, y, 0, .8, .8)
		     end
		  end
	       end
	       choice_panel:add(tmp)
	    end
	 end
      end

      done_panel = panel:new(450, 440, 100, 40)
      done_panel.name = "Done"
      done_panel.color_bg = color(.8,.8,.2)

      function done_panel.onclick(s, x, y, btn)
	 if discard_count == discard_target then
	    ui:remove(choice_panel)
	    udp:send('donechoosing', self.ip_address)
	    choosing = false
	 end
      end

      function done_panel.onupdate(s)
	 if discard_count ~= discard_target then
	    s.color_bg = color(.8,.2,.2)
	 else
	    s.color_bg = color(.0,.6,.3)
	 end
      end

      choice_panel:add(title_panel)
      choice_panel:add(card_panel)
      choice_panel:add(done_panel)
      ui:add(choice_panel)
   end

   if cmd == 'donechoosing' then
      wait_count = wait_count + 1
      if wait_count == num_players - 1 then
	 wait_count = 0
	 waiting = false
	 if not already_played then
	    player:play_clear(player.last_played, 999)
	    if player.last_played.requireswait then
	       already_played = true
	    end
	 else
	    already_played = false
	 end
	 players_reacting = 0
      end
   end

   if cmd == 'endgame' then
      choosing = true
      game_over = true
      local v_points = {}
      local count = 1
      for v in string.gmatch(data:match('%a+ ([%d%p]+)'), "[^%p]+") do
	 v_points[count] = v
	 count = count + 1
      end

      local max_points = 0

      for k,v in pairs(v_points) do
	 if tonumber(v) > max_points then
	    max_points = tonumber(v)
	 end
      end

      choice_panel = panel:new(140, 50, 1000, 500)
      choice_panel.name = ""
      choice_panel.color_bg = color(.2,.2,.2)

      for k,v in pairs(v_points) do
	 tmp = panel:new(30, 60+70*(k-1), 940, 50)
	 tmp.name = names[k].." : "..v.." Points"

	 if tonumber(v) < max_points then
	    tmp.color_bg = color(.8,.2,.2)
	 else
	    tmp.color_bg = color(.0,.6,.3)
	 end

	 choice_panel:add(tmp)
      end

      title_panel = panel:new(0, 0, 1000, 30)
      title_panel.name = "Victory Points"
      title_panel.color_bg = color(.4,.4,.4)

      done_panel = panel:new(450, 440, 100, 40)
      done_panel.name = "End Game"
      done_panel.color_bg = color(.4,.4,.4)

      function done_panel.onclick(s, x, y, btn)
	 ui:remove(choice_panel)
	 choosing = false
	 self:gotoState('Menu')
      end

      choice_panel:add(title_panel)
      choice_panel:add(done_panel)
      ui:add(choice_panel)
   end

   if cmd == 'getvictory' then
      udp:send('endgame '..player.id..' '..player:count_victory(), self.ip_address)
   end

   if cmd == 'exit' then
      print("Client kicked out")
      self:gotoState('Menu')
   end

   if cmd == 'updateplayer' then
      play_area = {}
      play_area_info = {}
      active_player = tonumber(data:match('%a+ (%d)'))

      if active_player ~= player_index then
	 last_bought = {}
      end

      if active_player == player_index then
	 love.audio.play(new_turn_sound)
	 if next(player.duration_cards) then

	    choosing = true

	    choice_panel = panel:new(140, 50, 1000, 500)
	    choice_panel.name = ""
	    choice_panel.color_bg = color(.2,.2,.2)

	    title_panel = panel:new(0, 0, 1000, 30)
	    title_panel.name = "Duration Cards"
	    title_panel.color_bg = color(.4,.4,.4)

	    for i=0,6 do
	       for j=0,2 do
		  tmp = panel:new(i*90+30, j*124+66, 75, 120)
		  tmp.name = "Duration Card#"..(i+1)+(j*7)
		  tmp.align = 'center'
		  function tmp:card() return player.duration_cards[(i+1)+(j*7)], (i+1)+(j*7) end

		  function tmp.ondraw(s)
		     if s:card() then
			local img = imgs[s:card().image]
			love.graphics.draw(img, 0, 0, 0, .25, .25)
		     end
		  end

		  function tmp.magnify(s, x, y)
		     if s:card() then
			local img = imgs[s:card().image]
			if x > 1000 then
			   love.graphics.draw(img, x-235, y, 0, .8, .8)
			else
			   love.graphics.draw(img, x, y, 0, .8, .8)
			end
		     end
		  end
		  choice_panel:add(tmp)
	       end
	    end

	    done_panel = panel:new(450, 440, 100, 40)
	    done_panel.name = "Done"
	    done_panel.color_bg = color(.0,.6,.3)

	    function done_panel.onclick(s, x, y, btn)
	       ui:remove(choice_panel)

	       for i,v in ipairs(player.duration_cards) do
		  v:nextturn(player)
	       end

	       for i=#player.duration_cards, 1, -1 do
		  player.discard_pile[#player.discard_pile+1] = table.remove(player.duration_cards, i)
	       end

	       choosing = false
	    end

	    choice_panel:add(title_panel)
	    choice_panel:add(done_panel)
	    ui:add(choice_panel)
	 end
      end
   end

   if cmd == 'initsupply' then
      for i in string.gmatch(data:match('%a+ ([%a%p%s]+)'), "[^%p]+") do
	 supply1[#supply1+1] = cards:newcard(cards.set[i])
      end
   end

   socket.sleep(0.01)
end

function Client:donespying()
   wait_count = wait_count + 1
   if wait_count == num_players then
      wait_count = 0
      waiting = false
      choosing = true

      clicked = {false, false, false, false, false}

      choice_panel = panel:new(140, 50, 1000, 500)
      choice_panel.name = ""
      choice_panel.color_bg = color(.2,.2,.2)

      title_panel = panel:new(0, 0, 1000, 30)
      title_panel.name = "Choose"
      title_panel.color_bg = color(.4,.4,.4)

      card_panel = panel:new(30, 60, 240, 380)
      card_panel.name = ""
      card_panel.align = 'center'

      function card_panel.ondraw(s)
	 local img = imgs['spy']
	 love.graphics.draw(img, 0, 0, 0, .8, .8)
      end

      local tmp

      for k,v in pairs(revealed) do
	 tmp = panel:new(90*(k-1)+285, 66, 75, 120)
	 tmp.name = "Choice Card#"..k
	 tmp.align = 'center'
	 function tmp:card() return v, k end

	 function tmp.ondraw(s)
	    if s:card() then
	       local img = imgs[s:card()]
	       love.graphics.draw(img, 0, 0, 0, .25, .25)
	    end
	 end

	 function tmp.magnify(s, x, y)
	    if s:card() then
	       local img = imgs[s:card()]
	       if x > 1000 then
		  love.graphics.draw(img, x-235, y, 0, .8, .8)
	       else
		  love.graphics.draw(img, x, y, 0, .8, .8)
	       end
	    end
	 end

	 choice_panel:add(tmp)

	 tmp = panel:new(90*(k-1)+285, 66+125, 75, 50)
	 tmp.name = names[tonumber(k)].." Discard"
	 tmp.color_bg = color(.0,.6,.3)

	 function tmp.onclick(s, x, y, btn)
	    if v and v ~= 'back' then
	       if btn == 'l' then
		  if not clicked[k] then
		     local i = tonumber(k)
		     if i == player.id then
			player.discard_pile[#player.discard_pile+1] = table.remove(player.deck, #player.deck)
		     else
			udp:send("discardtop "..i, self.ip_address)
		     end
		     s.color_bg = color(.8,.2,.2)
		     clicked[k] = true
		  end
	       end
	    end
	 end

	 choice_panel:add(tmp)
      end

      done_panel = panel:new(450, 440, 100, 40)
      done_panel.name = "Done"
      done_panel.color_bg = color(.0,.6,.3)

      function done_panel.onclick(s, x, y, btn)
	 ui:remove(choice_panel)
	 revealed = {}
	 choosing = false
      end

      choice_panel:add(title_panel)
      choice_panel:add(card_panel)
      choice_panel:add(done_panel)
      ui:add(choice_panel)
   end
end

function Client:draw()

   ui:draw()

   local last_player = active_player - 1
   if last_player == 0 then
      last_player = num_players
   end

   love.graphics.setFont(fonts[12])
   if not game_end then
      if active_player == player_index then
	 if waiting then
	    love.graphics.setColorMode('modulate')
	    love.graphics.setColor(color(.1,.2,.2, .8))
	    love.graphics.rectangle('fill', 0, 0, 1280, 800)
	    love.graphics.setColor(color(.9,.9,.0))
	    love.graphics.setFont(fonts[32])
	    love.graphics.printf("Waiting on "..num_players-(wait_count+1).." Player(s).", 0, 350, 1280, 'center')
	    love.graphics.setColorMode('replace')
	 else
	    love.graphics.print('It\'s your turn. Last Player Bought / Gained: '..table.concat(last_bought, ', '), 0, 0)
	 end
      else
	 love.graphics.print('Waiting on '..names[active_player]..'.', 0, 0)
      end
   end

   local x, y = love.mouse.getPosition()
   local t = ui:hover(x, y)
   if love.mouse.isDown('r') and t and string.find(t.name, 'Card') then
      t.magnify(t,x,y)
   end
end

function Client:mousepressed(x, y, btn)
   ui:click(x, y, btn)
end

function Client:keypressed(k, u)
   if k=='escape' then
      self:gotoState('Menu')
   end

   --END TURN
   if k=='x' then
      ui:click(62, 693, 'l')
   end

   --COINS
   if k=='z' then
      ui:click(382, 587, 'l')
   end

   --SCROLL LEFT
   if k=='left' then
      player.hand[#player.hand] = table.remove(player.hand, 1)
   end

   --SCROLL RIGHT
   if k=='right' then
      table.insert(player.hand, 1, table.remove(player.hand, #player.hand))
   end
end
