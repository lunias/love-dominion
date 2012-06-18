require 'lua.Panel'
require 'lua.Player'
require 'lua.Cards'

local game_end = false
local game_over = false
active_player = 0
local player = 1
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
local out_counts = 0
local v_points = {}
local sound = false

local Server = Gamestate:addState('Server')

function Server:enterState()
   local tmp

   local found = 0

   players[1]:start()

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
   if #players > 2 then
      supply2_counts[5] = 12
   else
      supply2_counts[5] = 8
   end
   supply2[6] = cards:newcard(cards.set["Duchy"])
   if #players > 2 then
      supply2_counts[6] = 12
   else
      supply2_counts[6] = 8
   end
   supply2[7] = cards:newcard(cards.set["Province"])
   if #players == 2 then
      supply2_counts[7] = 8
   elseif #players > 4 then
      supply2_counts[7] = 15
   else
      supply2_counts[7] = 12
   end
   supply2[8] = cards:newcard(cards.set["Curse"])
   if #players == 2 then
      supply2_counts[8] = 10
   elseif #players == 3 then
      supply2_counts[8] = 20
   elseif #players == 4 then
      supply2_counts[8] = 30
   else
      supply2_counts[8] = 40
   end


   shuffle(cards.set)

   --supply1[#supply1+1] = cards:newcard(cards.set["Coppersmith"])
   --supply1_counts[#supply1_counts+1] = 10

   --supply1[#supply1+1] = cards:newcard(cards.set["Village"])
   --supply1_counts[#supply1_counts+1] = 10

   --supply1[#supply1+1] = cards:newcard(cards.set["Walled Village"])
   --supply1_counts[#supply1_counts+1] = 10

   local count = 0
   local counts = {}
   counts[0] = 0 counts[1] = 0 counts[2] = 0 counts[3] = 0 counts[4] = 0 counts[5] = 0 counts[6] = 0
   for i,v in ipairs(cards.set) do
      if (v.type ~= 'treasure' and v.type ~= 'victory') or v.name == 'Gardens' or v.name == 'Duke' or v.name == 'Vineyard' or v.name == 'Philosophers Stone' then
	 if v.cost.gold == 0 or counts[v.cost.gold] < 3 then
	    supply1[#supply1+1] = cards:newcard(cards.set[v.name])
	    supply1_counts[#supply1_counts+1] = 10
	    count = count + 1
	    counts[v.cost.gold] = counts[v.cost.gold] + 1
	 end
      end
      if count == 10 then
	 break
      end
   end

   table.sort(supply1, function(a,b) return a.cost.gold<b.cost.gold end)

   local sup_tmp = {}
   for i,v in ipairs(supply1) do
      sup_tmp[#sup_tmp+1] = v.name
   end

   for i=2,#players do
      udp:sendto('initsupply '..table.concat(sup_tmp, ','), players[i].ip, players[i].port)
   end

   active_player = math.random(#players)
   if active_player == 1 then
      love.audio.play(new_turn_sound)
   end
   for i=2,#players do
      udp:sendto('updateplayer '..active_player, players[i].ip, players[i].port)
   end

   --INIT UI
   ui = panel:new(0, 0, 1280, 800)
   ui.name = ""
   ui.color_bg = color(.2,.2,.2)

   --PASS PANEL
   pass_panel = panel:new(0, 600, 100, 200)
   pass_panel.name = "End Turn"
   pass_panel.color_bg = color(.2,.6,.5)

   function pass_panel.onupdate(s)
      if active_player == 1 then
	 s.color_bg = color(.2,.6,.5)
      else
	 s.color_bg = color(.6,.2,.5)
      end
   end

   function pass_panel.onclick(s, x, y, btn)
      if active_player == 1 and not choosing and not waiting then

	 --END OF TURN CARDS
	 table.sort(players[1].played, function(a,b) return a.name<b.name end)

	 for i,v in ipairs(players[1].played) do
	    if v.name == "Herbalist" then
	       v:onend(players[1], i)
	       break
	    elseif v.name == "Alchemist" then
	       v:onend(players[1], i)
	       break
	    elseif v.name == "Treasury" then
	       v:onend(players[1], i)
	       break
	    elseif v.name == "Walled Village" then
	       v:onend(players[1], i)
	       break
	    end
	 end

	 if not choosing then
	    players[1].outpost_block = false
	    if not players[1].outpost then
	       active_player = (active_player % #players) + 1
	    else
	       players[1].outpost_block = true
	    end

	    for i=#players[1].hand, 1, -1 do
	       players[1]:discard(i)
	    end

	    for i=#players[1].played, 1, -1 do
	       players[1].discard_pile[#players[1].discard_pile+1] = table.remove(players[1].played, i)
	    end

	    if not players[1].outpost then
	       players[1]:drawcard(5)
	    else
	       players[1]:drawcard(3)
	    end

	    players[1].coins = 0
	    players[1].potions = 0
	    players[1].buys = 1
	    players[1].actions = 1
	    players[1].action_count = 0
	    players[1].victory_count = 0
	    players[1].coppersmith = 0
	    players[1].crossroads = false

	    play_area = {}
	    play_area_info = {}
	    last_bought = {}

	    gain = 0
	    gaining = false

	    for i=2,#players do
	       udp:sendto('updateplayer '..active_player, players[i].ip, players[i].port)
	    end

	    if players[1].outpost then
	       udp:sendto('cleanup', players[1].ip, players[1].port)
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
      function tmp:card() return players[1].hand[i+1], i+1 end

      function tmp.ondraw(s)
	 if s:card() then
	    local img = imgs[s:card().image]
	    love.graphics.draw(img, 0, 0, 0, .4, .4)
	 end
      end

      function tmp.onclick(s, x, y, btn)
	 if s:card() and active_player == 1 and not choosing and not waiting then
	    local c, i = s:card()
	    if btn == 'l' and c.type ~= 'victory' then
	       if players[1].actions > 0 or c.type == 'treasure' or c.type == 'tv' then
		  play_area[#play_area+1] = c.image
		  play_area_info[#play_area_info+1] = "P"

		  for i=2,#players do
		     udp:sendto('played '..c.image..",".."P", players[i].ip, players[i].port)
		  end

		  if c.type == 'action' or c.type == 'attack' or c.type == 'reaction' or c.type == 'av' then
		     players[1].actions = players[1].actions - 1
		     players[1].action_count = players[1].action_count + 1
		  end

		  if c.type == 'treasure' or c.type == 'tv' then
		     players[1].actions = 0
		  end
		  players[1]:play(c, i)
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
      if #players[1].hand > 7 then
	 s.color_txt = color(.9,.1,.1)
	 s.name = #players[1].hand - 7
      else
	 s.name = "<"
	 s.color_txt = color(.9,.9,.9)
      end
   end

   function scroll_panel.onclick(s, x, y, btn)
      players[1].hand[#players[1].hand] = table.remove(players[1].hand, 1)
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
      love.graphics.printf(#players[1].deck, 0, 42, 125, 'center')
      love.graphics.setColor(color(.9,.0,.0))
      love.graphics.printf(#players[1].discard_pile, 0, 102, 125, 'center')
      love.graphics.setColorMode('replace')
   end

   function deck_panel.onclick(s, x, y, btn)
      if btn == 'l' and game_over then
	 players[1]:drawcard(1)
      end
   end

   --INFO BAR
   --PLAYER
   player_panel = panel:new(50, 570, 156, 30)
   player_panel.name = players[1].name
   player_panel.color_bg = color(.8,.2,.2)

   --COINS
   coins_panel = panel:new(306, 570, 156, 30)
   coins_panel.name = "Coins: "..players[1].coins
   coins_panel.color_bg = color(.6,.4,.0)

   function coins_panel.onupdate(s)
      s.name = "Coins: "..players[1].coins
   end

   function coins_panel.onclick(s, x, y, btn)
      if btn == 'l' and active_player == 1 and not choosing and not waiting then
	 players[1].actions = 0
	 for i=#players[1].hand, 1, -1 do
	    if players[1].hand[i].type == 'treasure' or players[1].hand[i].type == 'tv' then
	       play_area[#play_area+1] = players[1].hand[i].image
	       play_area_info[#play_area_info+1] = "P"

	       for j=2,#players do
		  udp:sendto('played '..players[1].hand[i].image..",".."P", players[j].ip, players[j].port)
	       end

	       players[1]:play(players[1].hand[i], i)
	    end
	 end
      end
   end

   --POTIONS
   potions_panel = panel:new(562, 570, 156, 30)
   potions_panel.name = "Potions: "..players[1].potions
   potions_panel.color_bg = color(.3,.2,.3)

   function potions_panel.onupdate(s)
      s.name = "Potions: "..players[1].potions
   end

   --ACTIONS
   actions_panel = panel:new(818, 570, 156, 30)
   actions_panel.name = "Actions: "..players[1].actions
   actions_panel.color_bg = color(.3,.2,.6)

   function actions_panel.onupdate(s)
      s.name = "Actions: "..players[1].actions
   end

   --BUYS
   buys_panel = panel:new(1074, 570, 156, 30)
   buys_panel.name = "Buys: "..players[1].buys
   buys_panel.color_bg = color(.2,.5,.5)

   function buys_panel.onupdate(s)
      s.name = "Buys: "..players[1].buys
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
	       if players[1].coins < s:card().cost.gold or players[1].potions < s:card().cost.potion or players[1].buys == 0 or active_player ~= 1 or supply1_counts[i+1] == 0 then
		  love.graphics.setColor(color(.4,.4,.4))
	       else
		  love.graphics.setColor(color(1,1,1))
	       end
	    else
	       if (gain_type ~= 'any' and (gain_type ~= s:card().type and gain_type2 ~= s:card().type)) or gain < s:card().cost.gold or s:card().cost.potion > 0 or active_player ~= 1 or supply1_counts[i+1] == 0 then
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
	 if s:card() and active_player == 1 and not choosing and not waiting then
	    local c, i = s:card()
	    if btn == 'l' then
	       if not gaining then
		  if supply1_counts[i] ~= 0 and players[1].coins >= c.cost.gold and players[1].potions >= c.cost.potion and players[1].buys > 0 then
		     love.audio.play(buy_sound)
		     players[1].discard_pile[#players[1].discard_pile+1] = c
		     players[1].buys = players[1].buys - 1
		     players[1].coins = players[1].coins - c.cost.gold
		     players[1].potions = players[1].potions - c.cost.potion
		     play_area[#play_area+1] = c.image
		     play_area_info[#play_area_info+1] = "B"
		     supply1_counts[i] = supply1_counts[i] - 1
		     players[1].actions = 0

		     if c.type == 'victory' or c.type == 'av' or c.type == 'tv' then
			players[1].victory_count = players[1].victory_count + 1
		     end

		     for j=2,#players do
			udp:sendto('boughtone '..i, players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('played '..c.image..",".."B", players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('lastbought '..c.name, players[j].ip, players[j].port)
		     end

		     if supply1_counts[i] == 0 then
			out_counts = out_counts + 1
			if (#players < 5 and out_counts > 2) or (#players > 5 and out_counts > 3) then
			   --END GAME
			   v_points[1] = players[1]:count_victory()

			   for i=2,#players do
			      udp:sendto('getvictory', players[i].ip, players[i].port)
			   end
			   print("GAME OVER")
			end
		     end
		  end
	       else
		  if supply1_counts[i] ~= 0 and (gain_type == 'any' or gain_type == c.type or gain_type2 == c.type) and gain >= c.cost.gold and c.cost.potion == 0 then
		     love.audio.play(buy_sound)
		     players[1].discard_pile[#players[1].discard_pile+1] = c

		     if players[1].last_played.name == "Ironworks" then
			if c.type == 'treasure' or c.type == 'tv' then
			   players[1].coins = players[1].coins + 1
			end
			if c.type == 'action' or c.type == 'av' then
			   players[1].actions = players[1].actions + 1
			end
			if c.type == 'victory' or c.type == 'av' then
			   players[1]:drawcard()
			end
		     end

		     play_area[#play_area+1] = c.image
		     play_area_info[#play_area_info+1] = "G"
		     supply1_counts[i] = supply1_counts[i] - 1

		     for j=2,#players do
			udp:sendto('boughtone '..i, players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('played '..c.image..",".."G", players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('lastbought '..c.name, players[j].ip, players[j].port)
		     end

		     gain = 0
		     gain_type = 'any'
		     gain_type2 = 'any'
		     gaining = false

		     if supply1_counts[i] == 0 then
			out_counts = out_counts + 1
			if (#players < 5 and out_counts > 2) or (#players > 5 and out_counts > 3) then
			   --END GAME
			   v_points[1] = players[1]:count_victory()

			   for i=2,#players do
			      udp:sendto('getvictory', players[i].ip, players[i].port)
			   end
			   print("GAME OVER")
			end
		     end

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
	       if players[1].coins < s:card().cost.gold or players[1].buys == 0 or active_player ~= 1 or supply2_counts[i+1] == 0 then
		  love.graphics.setColor(color(.4,.4,.4))
	       else
		  love.graphics.setColor(color(1,1,1))
	       end
	    else
	       if (gain_type ~= 'any' and (gain_type ~= s:card().type and gain_type2 ~= s:card().type)) or gain < s:card().cost.gold or active_player ~= 1 or supply2_counts[i+1] == 0 then
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
	 if s:card() and active_player == 1 and not choosing and not waiting then
	    local c, i = s:card()
	    if btn == 'l' then
	       if not gaining then
		  if supply2_counts[i] ~= 0 and players[1].coins >= c.cost.gold and players[1].potions >= c.cost.potion and players[1].buys > 0 then
		     love.audio.play(buy_sound)
		     players[1].discard_pile[#players[1].discard_pile+1] = c
		     players[1].buys = players[1].buys - 1
		     players[1].coins = players[1].coins - c.cost.gold
		     play_area[#play_area+1] = c.image
		     play_area_info[#play_area_info+1] = "B"
		     supply2_counts[i] = supply2_counts[i] - 1
		     players[1].actions = 0

		     if c.type == 'victory' or c.type == 'av' or c.type == 'tv' then
			players[1].victory_count = players[1].victory_count + 1
		     end

		     for j=2,#players do
			udp:sendto('boughtdos '..i, players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('played '..c.image..",".."B", players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('lastbought '..c.name, players[j].ip, players[j].port)
		     end

		     if supply2_counts[i] == 0 then
			out_counts = out_counts + 1
			if (#players < 5 and out_counts > 2) or (#players > 5 and out_counts > 3) or supply2_counts[7] == 0 then
			   --END GAME
			   v_points[1] = players[1]:count_victory()

			   for i=2,#players do
			      udp:sendto('getvictory', players[i].ip, players[i].port)
			   end
			   print("GAME OVER")
			end
		     end
		  end
	       else
		  if supply2_counts[i] ~= 0 and (gain_type == 'any' or gain_type == c.type or gain_type2 == c.type) and gain >= c.cost.gold then
		     love.audio.play(buy_sound)
		     if players[1].last_played.name == "Mine" then
			players[1].hand[#players[1].hand+1] = c
		     else
			players[1].discard_pile[#players[1].discard_pile+1] = c
		     end

		     if players[1].last_played.name == "Ironworks" then
			if c.type == 'treasure' or c.type == 'tv' then
			   players[1].coins = players[1].coins + 1
			end
			if c.type == 'action' or c.type == 'av' then
			   players[1].actions = players[1].actions + 1
			end
			if c.type == 'victory' or c.type == 'av'  then
			   players[1]:drawcard()
			end
		     end

		     play_area[#play_area+1] = c.image
		     play_area_info[#play_area_info+1] = "G"
		     supply2_counts[i] = supply2_counts[i] - 1

		     for j=2,#players do
			udp:sendto('boughtone '..i, players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('played '..c.image..",".."G", players[j].ip, players[j].port)
		     end

		     for j=2,#players do
			udp:sendto('lastbought '..c.name, players[j].ip, players[j].port)
		     end

		     gain = 0
		     gain_type = 'any'
		     gain_type2 = 'any'
		     gaining = false

		     if supply2_counts[i] == 0 then
			out_counts = out_counts + 1
			if (#players < 5 and out_counts > 2) or (#players > 5 and out_counts > 3) or supply2_counts[7] == 0 then
			   --END GAME
			   v_points[1] = players[1]:count_victory()

			   for i=2,#players do
			      udp:sendto('getvictory', players[i].ip, players[i].port)
			   end
			   print("GAME OVER")
			end
		     end
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
	 print("Clicked on trash. "..#players[1].trash)
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

   --UI ADDS
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

function Server:exitState()
   ui = nil

   game_over = false
   active_player = 0
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
   out_counts = 0
   sound = false
   v_points = {}
end

dtotal = 0
function Server:update(dt)
   dtotal = dtotal + dt

   if dtotal >= (1/10) then
      dtotal = dtotal - (1/10)
      ui:update(dt)
   end

   if active_player ~= 1 and choosing and not sound then
      sound = true
      love.audio.play(attack_sound)
   end

   if not choosing then
      sound = false
   end

   local data, ip, port = udp:receivefrom()
   local cmd
   if data then
      self.ip = ip
      self.port = port
      cmd = data:match('(%a+)')
   end

   local to_draw
   if cmd == "draw" then
      to_draw = tonumber(data:match('%a+ (%d+)'))
      players[1]:drawcard(to_draw)
   end

   if cmd == "drawallother" then
      to_draw = tonumber(data:match('%a+ (%d+)'))
      players[1]:drawcard(to_draw)

      for i=2,#players do
	 if i ~= active_player then
	    udp:sendto('draw '..to_draw, players[i].ip, players[i].port)
	 end
      end
   end

   if cmd == "discardtop" then
      local index = tonumber(data:match('%a+ (%d+)'))
      if index == 1 then
	 players[1].discard_pile[#players[1].discard_pile+1] = table.remove(players[1].deck, #players[1].deck)
      else
	 udp:sendto('discardtop', players[index].ip, players[index].port)
      end
   end

   if cmd == "reacting" then
      players_reacting = players_reacting + 1
   end

   if cmd == "canreact" then
      for i=2,#players do
	 if i ~= active_player then
	    udp:sendto("canreact", players[i].ip, players[i].port)
	 end
      end

      if players[1]:can_react() then
	 udp:sendto("reactingcount "..players_reacting+1, players[active_player].ip, players[active_player].port)
	 players[1]:react()
      else
	 udp:sendto("donechoosing", players[active_player].ip, players[active_player].port)
      end
      players_reacting = 0
   end

   if cmd == "cutpurse" then
      if not players[1].unaffected and not players[1].lighthouse then
	 for i,v in ipairs(players[1].hand) do
	    if v.name == 'Copper' then
	       players[1].discard_pile[#players[1].discard_pile+1] = table.remove(players[1].hand, i)
	       break
	    end
	 end
      else
	 players[1].unaffected = false
      end

      for i=2,#players do
	 if not players[i].unaffected and not players[i].lightouse and active_player ~= i then
	    udp:sendto('cutpurse', players[i].ip, players[i].port)
	 else
	    players[i].unaffected = false
	 end
      end
   end

   if cmd == "witch" then
      local witch_count = supply2_counts[8]
      if witch_count == 0 then
	 return
      end

      if not players[1].unaffected and not players[1].lighthouse then
	 supply2_counts[8] = supply2_counts[8] - 1
	 for j=2,#players do
	    udp:sendto('boughtdos '..8, players[j].ip, players[j].port)
	 end
	 witch_count = witch_count - 1
	 players[1].discard_pile[#players[1].discard_pile+1] = supply2[8]
      else
	 players[1].unaffected = false
      end

      for i=2,#players do
	 if i ~= active_player and witch_count > 0 then
	    if not players[i].unaffected and not players[i].lighthouse then
	       witch_count = witch_count - 1
	       udp:sendto('witch', players[i].ip, players[i].port)
	    else
	       players[i].unaffected = false
	    end
	 end
      end
   end

   if cmd == 'minion' then
      if not players[1].unaffected and not players[1].lighthouse then
	 if #players[1].hand > 4 then
	    for i=#players[1].hand, 1, -1 do
	       players[1]:discard(i)
	    end
	    players[1]:drawcard(4)
	 end
      else
	 players[1].unaffected = false
      end

      for i=2,#players do
	 if not players[i].unaffected and not players[i].lighthouse and i ~= active_player then
	    udp:sendto('minion', players[i].ip, players[i].port)
	 else
	    players[i].unaffected = false
	 end
      end
   end

   local card
   local info
   if cmd == "played" then
      for i in string.gmatch(data:match('%a+ ([%a%p%s%d]+)'), "[^,]+") do
	 if #i == 1 then
	    play_area_info[#play_area_info+1] = i
	    info = i
	 else
	    play_area[#play_area+1] = i
	    card = i
	 end
      end

      for i=2,#players do
	 udp:sendto('played '..card..","..info, players[i].ip, players[i].port)
      end
   end

   if cmd == "unaffected" then
      local index = tonumber(data:match('%a+ (%d+)'))
      players[index].unaffected = true
   end

   if cmd == "lighthouse" then
      local state = data:match('%a+ (%a+) %d+')
      local index = tonumber(data:match('%a+ %a+ (%d+)'))

      if state == 'on' then
	 players[index].lighthouse = true
      else
	 players[index].lighthouse = false
      end
   end

   if cmd == "boughtone" then
      index = tonumber(data:match('%a+ (%d+)'))
      supply1_counts[index] = supply1_counts[index] - 1

      if supply1_counts[index] == 0 then
	 out_counts = out_counts + 1
	 if (#players < 5 and out_counts > 2) or (#players > 5 and out_counts > 3) then
	    --END GAME
	    v_points[1] = players[1]:count_victory()

	    for i=2,#players do
	       udp:sendto('getvictory', players[i].ip, players[i].port)
	    end
	    print("GAME OVER")
	 end
      end

      for i=2,#players do
	 udp:sendto('boughtone '..index, players[i].ip, players[i].port)
      end
   end

   if cmd == "boughtdos" then
      index = tonumber(data:match('%a+ (%d+)'))
      supply2_counts[index] = supply2_counts[index] - 1

      if supply2_counts[index] == 0 then
	 out_counts = out_counts + 1
	 if (#players < 5 and out_counts > 2) or (#players > 5 and out_counts > 3) or supply2_counts[7] == 0 then
	    --END GAME
	    v_points[1] = players[1]:count_victory()

	    for i=2,#players do
	       udp:sendto('getvictory', players[i].ip, players[i].port)
	    end
	    print("GAME OVER")
	 end
      end

      for i=2,#players do
	 udp:sendto('boughtdos '..index, players[i].ip, players[i].port)
      end
   end

   if cmd == "lastbought" then
      local card = data:match('%a+ ([%a%s]+)')

      last_bought[#last_bought+1] = card

      for i=2,#players do
	 if active_player ~= i then
	    udp:sendto('lastbought '..card, players[i].ip, players[i].port)
	 end
      end
   end

   if cmd == 'torturer' then
      choosing = true

      for i=2,#players do
	 if i ~= active_player then
	    if not players[i].unaffected and not players[i].lighthouse then
	       udp:sendto('torturer', players[i].ip, players[i].port)
	    else
	       udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
	       players[i].unaffected = false
	    end
	 end
      end

      if players[1].unaffected or players[1].lighthouse then
	 udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
	 choosing = false
	 players[1].unaffected = false
	 return
      end

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
		  function tmp:card() return players[1].hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
			      players[1]:discard(i)
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
	       if discard_count == 2 or #players[1].hand == 0 then
		  done_panel.color_bg = color(.0,.6,.3)
	       end
	    end

	    function done_panel.onclick(s, x, y, btn)
	       if discard_count == 2 or #players[1].hand == 0 then
		  udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
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
	       supply2_counts[8] = supply2_counts[8] - 1
	       for j=2,#players do
		  udp:sendto('boughtdos '..8, players[j].ip, players[j].port)
	       end
	       players[1].hand[#players[1].hand+1] = supply2[8]

	       udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
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

      for i=2,#players do
	 if i ~= active_player then
	    if not players[i].unaffected and not players[i].lighthouse then
	       udp:sendto('bureaucrat', players[i].ip, players[i].port)
	    else
	       udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
	       players[i].unaffected = false
	    end
	 end
      end

      if players[1].unaffected or players[1].lighthouse then
	 udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
	 choosing = false
	 players[1].unaffected = false
	 return
      end

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
      for i,v in ipairs(players[1].hand) do
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
			players[1].deck[#players[1].deck+1] = table.remove(players[1].hand, i)

			  play_area[#play_area+1] = c.image
			  play_area_info[#play_area_info+1] = "R"

			  for i=2,#players do
			     udp:sendto('played '..c.image..",".."R", players[i].ip, players[i].port)
			  end

			  udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
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
	    udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
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

      if active_player == 1 then
	 revealed[index] = card
	 self:donespying()
      else
	 udp:sendto('reveal '..card..' '..index, players[active_player].ip, players[active_player].port)
      end
   end

   if cmd == 'spy' then
      local c = players[1]:revealtop()

      if c and not players[1].unaffected and not players[1].lighthouse then
	 play_area[#play_area+1] = c.image
	 play_area_info[#play_area_info+1] = "1"
	 for i=2,#players do
	    udp:sendto('played '..c.image..",".."1", players[i].ip, players[i].port)
	 end
	 udp:sendto('reveal '..c.image..' '..1, players[active_player].ip, players[active_player].port)
      else
	 udp:sendto('reveal back '..1, players[active_player].ip, players[active_player].port)
      end

      for i=2,#players do
	 if not players[i].unaffected and not players[i].lighthouse then
	    udp:sendto('spy', players[i].ip, players[i].port)
	 else
	    udp:sendto('reveal back '..i, players[active_player].ip, players[active_player].port)
	    players[i].unaffected = false
	 end
      end
   end

   if cmd == 'donespying' then
      self:donespying()
   end

   if cmd == 'tribute' then
      if (active_player % #players) + 1 == 1 then
	 for i=0,1 do
	    local revealed = players[1]:discardtop()

	    if not revealed then
	       return
	    end

	    play_area[#play_area+1] = c.image
	    play_area_info[#play_area_info+1] = "R"

	    for i=2,#players do
	       udp:sendto('played '..c.image..",".."R", players[i].ip, players[i].port)
	    end

	    udp:sendto('tributecards', players[active_player].ip, players[active_player].port)
	 end
      else
	 udp:sendto('tribute', players[(active_player % #players)+1].ip, players[(active_player % #players)+1].port)
      end
   end

   if cmd == 'militia' then
      choosing = true

      for i=2,#players do
	 if i ~= active_player then
	    if not players[i].unaffected and not players[i].lighthouse then
	       udp:sendto('militia', players[i].ip, players[i].port)
	    else
	       udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
	       players[i].unaffected = false
	    end
	 end
      end

      local discard_count = 0
      local discard_target = #players[1].hand - 3

      if discard_target < 1 or players[1].unaffected or players[1].lighthouse then
	 udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
	 choosing = false
	 players[1].unaffected = false
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
      if #players[1].hand > 0 then
	 for i=0,6 do
	    for j=0,2 do
	       tmp = panel:new(i*90+285, j*124+66, 75, 120)
	       tmp.name = "Choice Card#"..(i+1)+(j*7)
	       tmp.align = 'center'
	       function tmp:card() return players[1].hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
			   players[1]:discard(i)
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
	    udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
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
      if active_player == 1 then
	 wait_count = wait_count + 1
	 if wait_count == #players - 1 then
	    wait_count = 0
	    waiting = false
	    if not already_played then
	       players[1]:play_clear(players[1].last_played, 999)
	       if players[1].last_played.requireswait then
		  already_played = true
	       end
	    else
	       already_played = false
	    end
	    players_reacting = 0
	 end
      else
	 udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
      end
   end

   if cmd == "cleanup" then
      local arg = data:match('%a+ (%a+)')
      play_area = {}
      play_area_info = {}

      if not players[1].outpost then
	 if not arg then
	    active_player = (active_player % #players) + 1
	 end

	 for i=2,#players do
	    udp:sendto('updateplayer '..active_player, players[i].ip, players[i].port)
	 end
      end

      if active_player ~= 1 then
	 last_bought = {}
      end

      if active_player == 1 then
	 love.audio.play(new_turn_sound)
	 if next(players[1].duration_cards) then

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
		  function tmp:card() return players[1].duration_cards[(i+1)+(j*7)], (i+1)+(j*7) end

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

	       for i,v in ipairs(players[1].duration_cards) do
		  v:nextturn(players[1])
	       end

	       for i=#players[1].duration_cards, 1, -1 do
		  players[1].discard_pile[#players[1].discard_pile+1] = table.remove(players[1].duration_cards, i)
	       end

	       choosing = false
	    end

	    choice_panel:add(title_panel)
	    choice_panel:add(done_panel)
	    ui:add(choice_panel)
	 end
      end
   end

   if cmd == "endgame" then
      local player = data:match('%a+ (%d+)')
      local total = data:match('%a+ %d+ (%d+)')

      v_points[tonumber(player)] = total
      self:victory_wait()
   end

   socket.sleep(0.01)
end

function Server:victory_wait()
   wait_count = wait_count + 1
   if wait_count == #players - 1 then
      wait_count = 0
      waiting = false
      choosing = true
      game_over = true

      local point_list = {}
      local max_points = 0

      for k,v in pairs(v_points) do
	 point_list[#point_list+1] = v
	 if tonumber(v) > max_points then
	    max_points = tonumber(v)
	 end
      end

      for i=2,#players do
	 udp:sendto('endgame '..table.concat(point_list, ','), players[i].ip, players[i].port)
      end

      choice_panel = panel:new(140, 50, 1000, 500)
      choice_panel.name = ""
      choice_panel.color_bg = color(.2,.2,.2)

      for k,v in pairs(v_points) do
	 tmp = panel:new(30, 60+70*(k-1), 940, 50)
	 tmp.name = players[k].name.." : "..v.." Points"

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
end

function Server:donespying()
   wait_count = wait_count + 1
   if wait_count == #players - 1 then
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
	 tmp.name = players[tonumber(k)].name.." Discard"
	 tmp.color_bg = color(.0,.6,.3)

	 function tmp.onclick(s, x, y, btn)
	    if v and v ~= 'back' then
	       if btn == 'l' then
		  if not clicked[k] then
		     local i = tonumber(k)
		     if i == 1 then
			players[1].discard_pile[#players[1].discard_pile+1] = table.remove(players[1].deck, #players[1].deck)
		     else
			udp:sendto("discardtop", players[i].ip, players[i].port)
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

function Server:draw()

   ui:draw()

   local last_player = active_player - 1
   if last_player == 0 then
      last_player = #players
   end

   love.graphics.setFont(fonts[12])
   if not game_end then
      if active_player == 1 then
	 if waiting then
	    love.graphics.setColorMode('modulate')
	    love.graphics.setColor(color(.1,.2,.2, .8))
	    love.graphics.rectangle('fill', 0, 0, 1280, 800)
	    love.graphics.setColor(color(.9,.9,.0))
	    love.graphics.setFont(fonts[32])
	    love.graphics.printf("Waiting on "..#players-(wait_count+1).." Player(s).", 0, 350, 1280, 'center')
	    love.graphics.setColorMode('replace')
	 else
	    love.graphics.print('It\'s your turn. Last Player Bought / Gained: '..table.concat(last_bought, ', '), 0, 0)
	 end
      else
	 love.graphics.print('Waiting on '..players[active_player].name..'.', 0, 0)
      end
   end

   local x, y = love.mouse.getPosition()
   local t = ui:hover(x, y)
   if love.mouse.isDown('r') and t and string.find(t.name, 'Card') then
      t.magnify(t,x,y)
   end
end

function Server:mousepressed(x, y, btn)
   ui:click(x, y, btn)
end


function Server:keypressed(k, u)
   if k=='escape' then
      for i=2,#players do
	 udp:sendto('exit', players[i].ip, players[i].port)
      end
      print("Server left the game.")
      self:gotoState('Menu')
   end

   --if k=='e' then
   --   v_points[1] = players[1]:count_victory()
   --
   --   for i=2,#players do
   --	 udp:sendto('getvictory', players[i].ip, players[i].port)
   --   end
   --end

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
      players[1].hand[#players[1].hand] = table.remove(players[1].hand, 1)
   end

   --SCROLL RIGHT
   if k=='right' then
      table.insert(players[1].hand, 1, table.remove(players[1].hand, #players[1].hand))
   end
end