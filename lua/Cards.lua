local _M = {_NAME = "cards", _TYPE = 'module'}

require "lua.Utils"

function _M:newcard(t)
   local c = {}

   c._TYPE  = 'card'
   c.name   = t.name or "Card"
   c.type   = t.type or 'treasure'
   c.image  = t.image or 'back'
   c.onturn = t.onturn or function() end;
   c.reaction = t.reaction or function() end;
   c.nextturn = t.nextturn or function() end;
   c.onend = t.onend or function() end;
   c.requireswait = t.requireswait or false;
   c.duration = t.duration or false;
   c.cost   = t.cost or {}
   c.worth  = t.worth or 0
   c.potion = t.potion or 0
   c.set    = t.set or {}

   return c
end

local set = {}
_M.set = set

local function addcard(c)
   c = _M:newcard(c)
   if not set[c.name] then
      set[c.name] = c
      set[#set+1] = c
   end
end

--COMPLETE
addcard{name = "Adventurer", type='action';
	image = 'adventurer';
	cost = {gold=6, potion=0};
	onturn = function(s, p)
		    local c
		    local t_count = 0
		    while true do
		       c = p:revealtop()

		       if c == nil then
			  break
		       end

		       if c.type == 'treasure' or c.type == 'tv' then
			  p:drawcard()
			  t_count = t_count + 1
		       else
			  p.discard_pile[#p.discard_pile+1] = table.remove(p.deck, #p.deck)
		       end

		       if p.id == 1 then
			  play_area[#play_area+1] = c.image
			  play_area_info[#play_area_info+1] = "R"

			  for i=2,#players do
			     udp:sendto('played '..c.image..",".."R", players[i].ip, players[i].port)
			  end
		       else
			  udp:send('played '..c.image..",".."R", s.ip_address)
		       end

		       if t_count == 2 then
			  table.sort(p.hand, function(a,b) return a.name<b.name end)
			  break
		       end
		    end
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Alchemist", type='action';
	image = 'alchemist';
	cost = {gold=3, potion=1};
	onturn = function(s, p)
		    p:drawcard(2)
		    p.actions = p.actions + 2
		 end;
	onend = function(s, p, index)

		   local played_potion = false
		   for i,v in ipairs(p.played) do
		      if v.name == "Potion" then
			 played_potion = true
			 break
		      end
		   end

		   if not played_potion then
		      p.discard_pile[#p.discard_pile+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		      return
		   end

		   choosing = true

		   choice_panel = panel:new(465, 50, 350, 500)
		   choice_panel.name = ""
		   choice_panel.color_bg = color(.2,.2,.2)

		   title_panel = panel:new(0, 0, 350, 30)
		   title_panel.name = "Put on Top of Deck?"
		   title_panel.color_bg = color(.4,.4,.4)

		   card_panel = panel:new(55, 40, 240, 380)
		   card_panel.name = ""
		   card_panel.align = 'center'

		   function card_panel.ondraw(s)
		      local img = imgs['alchemist']
		      love.graphics.draw(img, 0, 0, 0, .8, .8)
		   end

		   yes_panel = panel:new(50, 440, 100, 40)
		   yes_panel.name = "Yes"
		   yes_panel.color_bg = color(.0,.6,.3)

		   function yes_panel.onclick(s, x, y, btn)
		      p.deck[#p.deck+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		   end

		   no_panel = panel:new(200, 440, 100, 40)
		   no_panel.name = "No"
		   no_panel.color_bg = color(.8,.2,.2)

		   function no_panel.onclick(s, x, y, btn)
		      p.discard_pile[#p.discard_pile+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		   end

		   choice_panel:add(title_panel)
		   choice_panel:add(card_panel)
		   choice_panel:add(yes_panel)
		   choice_panel:add(no_panel)
		   ui:add(choice_panel)
		end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Apothecary", type='action';
	image = 'apothecary';
	cost = {gold=2, potion=1};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1

		    local choices = {}
		    local c

		    for i=0,3 do
		       c = p:revealtop()
		       if not c then
			  break
		       else
			  if c.name == "Copper" or c.name == "Potion" then
			     p.hand[#p.hand+1] = table.remove(p.deck, #p.deck)
			     table.sort(p.hand, function(a,b) return a.name<b.name end)
			  else
			     choices[#choices+1] = table.remove(p.deck, #p.deck)
			  end
		       end
		    end

		    if next(choices) ~= nil then
		       choosing = true

		       choice_panel = panel:new(140, 50, 1000, 500)
		       choice_panel.name = ""
		       choice_panel.color_bg = color(.2,.2,.2)

		       title_panel = panel:new(0, 0, 1000, 30)
		       title_panel.name = "Put Cards on Top of Deck"
		       title_panel.color_bg = color(.4,.4,.4)

		       card_panel = panel:new(30, 60, 240, 380)
		       card_panel.name = ""
		       card_panel.align = 'center'

		       function card_panel.ondraw(s)
			  local img = imgs['apothecary']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       local tmp

		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return choices[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p.deck[#p.deck+1] = table.remove(choices, i)
				      if next(choices) == nil then
					 ui:remove(choice_panel)
					 choosing = false
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

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       ui:add(choice_panel)
		    end
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Apprentice", type='action';
	image = 'apprentice';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions + 1

		    if next(p.hand) == nil then
		       return
		    end

		    choosing = true

		    choice_panel = panel:new(140, 50, 1000, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 1000, 30)
		    title_panel.name = "Trash a Card"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(30, 60, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['apprentice']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    if #p.hand > 0 then
		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p:trash_card(i)

				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "T"
					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."T", s.ip_address)
				      end

				      p:drawcard(c.cost.gold)
				      if c.cost.potion ~= 0 then
					 p:drawcard(2)
				      end

				      ui:remove(choice_panel)
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
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Baron", type='action';
	image = 'baron';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
	            p.buys = p.buys + 1

		    local has_estate = false
		    local estate_index = 0

		    for i,v in ipairs(p.hand) do
		       if v.name == 'Estate' then
			  has_estate = true
			  estate_index = i
			  break
		       end
		    end

		    if has_estate then
		       choosing = true

		       choice_panel = panel:new(465, 50, 350, 500)
		       choice_panel.name = ""
		       choice_panel.color_bg = color(.2,.2,.2)

		       title_panel = panel:new(0, 0, 350, 30)
		       title_panel.name = "Discard Estate?"
		       title_panel.color_bg = color(.4,.4,.4)

		       card_panel = panel:new(55, 40, 240, 380)
		       card_panel.name = ""
		       card_panel.align = 'center'

		       function card_panel.ondraw(s)
			  local img = imgs['baron']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       yes_panel = panel:new(50, 440, 100, 40)
		       yes_panel.name = "Yes"
		       yes_panel.color_bg = color(.0,.6,.3)

		       function yes_panel.onclick(s, x, y, btn)
			  p:discard(estate_index)
			  p.coins = p.coins + 4
			  ui:remove(choice_panel)
			  choosing = false
		       end

		       no_panel = panel:new(200, 440, 100, 40)
		       no_panel.name = "No"
		       no_panel.color_bg = color(.8,.2,.2)

		       function no_panel.onclick(s, x, y, btn)
			  if supply2_counts[5] > 0 then
			     p.discard_pile[#p.discard_pile+1] = supply2[5]
			     supply2_counts[5] = supply2_counts[5] - 1

			     if p.id == 1 then
				play_area[#play_area+1] = supply2[5].image
				play_area_info[#play_area_info+1] = "G"
				supply2_counts[5] = supply2_counts[5] - 1

				for i=2,#players do
				   udp:sendto('boughtdos '..5, players[i].ip, players[i].port)
				end

				for i=2,#players do
				   udp:sendto('played '..supply2[5].image..",".."G", players[i].ip, players[i].port)
				end

				for i=2,#players do
				   udp:sendto('lastbought '..supply2[5].name, players[i].ip, players[i].port)
				end
			     else
				udp:send('boughtdos '..5, s.ip_address)
				udp:send('lastbought '..supply2[5].name, s.ip_address)
				udp:send('played '..supply2[5].image..",".."G", s.ip_address)
			     end
			  end

			  ui:remove(choice_panel)
			  choosing = false
		       end

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       choice_panel:add(yes_panel)
		       choice_panel:add(no_panel)
		       ui:add(choice_panel)
		    else
		       if supply2_counts[5] > 0 then
			  p.discard_pile[#p.discard_pile+1] = supply2[5]

			  if p.id == 1 then
			     play_area[#play_area+1] = supply2[5].image
			     play_area_info[#play_area_info+1] = "G"
			     supply2_counts[5] = supply2_counts[5] - 1

			     for i=2,#players do
				udp:sendto('boughtdos '..5, players[i].ip, players[i].port)
			     end

			     for i=2,#players do
				udp:sendto('played '..supply2[5].image..",".."G", players[i].ip, players[i].port)
			     end

			     for i=2,#players do
				udp:sendto('lastbought '..supply2[5].name, players[i].ip, players[i].port)
			     end
			  else
			     udp:send('boughtdos '..5, s.ip_address)
			     udp:send('lastbought '..supply2[5].name, s.ip_address)
			     udp:send('played '..supply2[5].image..",".."G", s.ip_address)
			  end
		       end
		    end
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Bazaar", type='action';
	image = 'bazaar';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard(1)
		    p.actions = p.actions + 2
		    p.coins = p.coins + 1
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Bureaucrat", type='attack';
	image = 'bureaucrat';
	cost = {gold=4, potion=0};
	requireswait = true;
	onturn = function(s, p)
		    if supply2_counts[2] > 0 then

		       p.deck[#p.deck+1] = supply2[2]
		       waiting = true
		       if p.id == 1 then
			  supply2_counts[2] = supply2_counts[2] - 1
			  play_area[#play_area+1] = supply2[2].image
			  play_area_info[#play_area_info+1] = "G"

			  for i=2,#players do
			     udp:sendto('boughtdos '..2, players[i].ip, players[i].port)
			  end

			  for i=2,#players do
			     udp:sendto('played '..supply2[2].image..",".."G", players[i].ip, players[i].port)
			  end

			  for i=2,#players do
			     udp:sendto('lastbought '..supply2[2].name, players[i].ip, players[i].port)
			  end

			  for i=2,#players do
			     if not players[i].unaffected and not players[i].lighthouse then
				udp:sendto('bureaucrat', players[i].ip, players[i].port)
			     else
				udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
				players[i].unaffected = false
			     end
			  end
		       else
			  udp:send('boughtdos '..2, s.ip_address)
			  udp:send('played '..supply2[2].image..",".."G", s.ip_address)
			  udp:send('lastbought '..supply2[2].name, s.ip_address)
			  udp:send('bureaucrat', s.ip_address)
		       end
		    else
		       if p.id == 1 then
			  for i=2,#players do
			     if not players[i].unaffected and not players[i].lighthouse then
				udp:sendto('bureaucrat', players[i].ip, players[i].port)
			     else
				udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
				players[i].unaffected = false
			     end
			  end
		       else
			  udp:send('bureaucrat', s.ip_address)
		       end
		    end
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Caravan", type='action';
	image = 'caravan';
	cost = {gold=4, potion=0};
	duration = true;
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions+1
		 end;
	nextturn = function(s, p)
		      p:drawcard()
		   end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Cellar", type='action';
	image = 'cellar';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions + 1

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
		       local img = imgs['cellar']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    local discard_count = 0
		    if #p.hand > 0 then
		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p:discard(i)
				      discard_count = discard_count + 1
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
		    done_panel.name = "Done ("..discard_count..")"
		    done_panel.color_bg = color(.0,.6,.3)

		    function done_panel.onupdate(s)
		       done_panel.name = "Done ("..discard_count..")"
		    end

		    function done_panel.onclick(s, x, y, btn)
		       ui:remove(choice_panel)
		       p:drawcard(discard_count)
		       choosing = false
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(done_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Chancellor", type='action';
	image = 'chancellor';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
	            p.coins = p.coins + 2

		    choosing = true

		    choice_panel = panel:new(465, 50, 350, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 350, 30)
		    title_panel.name = "Choose"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(55, 40, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['chancellor']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    yes_panel = panel:new(50, 440, 100, 40)
		    yes_panel.name = "Yes"
		    yes_panel.color_bg = color(.0,.6,.3)

		    function yes_panel.onclick(s, x, y, btn)
		       p:deck_into_discard()
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    no_panel = panel:new(200, 440, 100, 40)
		    no_panel.name = "No"
		    no_panel.color_bg = color(.8,.2,.2)

		    function no_panel.onclick(s, x, y, btn)
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(yes_panel)
		    choice_panel:add(no_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Chapel", type='action';
	image = 'chapel';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
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
		       local img = imgs['chapel']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    local trash_count = 0
		    if #p.hand > 0 then
		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      if trash_count < 4 then
					 p:trash_card(i)
					 trash_count = trash_count + 1

					 if p.id == 1 then
					    play_area[#play_area+1] = c.image
					    play_area_info[#play_area_info+1] = "T"
					    for i=2,#players do
					       udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					    end
					 else
					    udp:send('played '..c.image..",".."T", s.ip_address)
					 end
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
		    done_panel.name = "Done ("..trash_count..")"
		    done_panel.color_bg = color(.0,.6,.3)

		    function done_panel.onupdate(s)
		       done_panel.name = "Done ("..trash_count..")"
		    end

		    function done_panel.onclick(s, x, y, btn)
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(done_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Conspirator", type='action';
	image = 'conspirator';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.coins = p.coins + 2

		    if p.action_count > 2 then
		       p:drawcard()
		       p.actions = p.actions + 1
		    end
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Copper", type='treasure';
	image = 'copper';
	cost = {gold=0, potion=0};
	worth = 1;
	onturn = function(s, p)
		    p:addCoins(s.worth + p.coppersmith)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Coppersmith", type='action';
	image = 'coppersmith';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.coppersmith = p.coppersmith + 1
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Council Room", type='action';
	image = 'councilroom';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard(4)
		    p.buys = p.buys + 1

		    if p.id == 1 then
		       for i=2,#players do
			  udp:sendto('draw 1', players[i].ip, players[i].port)
		       end
		    else
		       udp:send('drawallother 1', s.ip_address)
		    end
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Courtyard", type='action';
	image = 'courtyard';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    p:drawcard(3)

		    choosing = true

		    if next(p.hand) == nil then
		       choosing = false
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
		       local img = imgs['courtyard']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    if #p.hand > 0 then
		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p.deck[#p.deck+1] = table.remove(p.hand, i)
				      ui:remove(choice_panel)
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
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Crossroads", type='action';
	image = 'crossroads';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    local draw_count = 0
		    for i,v in ipairs(p.hand) do
		       if v.type == 'victory' or v.type == 'av' or v.type == 'tv' then
			  draw_count = draw_count + 1
		       end
		    end
		    p:drawcard(draw_count)
		    if not p.crossroads then
		       p.actions = p.actions + 3
		       p.crossroads = true
		    end
		 end;
	set = {'H'};
     }

--COMPLETE
addcard{name = "Curse", type='victory';
	image = 'curse';
	cost = {gold=0, potion=0};
	set = {'B'};
     }

--COMPLETE
addcard{name = "Cutpurse", type='attack';
	image = 'cutpurse';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.coins = p.coins + 2

		    if p.id == 1 then
		       for i=2,#players do
			  if not players[i].unaffected and not players[i].lighthouse then
			     udp:sendto('cutpurse', players[i].ip, players[i].port)
			  else
			     players[i].unaffected = false
			  end
		       end
		    else
		       udp:send('cutpurse', s.ip_address)
		    end
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Duchy", type='victory';
	image = 'duchy';
	cost = {gold=5, potion=0};
	set = {'B'};
     }

--COMPLETE
addcard{name = "Duke", type='victory';
	image = 'duke';
	cost = {gold=5, potion=0};
	set = {'I'};
     }

--COMPLETE
addcard{name = "Estate", type='victory';
	image = 'estate';
	cost = {gold=2, potion=0};
	set = {'B'};
     }

--COMPLETE
addcard{name = "Explorer", type='action';
	image = 'explorer';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    local found = false

		    for i,v in ipairs(p.hand) do
		       if v.name == "Province" then
			  found = true
			  choosing = true

			  choice_panel = panel:new(465, 50, 350, 500)
			  choice_panel.name = ""
			  choice_panel.color_bg = color(.2,.2,.2)

			  title_panel = panel:new(0, 0, 350, 30)
			  title_panel.name = "Reveal?"
			  title_panel.color_bg = color(.4,.4,.4)

			  card_panel = panel:new(55, 40, 240, 380)
			  card_panel.name = ""
			  card_panel.align = 'center'

			  function card_panel.ondraw(s)
			     local img = imgs['province']
			     love.graphics.draw(img, 0, 0, 0, .8, .8)
			  end

			  yes_panel = panel:new(50, 440, 100, 40)
			  yes_panel.name = "Yes"
			  yes_panel.color_bg = color(.0,.6,.3)

			  function yes_panel.onclick(s, x, y, btn)
			     if p.id == 1 then
				play_area[#play_area+1] = "province"
				play_area_info[#play_area_info+1] = "R"

				for i=2,#players do
				   udp:sendto("played province,".."R", players[i].ip, players[i].port)
				end
			     else
				udp:send("played province,".."R", s.ip_address)
			     end

			     if supply2_counts[3] > 0 then
				if p.id == 1 then
				   supply2_counts[3] = supply2_counts[3] - 1
				   play_area[#play_area+1] = supply2[3].image
				   play_area_info[#play_area_info+1] = "G"

				   for i=2,#players do
				      udp:sendto('boughtdos '..3, players[i].ip, players[i].port)
				   end

				   for i=2,#players do
				      udp:sendto('played '..supply2[3].image..",".."G", players[i].ip, players[i].port)
				   end

				   for i=2,#players do
				      udp:sendto('lastbought '..supply2[3].name, players[i].ip, players[i].port)
				   end
				else
				   udp:send('boughtdos '..3, s.ip_address)
				   udp:send('played '..supply2[3].image..",".."G", s.ip_address)
				   udp:send('lastbought '..supply2[3].name, s.ip_address)
				end
				p.hand[#p.hand+1] = supply2[3]
				table.sort(p.hand, function(a,b) return a.name<b.name end)
			     end

			     ui:remove(choice_panel)
			     choosing = false
			  end

			  no_panel = panel:new(200, 440, 100, 40)
			  no_panel.name = "No"
			  no_panel.color_bg = color(.8,.2,.2)

			  function no_panel.onclick(s, x, y, btn)
			     if supply2_counts[2] > 0 then
				if p.id == 1 then
				   supply2_counts[2] = supply2_counts[2] - 1
				   play_area[#play_area+1] = supply2[2].image
				   play_area_info[#play_area_info+1] = "G"

				   for i=2,#players do
				      udp:sendto('boughtdos '..2, players[i].ip, players[i].port)
				   end

				   for i=2,#players do
				      udp:sendto('played '..supply2[2].image..",".."G", players[i].ip, players[i].port)
				   end

				   for i=2,#players do
				      udp:sendto('lastbought '..supply2[2].name, players[i].ip, players[i].port)
				   end
				else
				   udp:send('boughtdos '..2, s.ip_address)
				   udp:send('played '..supply2[2].image..",".."G", s.ip_address)
				   udp:send('lastbought '..supply2[2].name, s.ip_address)
				end
				p.hand[#p.hand+1] = supply2[2]
				table.sort(p.hand, function(a,b) return a.name<b.name end)
			     end
			     ui:remove(choice_panel)
			     choosing = false
			  end

			  choice_panel:add(title_panel)
			  choice_panel:add(card_panel)
			  choice_panel:add(yes_panel)
			  choice_panel:add(no_panel)
			  ui:add(choice_panel)
			  break
		       end
		    end

		    if not found then
		       if supply2_counts[2] > 0 then
			  if p.id == 1 then
			     supply2_counts[2] = supply2_counts[2] - 1
			     play_area[#play_area+1] = supply2[2].image
			     play_area_info[#play_area_info+1] = "G"

			     for i=2,#players do
				udp:sendto('boughtdos '..2, players[i].ip, players[i].port)
			     end

			     for i=2,#players do
				udp:sendto('played '..supply2[2].image..",".."G", players[i].ip, players[i].port)
			     end

			     for i=2,#players do
				udp:sendto('lastbought '..supply2[2].name, players[i].ip, players[i].port)
			     end
			  else
			     udp:send('boughtdos '..2, s.ip_address)
			     udp:send('played '..supply2[2].image..",".."G", s.ip_address)
			     udp:send('lastbought '..supply2[2].name, s.ip_address)
			  end
			  p.hand[#p.hand+1] = supply2[2]
			  table.sort(p.hand, function(a,b) return a.name<b.name end)
		       end
		    end
		 end;
	set = {'S'};
     }

--COMPLETE
--BUGGY EXTRA CURSE
addcard{name = "Familiar", type='attack';
	image = 'familiar';
	cost = {gold=3, potion=1};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1

		    local witch_count = supply2_counts[8]

		    if p.id == 1 then
		       for i=2,#players do
			  if not players[i].unaffected and not players[i].lighthouse then
			     if witch_count == 0 then
				return
			     end
			     witch_count = witch_count - 1
			     udp:sendto('witch', players[i].ip, players[i].port)
			  else
			     players[i].unaffected = false
			  end
		       end
		    else
		       udp:send('witch', s.ip_address)
		    end
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Farming Village", type='action';
	image = 'farmingvillage';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions+2

		    local c
		    local found = false
		    while true do
		       c = p:revealtop()

		       if c == nil then
			  break
		       end

		       if c.type == 'treasure' or c.type == 'tv' or c.type == 'action' or c.type == 'reaction' or c.type == 'attack' or c.type == 'av' then
			  p:drawcard()
			  found = true
		       else
			  p.discard_pile[#p.discard_pile+1] = table.remove(p.deck, #p.deck)
		       end

		       if p.id == 1 then
			  play_area[#play_area+1] = c.image
			  play_area_info[#play_area_info+1] = "R"

			  for i=2,#players do
			     udp:sendto('played '..c.image..",".."R", players[i].ip, players[i].port)
			  end
		       else
			  udp:send('played '..c.image..",".."R", s.ip_address)
		       end

		       if found then
			  table.sort(p.hand, function(a,b) return a.name<b.name end)
			  break
		       end
		    end
		 end;
	set = {'C'};
     }

--COMPLETE
addcard{name = "Feast", type='action';
	image = 'feast';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    gain = 5
		    gaining = true
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Festival", type='action';
	image = 'festival';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions+2
		    p.buys = p.buys+1
		    p.coins = p.coins+2
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Fishing Village", type='action';
	image = 'fishingvillage';
	cost = {gold=3, potion=0};
	duration = true;
	onturn = function(s, p)
		    p.actions = p.actions+2
		    p.coins = p.coins+1
		 end;
	nextturn = function(s, p)
		      p.actions = p.actions + 1
		      p.coins = p.coins + 1
		   end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Gardens", type='victory';
	image = 'gardens';
	cost = {gold=4, potion=0};
	set = {'B'};
     }

--COMPLETE
addcard{name = "Gold", type='treasure';
	image = 'gold';
	cost = {gold=6, potion=0};
	worth = 3;
	onturn = function(s, p)
		    p:addCoins(s.worth)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Great Hall", type='av';
	image = 'greathall';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Harem", type='tv';
	image = 'harem';
	cost = {gold=6, potion=0};
	onturn = function(s, p)
		    p.coins = p.coins + 2
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Haven", type='action';
	image = 'haven';
	cost = {gold=2, potion=0};
	duration = true;
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1

		    if next(p.hand) ~= nil then
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
			  local img = imgs['haven']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       local tmp

		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p.haven[#p.haven+1] = table.remove(p.hand, i)
				      ui:remove(choice_panel)
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

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       ui:add(choice_panel)
		    end
		 end;
	nextturn = function(s, p)
		      p.hand[#p.hand+1] = table.remove(p.haven, #p.haven)
		      table.sort(p.hand, function(a,b) return a.name<b.name end)
		   end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Herbalist", type='action';
	image = 'herbalist';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    p.buys = p.buys + 1
		    p.coins = p.coins + 1
		 end;
	onend = function(s, p, index)
		   local choices = {}

		   p.discard_pile[#p.discard_pile+1] = table.remove(p.played, index)

		   for i=#p.played, 1, -1 do
		      if p.played[i].type == 'treasure' or p.played[i].type == 'tv' then
			 choices[#choices+1] = table.remove(p.played, i)
		      end
		   end

		   if next(choices) ~= nil then
		      choosing = true

		      choice_panel = panel:new(140, 50, 1000, 500)
		      choice_panel.name = ""
		      choice_panel.color_bg = color(.2,.2,.2)

		      title_panel = panel:new(0, 0, 1000, 30)
		      title_panel.name = "Put Card on Top of Deck"
		      title_panel.color_bg = color(.4,.4,.4)

		      card_panel = panel:new(30, 60, 240, 380)
		      card_panel.name = ""
		      card_panel.align = 'center'

		      function card_panel.ondraw(s)
			 local img = imgs['herbalist']
			 love.graphics.draw(img, 0, 0, 0, .8, .8)
		      end

		      local tmp

		      for i=0,6 do
			 for j=0,2 do
			    tmp = panel:new(i*90+285, j*124+66, 75, 120)
			    tmp.name = "Choice Card#"..(i+1)+(j*7)
			    tmp.align = 'center'
			    function tmp:card() return choices[(i+1)+(j*7)], (i+1)+(j*7) end

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
				     p.deck[#p.deck+1] = table.remove(choices, i)
				     while #choices > 0 do
					p.played[#p.played+1] = table.remove(choices, 1)
				     end
				     ui:remove(choice_panel)
				     choosing = false
				     ui:click(62, 693, 'l')
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
		      done_panel.name = "Done"
		      done_panel.color_bg = color(.0,.6,.3)

		      function done_panel.onclick(s, x, y, btn)
			 while #choices > 0 do
			    p.played[#p.played+1] = table.remove(choices, 1)
			 end
			 ui:remove(choice_panel)
			 choosing = false
			 ui:click(62, 693, 'l')
		      end

		      choice_panel:add(title_panel)
		      choice_panel:add(card_panel)
		      choice_panel:add(done_panel)
		      ui:add(choice_panel)
		   end
		end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Hunting Party", type='action';
	image = 'huntingparty';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1

		    local c
		    while true do
		       c = p:revealtop()
		       if c == nil then
			  break
		       end
		       for i,v in ipairs(p.hand) do
			  if c.name == v.name then
			     p.discard_pile[#p.discard_pile+1] = table.remove(p.deck, #p.deck)
			     break
			  end
		       end
		       p:drawcard()
		       break
		    end
		 end;
	set = {'C'};
     }

--COMPLETE
addcard{name = "Ironworks", type='action';
	image = 'ironworks';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    gain = 4
		    gaining = true
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Island", type='av';
	image = 'island';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    if next(p.hand) ~= nil then
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
			  local img = imgs['island']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       local tmp

		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "R"

					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."R", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."R", s.ip_address)
				      end
				      p.island[#p.island+1] = table.remove(p.hand, i)
				      ui:remove(choice_panel)
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

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       ui:add(choice_panel)
		    end
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Laboratory", type='action';
	image = 'laboratory';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard(2)
		    p.actions = p.actions+1
		 end;
	set = {'B'};
     }

--BUGGY?
addcard{name = "Library", type='action';
	image = 'library';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    choosing = true

		    local num_to_draw = 7 - #p.hand
		    local draw_list = {}

		    if num_to_draw > 0 then
		       if next(p.deck) == nil then
			  shuffle(p.discard_pile)
			  p.deck = p.discard_pile
			  p.discard_pile = {}
		       end
		       draw_list[#draw_list+1] = p.deck[#p.deck]
		       p.deck[#p.deck] = nil
		       num_to_draw = num_to_draw - 1
		    else
		       ui:remove(choice_panel)
		       choosing = false
		       return
		    end

		    choice_panel = panel:new(465, 50, 350, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 350, 30)
		    title_panel.name = "Discard?"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(55, 40, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       if draw_list[#draw_list] then
			  if draw_list[#draw_list].type == 'action' or draw_list[#draw_list].type == 'attack' or draw_list[#draw_list].type == 'reaction' or draw_list[#draw_list].type == 'av' then
			     local img = imgs[draw_list[#draw_list].image]
			     love.graphics.draw(img, 0, 0, 0, .8, .8)
			  else
			     if num_to_draw > 0 then
				if next(p.deck) == nil then
				   shuffle(p.discard_pile)
				   p.deck = p.discard_pile
				   p.discard_pile = {}
				end
				draw_list[#draw_list+1] = p.deck[#p.deck]
				p.deck[#p.deck] = nil
				num_to_draw = num_to_draw - 1
			     else
				while #draw_list > 0 do
				   p.hand[#p.hand+1] = table.remove(draw_list, 1)
				end
				table.sort(p.hand, function(a,b) return a.name<b.name end)
				ui:remove(choice_panel)
				choosing = false
			     end
			  end
		       else
			  while #draw_list > 0 do
			     p.hand[#p.hand+1] = table.remove(draw_list, 1)
			  end
			  table.sort(p.hand, function(a,b) return a.name<b.name end)
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    yes_panel = panel:new(50, 440, 100, 40)
		    yes_panel.name = "Yes"
		    yes_panel.color_bg = color(.0,.6,.3)

		    function yes_panel.onclick(s, x, y, btn)
		       p.discard_pile[#p.discard_pile+1] = table.remove(draw_list, #draw_list)
		       if next(p.deck) == nil then
			  shuffle(p.discard_pile)
			  p.deck = p.discard_pile
			  p.discard_pile = {}
		       end
		       draw_list[#draw_list+1] = p.deck[#p.deck]
		       p.deck[#p.deck] = nil
		    end

		    no_panel = panel:new(200, 440, 100, 40)
		    no_panel.name = "No"
		    no_panel.color_bg = color(.8,.2,.2)

		    function no_panel.onclick(s, x, y, btn)
		       if next(p.deck) == nil then
			  shuffle(p.discard_pile)
			  p.deck = p.discard_pile
			  p.discard_pile = {}
		       end
		       draw_list[#draw_list+1] = p.deck[#p.deck]
		       p.deck[#p.deck] = nil
		       num_to_draw = num_to_draw - 1
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(yes_panel)
		    choice_panel:add(no_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Lighthouse", type='action';
	image = 'lighthouse';
	cost = {gold=2, potion=0};
	duration = true;
	onturn = function(s, p)
		    p.actions = p.actions + 1
		    p.coins = p.coins + 1
		    if p.id == 1 then
		       players[1].lighthouse = true
		    else
		       udp:send("lighthouse on "..p.id, s.ip_address)
		    end
		 end;
	nextturn = function(s, p)
		      p.coins = p.coins + 1
		      if p.id == 1 then
			 players[1].lighthouse = false
		      else
			 udp:send("lighthouse off "..p.id, s.ip_address)
		      end
		   end;
	set = {'S'};
     }

addcard{name = "Lookout", type='action';
	image = 'lookout';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions+1

		    local choices = {}
		    local c
		    local count = 1

		    for i=0,2 do
		       c = p:revealtop()
		       if not c then
			  break
		       else
			  choices[#choices+1] = table.remove(p.deck, #p.deck)
		       end
		    end

		    if next(choices) ~= nil then
		       choosing = true

		       choice_panel = panel:new(140, 50, 1000, 500)
		       choice_panel.name = ""
		       choice_panel.color_bg = color(.2,.2,.2)

		       title_panel = panel:new(0, 0, 1000, 30)
		       title_panel.name = "Trash One"
		       title_panel.color_bg = color(.4,.4,.4)

		       card_panel = panel:new(30, 60, 240, 380)
		       card_panel.name = ""
		       card_panel.align = 'center'

		       function card_panel.ondraw(s)
			  local img = imgs['lookout']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       local tmp

		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return choices[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      if count == 1 then
					 count = count + 1
					 p.trash[#p.trash+1] = table.remove(choices, i)
					 title_panel.name = "Discard One"
				      elseif count == 2 then
					 p.discard_pile[#p.discard_pile+1] = table.remove(choices, i)
					 if next(choices) ~= nil then
					    p.deck[#p.deck+1] = table.remove(choices, 1)
					 end
				      end

				      if next(choices) == nil then
					 ui:remove(choice_panel)
					 choosing = false
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

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       ui:add(choice_panel)
		    end
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Market", type='action';
	image = 'market';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions+1
		    p.buys = p.buys+1
		    p.coins = p.coins+1
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Menagerie", type='action';
	image = 'menagerie';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions + 1

		    local last_seen = ""
		    table.sort(p.hand, function(a,b) return a.name<b.name end)
		    for i,v in ipairs(p.hand) do
		       if last_seen == v.name then
			  p:drawcard()
			  return
		       else
			  last_seen = v.name
		       end
		    end
		    p:drawcard(3)
		 end;
	set = {'C'};
     }

--COMPLETE
addcard{name = "Merchant Ship", type='action';
	image = 'merchantship';
	cost = {gold=5, potion=0};
	duration = true;
	onturn = function(s, p)
		    p.coins = p.coins+1
		 end;
	nextturn = function(s, p)
		      p.coins = p.coins + 2
		   end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Militia", type='attack';
	image = 'militia';
	cost = {gold=4, potion=0};
	requireswait = true;
	onturn = function(s, p)
		    p.coins = p.coins+2
		    waiting = true

		    if p.id == 1 then
		       for i=2,#players do
			  if not players[i].unaffected and not players[i].lighthouse then
			     udp:sendto('militia', players[i].ip, players[i].port)
			  else
			     udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
			     players[i].unaffected = false
			  end
		       end
		    else
		       udp:send('militia', s.ip_address)
		    end
                 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Mine", type='action';
	image = 'mine';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    choosing = true

		    local choices = {}
		    for i,v in ipairs(p.hand) do
		       if v.type == 'treasure' or v.type == 'tv' then
			  choices[#choices+1] = {card = v, hand_index = i}
		       end
		    end

		    if next(choices) == nil then
		       choosing = false
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
		       local img = imgs['mine']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    if #p.hand > 0 then
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
				      p:trash_card(i)

				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "T"
					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."T", s.ip_address)
				      end

				      ui:remove(choice_panel)
				      choosing = false

				      gain_type = 'treasure'
				      gain_type2 = 'tv'
				      gain = c.cost.gold + 3
				      gaining = true
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

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Mining Village", type='action';
	image = 'miningvillage';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 2

		    choosing = true

		    choice_panel = panel:new(465, 50, 350, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 350, 30)
		    title_panel.name = "Choose"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(55, 40, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['miningvillage']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    yes_panel = panel:new(50, 440, 100, 40)
		    yes_panel.name = "Yes"
		    yes_panel.color_bg = color(.0,.6,.3)

		    function yes_panel.onclick(s, x, y, btn)
		       p.trash[#p.trash+1] = table.remove(p.played, #p.played)
		       p.coins = p.coins + 2
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    no_panel = panel:new(200, 440, 100, 40)
		    no_panel.name = "No"
		    no_panel.color_bg = color(.8,.2,.2)

		    function no_panel.onclick(s, x, y, btn)
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(yes_panel)
		    choice_panel:add(no_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Minion", type='attack';
	image = 'minion';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions + 1

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
		       local img = imgs['minion']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    c1_panel = panel:new(285, 66, 300, 40)
		    c1_panel.name = "+2 Coins"

		    function c1_panel.onclick(s, x, y, btn)
		       if btn == 'l' then
			  p.coins = p.coins + 2
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    c2_panel = panel:new(285, 126, 300, 40)
		    c2_panel.name = "Discard Hand +4 Cards Effect"

		    function c2_panel.onclick(s, x, y, btn)
		       if btn == 'l' then

			  for i=#p.hand, 1, -1 do
			     p:discard(i)
			  end
			  p:drawcard(4)

			  if p.id == 1 then
			     for i=2,#players do
				if not players[i].unaffected and not players[i].lighthouse then
				   udp:sendto('minion', players[i].ip, players[i].port)
				else
				   players[i].unaffected = false
				end
			     end
			  else
			     udp:send('minion', s.ip_address)
			  end
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    choice_panel:add(c1_panel)
		    choice_panel:add(c2_panel)
		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Moat", type='reaction';
	image = 'moat';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    p:drawcard(2)
		 end;
	reaction = function(s, p)
		      choosing = true

		      choice_panel = panel:new(465, 50, 350, 500)
		      choice_panel.name = ""
		      choice_panel.color_bg = color(.2,.2,.2)

		      title_panel = panel:new(0, 0, 350, 30)
		      title_panel.name = "React"
		      title_panel.color_bg = color(.4,.4,.4)

		      card_panel = panel:new(55, 40, 240, 380)
		      card_panel.name = ""
		      card_panel.align = 'center'

		      function card_panel.ondraw(s)
			 local img = imgs['moat']
			 love.graphics.draw(img, 0, 0, 0, .8, .8)
		      end

		      yes_panel = panel:new(50, 440, 100, 40)
		      yes_panel.name = "Yes"
		      yes_panel.color_bg = color(.0,.6,.3)

		      function yes_panel.onclick(s, x, y, btn)

			 if p.id == 1 then
			    players[1].unaffected = true
			    play_area[#play_area+1] = "moat"
			    play_area_info[#play_area_info+1] = "R"

			    for i=2,#players do
			       udp:sendto("played moat,".."R", players[i].ip, players[i].port)
			    end
			    udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
			 else
			    --BUG? added s.ip_address
			    udp:send("unaffected "..p.id, s.ip_address)
			    udp:send("played moat,".."R", s.ip_address)
			    udp:send("donechoosing", s.ip_address)
			 end

			 ui:remove(choice_panel)
			 choosing = false
		      end

		      no_panel = panel:new(200, 440, 100, 40)
		      no_panel.name = "No"
		      no_panel.color_bg = color(.8,.2,.2)

		      function no_panel.onclick(s, x, y, btn)
			 if p.id == 1 then
			    udp:sendto('donechoosing', players[active_player].ip, players[active_player].port)
			 else
			    udp:send("donechoosing", s.ip_address)
			 end

			 ui:remove(choice_panel)
			 choosing = false
		      end

		      choice_panel:add(title_panel)
		      choice_panel:add(card_panel)
		      choice_panel:add(yes_panel)
		      choice_panel:add(no_panel)
		      ui:add(choice_panel)
		   end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Moneylender", type='action';
	image = 'moneylender';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    choosing = true

		    local choices = {}
		    for i,v in ipairs(p.hand) do
		       if v.name == 'Copper' then
			  choices[#choices+1] = {card = v, hand_index = i}
		       end
		    end

		    if next(choices) == nil then
		       choosing = false
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
		       local img = imgs['moneylender']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    if #p.hand > 0 then
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
				      p:trash_card(i)

				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "T"
					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."T", s.ip_address)
				      end

				      ui:remove(choice_panel)
				      choosing = false

				      p.coins = p.coins + 3
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

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Navigator", type='action';
	image = 'navigator';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.coins = p.coins + 2

		    local choices = {}
		    local c
		    local putting_back = false

		    for i=0,4 do
		       c = p:revealtop()
		       if not c then
			  break
		       else
			  choices[#choices+1] = table.remove(p.deck, #p.deck)
		       end
		    end

		    if next(choices) ~= nil then
		       choosing = true

		       choice_panel = panel:new(140, 50, 1000, 500)
		       choice_panel.name = ""
		       choice_panel.color_bg = color(.2,.2,.2)

		       title_panel = panel:new(0, 0, 1000, 30)
		       title_panel.name = "Put Cards on Top of Deck"
		       title_panel.color_bg = color(.4,.4,.4)

		       card_panel = panel:new(30, 60, 240, 380)
		       card_panel.name = ""
		       card_panel.align = 'center'

		       function card_panel.ondraw(s)
			  local img = imgs['navigator']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       local tmp

		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return choices[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      putting_back = true
				      p.deck[#p.deck+1] = table.remove(choices, i)
				      if next(choices) == nil then
					 ui:remove(choice_panel)
					 choosing = false
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
		       done_panel.name = "Discard All"
		       done_panel.color_bg = color(.0,.6,.3)

		       function done_panel.onupdate(s)
			  if putting_back then
			     done_panel.color_bg = color(.8,.2,.2)
			  end
		       end

		       function done_panel.onclick(s, x, y, btn)
			  if btn == 'l' and not putting_back then
			     while #choices > 0 do
				p.discard_pile[#p.discard_pile+1] = table.remove(choices, i)
			     end
			     ui:remove(choice_panel)
			     choosing = false
			  end
		       end

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       choice_panel:add(done_panel)
		       ui:add(choice_panel)
		    end
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Nobles", type='av';
	image = 'nobles';
	cost = {gold=6, potion=0};
	onturn = function(s, p)
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
		       local img = imgs['nobles']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    c1_panel = panel:new(285, 66, 300, 40)
		    c1_panel.name = "+3 Cards"

		    function c1_panel.onclick(s, x, y, btn)
		       if btn == 'l' then
			  p:drawcard(3)
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    c2_panel = panel:new(285, 126, 300, 40)
		    c2_panel.name = "+2 Actions"

		    function c2_panel.onclick(s, x, y, btn)
		       if btn == 'l' then
			  p.actions = p.actions + 2
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    choice_panel:add(c1_panel)
		    choice_panel:add(c2_panel)
		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Outpost", type='action';
	image = 'outpost';
	cost = {gold=5, potion=0};
	duration = true;
	onturn = function(s, p)
		    if not p.outpost_block then
		       p.outpost = true
		    end
		 end;
	nextturn = function(s, p)
		      p.outpost = false
		   end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Pawn", type='action';
	image = 'pawn';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    choosing = true

		    local picked = 0
		    local selections = {false, false, false, false}

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
		       local img = imgs['pawn']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    c1_panel = panel:new(285, 66, 300, 40)
		    c1_panel.name = "+1 Card"

		    function c1_panel.onclick(s, x, y, btn)
		       if btn == 'l' and picked < 2 and not selections[1] then
			  picked = picked + 1
			  selections[1] = true
			  c1_panel.color_bg = color(.0,.6,.3)
		       end
		    end

		    c2_panel = panel:new(285, 126, 300, 40)
		    c2_panel.name = "+1 Action"

		    function c2_panel.onclick(s, x, y, btn)
		       if btn == 'l' and picked < 2 and not selections[2] then
			  picked = picked + 1
			  selections[2] = true
			  c2_panel.color_bg = color(.0,.6,.3)
		       end
		    end

		    c3_panel = panel:new(285, 186, 300, 40)
		    c3_panel.name = "+1 Buy"

		    function c3_panel.onclick(s, x, y, btn)
		       if btn == 'l' and picked < 2 and not selections[3] then
			  picked = picked + 1
			  selections[3] = true
			  c3_panel.color_bg = color(.0,.6,.3)
		       end
		    end

		    c4_panel = panel:new(285, 246, 300, 40)
		    c4_panel.name = "+1 Coin"

		    function c4_panel.onclick(s, x, y, btn)
		       if btn == 'l' and picked < 2 and not selections[4] then
			  picked = picked + 1
			  selections[4] = true
			  c4_panel.color_bg = color(.0,.6,.3)
		       end
		    end

		    done_panel = panel:new(258, 450, 100, 40)
		    done_panel.name = "Done"
		    done_panel.color_bg = color(.0,.6,.3)

		    function done_panel.onclick(s, x, y, btn)
		       if picked == 2 then
			  if selections[1] then
			     p:drawcard()
			  end
			  if selections[2] then
			     p.actions = p.actions + 1
			  end
			  if selections[3] then
			     p.buys = p.buys + 1
			  end
			  if selections[4] then
			     p.coins = p.coins + 1
			  end
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    choice_panel:add(c1_panel)
		    choice_panel:add(c2_panel)
		    choice_panel:add(c3_panel)
		    choice_panel:add(c4_panel)
		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(done_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Pearl Diver", type='action';
	image = 'pearldiver';
	cost = {gold=2, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1

		    if #p.deck == 0 then
		       shuffle(p.discard_pile)
		       p.deck = p.discard_pile
		       p.discard_pile = {}
		       if #p.deck == 0 then
			  return
		       end
		    end

		    choosing = true

		    choice_panel = panel:new(465, 50, 350, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 350, 30)
		    title_panel.name = "Put on top?"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(55, 40, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs[p.deck[1].image]
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    yes_panel = panel:new(50, 440, 100, 40)
		    yes_panel.name = "Yes"
		    yes_panel.color_bg = color(.0,.6,.3)

		    function yes_panel.onclick(s, x, y, btn)
		       local c = table.remove(p.deck, 1)
		       p.deck[#p.deck+1] = c
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    no_panel = panel:new(200, 440, 100, 40)
		    no_panel.name = "No"
		    no_panel.color_bg = color(.8,.2,.2)

		    function no_panel.onclick(s, x, y, btn)
		       ui:remove(choice_panel)
		       choosing = false
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(yes_panel)
		    choice_panel:add(no_panel)
		    ui:add(choice_panel)
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Philosophers Stone", type='treasure';
	image = 'philosophersstone';
	cost = {gold=3, potion=1};
	onturn = function(s, p)
		    p.coins = p.coins + math.floor((#p.deck + #p.discard_pile) / 5)
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Province", type='victory';
	image = 'province';
	cost = {gold=8, potion=0};
	set = {'B'};
     }

--COMPLETE
addcard{name = "Potion", type='treasure';
	image = 'potion';
	cost = {gold=4, potion=0};
	potion = 1;
	onturn = function(s, p)
		    p.potions = p.potions + 1
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Remodel", type='action';
	image = 'remodel';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    choosing = true

		    if next(p.hand) == nil then
		       choosing = false
		       return
		    end

		    choice_panel = panel:new(140, 50, 1000, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 1000, 30)
		    title_panel.name = "Trash a Card"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(30, 60, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['remodel']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    if #p.hand > 0 then
		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p:trash_card(i)

				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "T"
					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."T", s.ip_address)
				      end

				      ui:remove(choice_panel)
				      choosing = false

				      gain = c.cost.gold + 2
				      gaining = true
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

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Salvager", type='action';
	image = 'salvager';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.buys = p.buys + 1

		    choosing = true

		    if next(p.hand) == nil then
		       choosing = false
		       return
		    end

		    choice_panel = panel:new(140, 50, 1000, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 1000, 30)
		    title_panel.name = "Trash"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(30, 60, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['salvager']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    for i=0,6 do
		       for j=0,2 do
			  tmp = panel:new(i*90+285, j*124+66, 75, 120)
			  tmp.name = "Choice Card#"..(i+1)+(j*7)
			  tmp.align = 'center'
			  function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				   p:trash_card(i)

				   if p.id == 1 then
				      play_area[#play_area+1] = c.image
				      play_area_info[#play_area_info+1] = "T"
				      for i=2,#players do
					 udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
				      end
				   else
				      udp:send('played '..c.image..",".."T", s.ip_address)
				   end

				   ui:remove(choice_panel)
				   choosing = false

				   p.coins = p.coins + c.cost.gold
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

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Scout", type='action';
	image = 'scout';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions + 1

		    local choices = {}
		    local c

		    for i=0,3 do
		       c = p:revealtop()
		       if not c then
			  break
		       else
			  if c.type == 'victory' or c.type == 'av' or c.type == 'tv' then
			     p.hand[#p.hand+1] = table.remove(p.deck, #p.deck)
			     table.sort(p.hand, function(a,b) return a.name<b.name end)
			  else
			     choices[#choices+1] = table.remove(p.deck, #p.deck)
			  end
		       end
		    end

		    if next(choices) ~= nil then
		       choosing = true

		       choice_panel = panel:new(140, 50, 1000, 500)
		       choice_panel.name = ""
		       choice_panel.color_bg = color(.2,.2,.2)

		       title_panel = panel:new(0, 0, 1000, 30)
		       title_panel.name = "Put Cards on Top of Deck"
		       title_panel.color_bg = color(.4,.4,.4)

		       card_panel = panel:new(30, 60, 240, 380)
		       card_panel.name = ""
		       card_panel.align = 'center'

		       function card_panel.ondraw(s)
			  local img = imgs['scout']
			  love.graphics.draw(img, 0, 0, 0, .8, .8)
		       end

		       local tmp

		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return choices[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p.deck[#p.deck+1] = table.remove(choices, i)
				      if next(choices) == nil then
					 ui:remove(choice_panel)
					 choosing = false
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

		       choice_panel:add(title_panel)
		       choice_panel:add(card_panel)
		       ui:add(choice_panel)
		    end
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Shanty Town", type='action';
	image = 'shantytown';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p.actions = p.actions + 2

		    for i,v in ipairs(p.hand) do
		       if v.type == 'action' or v.type == 'reaction' or v.type == 'attack' or v.type == 'av' then
			  return
		       end
		    end

		    p:drawcard(2)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Silver", type='treasure';
	image = 'silver';
	cost = {gold=3, potion=0};
	worth = 2;
	onturn = function(s, p)
		    p:addCoins(s.worth)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Smithy", type='action';
	image = 'smithy';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p:drawcard(3)
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Spy", type='attack';
	image = 'spy';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p:drawcard(1)
		    p.actions = p.actions + 1

		    if p.id == 1 then
		       local c = players[1]:revealtop()
		       if c then
			  play_area[#play_area+1] = c.image
			  play_area_info[#play_area_info+1] = "1"
			  for i=2,#players do
			     udp:sendto('played '..c.image..",".."1", players[i].ip, players[i].port)
			  end
			  revealed[1] = c.image
		       else
			  revealed[1] = 'back'
		       end

		       for i=2,#players do
			  if not players[i].unaffected and not players[i].lighthouse then
			     udp:sendto('spy', players[i].ip, players[i].port)
			  else
			     revealed[i] = 'back'
			     players[i].unaffected = false
			     udp:sendto('donespying', players[1].ip, players[1].port)
			  end
		       end
		    else
		       udp:send('spy', s.ip_address)
		    end
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Steward", type='action';
	image = 'steward';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
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
		       local img = imgs['steward']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    c1_panel = panel:new(285, 66, 300, 40)
		    c1_panel.name = "+2 Cards"

		    function c1_panel.onclick(s, x, y, btn)
		       if btn == 'l' then
			  p:drawcard(2)
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    c2_panel = panel:new(285, 126, 300, 40)
		    c2_panel.name = "+2 Coins"

		    function c2_panel.onclick(s, x, y, btn)
		       if btn == 'l' then
			  p.coins = p.coins + 2
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    c3_panel = panel:new(285, 186, 300, 40)
		    c3_panel.name = "Trash 2"

		    function c3_panel.onclick(s, x, y, btn)
		       if btn == 'l' then
			  ui:remove(choice_panel)

			  choice_panel = panel:new(140, 50, 1000, 500)
			  choice_panel.name = ""
			  choice_panel.color_bg = color(.2,.2,.2)

			  title_panel = panel:new(0, 0, 1000, 30)
			  title_panel.name = "Trash 2"
			  title_panel.color_bg = color(.4,.4,.4)

			  card_panel = panel:new(30, 60, 240, 380)
			  card_panel.name = ""
			  card_panel.align = 'center'

			  function card_panel.ondraw(s)
			     local img = imgs['steward']
			     love.graphics.draw(img, 0, 0, 0, .8, .8)
			  end

			  local tmp
			  local trash_count = 0
			  if #p.hand > 0 then
			     for i=0,6 do
				for j=0,2 do
				   tmp = panel:new(i*90+285, j*124+66, 75, 120)
				   tmp.name = "Choice Card#"..(i+1)+(j*7)
				   tmp.align = 'center'
				   function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
					    if trash_count < 2 then
					       p:trash_card(i)
					       trash_count = trash_count + 1

					       if p.id == 1 then
						  play_area[#play_area+1] = c.image
						  play_area_info[#play_area_info+1] = "T"
						  for i=2,#players do
						     udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
						  end
					       else
						  udp:send('played '..c.image..",".."T", s.ip_address)
					       end
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
			  done_panel.name = "Done ("..trash_count..")"
			  done_panel.color_bg = color(.8,.2,.2)

			  function done_panel.onupdate(s)
			     done_panel.name = "Done ("..trash_count..")"
			     if trash_count == 2 or #p.hand == 0 then
				done_panel.color_bg = color(.0,.6,.3)
			     end
			  end

			  function done_panel.onclick(s, x, y, btn)
			     if trash_count == 2 or #p.hand == 0 then
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

		    choice_panel:add(c1_panel)
		    choice_panel:add(c2_panel)
		    choice_panel:add(c3_panel)
		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Tactician", type='action';
	image = 'tactician';
	cost = {gold=5, potion=0};
	duration = true;
	onturn = function(s, p)
		    if #p.hand > 0 then
		       while #p.hand > 0 do
			  p.discard_pile[#p.discard_pile + 1] = table.remove(p.hand, 1)
		       end
		       p.tactician = p.tactician + 1
		    end
		 end;
	nextturn = function(s, p)
		      if p.tactician > 0 then
			 p:drawcard(5)
			 p.buys = p.buys + 1
			 p.actions = p.actions + 1
			 p.tactician = p.tactician - 1
		      end
		   end;
	set = {'S'};
     }

--addcard{name = "Thief", type='attack';
--	image = 'thief';
--	cost = {gold=4, potion=0};
--	set = {'B'};
--     }

--IN PROGRESS
--addcard{name = "Throne Room", type='action';
--	image = 'throneroom';
--	cost = {gold=4, potion=0};
--	onturn = function(s, p)
--		    choosing = true
--
--		    choices = {}
--
--		    for i,v in ipairs(p.hand) do
--		       if v.type == 'action' or v.type == 'attack' or v.type == 'reaction' then
--			  choices[#choices+1] = {card = v, hand_index = i}
--		       end
--		    end
--
--		    if next(choices) == nil then
--		       choosing = false
--		       return
--		    end
--
--		    choice_panel = panel:new(140, 50, 1000, 500)
--		    choice_panel.name = ""
--		    choice_panel.color_bg = color(.2,.2,.2)
--
--		    title_panel = panel:new(0, 0, 1000, 30)
--		    title_panel.name = "Choose"
--		    title_panel.color_bg = color(.4,.4,.4)
--
--		    card_panel = panel:new(30, 60, 240, 380)
--		    card_panel.name = ""
--		    card_panel.align = 'center'
--
--		    function card_panel.ondraw(s)
--		       local img = imgs['throneroom']
--		       love.graphics.draw(img, 0, 0, 0, .8, .8)
--		    end
--
--		    local tmp
--		    for i=0,6 do
--		       for j=0,2 do
--			  tmp = panel:new(i*90+285, j*124+66, 75, 120)
--			  tmp.name = "Choice Card#"..(i+1)+(j*7)
--			  tmp.align = 'center'
--			  function tmp:card()
--			     if choices[(i+1)+(j*7)] then
--				return choices[(i+1)+(j*7)].card, choices[(i+1)+(j*7)].hand_index
--			     else
--				return nil
--			     end
--			  end
--
--			  function tmp.ondraw(s)
--			     if s:card() then
--				local img = imgs[s:card().image]
--				love.graphics.draw(img, 0, 0, 0, .25, .25)
--			     end
--			  end
--
--			  function tmp.onclick(s, x, y, btn)
--			     if s:card() then
--				local c, i = s:card()
--				if btn == 'l' then
--				   for i=0,1 do
--				      if p.id == 1 then
--					 play_area[#play_area+1] = c.image
--					 play_area_info[#play_area_info+1] = "P"
--
--					 for i=2,#players do
--					    udp:sendto('played '..c.image..",".."P", players[i].ip, players[i].port)
--					 end
--				      else
--					 udp:send('played '..c.image..",".."P", s.ip_address)
--				      end
--				   end
--				   p:play(c, i)
--				   ui:remove(choice_panel)
--				   choosing = false
--				end
--			     end
--			  end
--
--			  function tmp.magnify(s, x, y)
--			     if s:card() then
--				local img = imgs[s:card().image]
--				if x > 1000 then
--				   love.graphics.draw(img, x-235, y, 0, .8, .8)
--				else
--				   love.graphics.draw(img, x, y, 0, .8, .8)
--				end
--			     end
--			  end
--			  choice_panel:add(tmp)
--		       end
--		    end
--
--		    choice_panel:add(title_panel)
--		    choice_panel:add(card_panel)
--		    ui:add(choice_panel)
--		 end;
--	set = {'B'};
--     }

--COMPLETE
addcard{name = "Torturer", type='attack';
	image = 'torturer';
	cost = {gold=5, potion=0};
	requireswait = true;
	onturn = function(s, p)
		    p:drawcard(3)

		    waiting = true
		    if p.id == 1 then
		       for i=2,#players do
			  if not players[i].unaffected and not players[i].lighthouse then
			     udp:sendto('torturer', players[i].ip, players[i].port)
			  else
			     players[i].unaffected = false
			     udp:sendto('donechoosing', players[1].ip, players[1].port)
			  end
		       end
		    else
		       udp:send('torturer', s.ip_address)
		    end
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Trading Post", type='action';
	image = 'tradingpost';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    if #p.hand < 2 then
		       return
		    end

		    choosing = true

		    choice_panel = panel:new(140, 50, 1000, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 1000, 30)
		    title_panel.name = "Trash 2"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(30, 60, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['tradingpost']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    local trash_count = 0
		    for i=0,6 do
		       for j=0,2 do
			  tmp = panel:new(i*90+285, j*124+66, 75, 120)
			  tmp.name = "Choice Card#"..(i+1)+(j*7)
			  tmp.align = 'center'
			  function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				   if trash_count < 2 then
				      p:trash_card(i)
				      trash_count = trash_count + 1

				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "T"
					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."T", s.ip_address)
				      end
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
		    done_panel.name = "Done ("..trash_count..")"
		    done_panel.color_bg = color(.8,.2,.2)

		    function done_panel.onupdate(s)
		       done_panel.name = "Done ("..trash_count..")"
		       if trash_count == 2 then
			  done_panel.color_bg = color(.0,.6,.3)
		       end
		    end

		    function done_panel.onclick(s, x, y, btn)
		       if trash_count == 2 then
			  if supply2_counts[2] > 0 then
			     p.hand[#p.hand+1] = supply2[2]
			     if p.id == 1 then
				supply2_counts[2] = supply2_counts[2] - 1
				play_area[#play_area+1] = supply2[2].image
				play_area_info[#play_area_info+1] = "G"

				for i=2,#players do
				   udp:sendto('boughtdos '..2, players[i].ip, players[i].port)
				end

				for i=2,#players do
				   udp:sendto('played '..supply2[2].image..",".."G", players[i].ip, players[i].port)
				end

				for i=2,#players do
				   udp:sendto('lastbought '..supply2[2].name, players[i].ip, players[i].port)
				end
			     else
				udp:send('boughtdos '..2, s.ip_address)
				udp:send('played '..supply2[2].image..",".."G", s.ip_address)
				udp:send('lastbought '..supply2[2].name, s.ip_address)
			     end
			  end
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(done_panel)
		    ui:add(choice_panel)
		 end;
	set = {'I'};
     }

--COMPLETE
addcard{name = "Transmute", type='action';
	image = 'transmute';
	cost = {gold=0, potion=1};
	onturn = function(s, p)
		    if next(p.hand) == nil then
		       return
		    end

		    choosing = true

		    choice_panel = panel:new(140, 50, 1000, 500)
		    choice_panel.name = ""
		    choice_panel.color_bg = color(.2,.2,.2)

		    title_panel = panel:new(0, 0, 1000, 30)
		    title_panel.name = "Trash a Card"
		    title_panel.color_bg = color(.4,.4,.4)

		    card_panel = panel:new(30, 60, 240, 380)
		    card_panel.name = ""
		    card_panel.align = 'center'

		    function card_panel.ondraw(s)
		       local img = imgs['transmute']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    local tg = 0
		    if #p.hand > 0 then
		       for i=0,6 do
			  for j=0,2 do
			     tmp = panel:new(i*90+285, j*124+66, 75, 120)
			     tmp.name = "Choice Card#"..(i+1)+(j*7)
			     tmp.align = 'center'
			     function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				      p:trash_card(i)

				      if p.id == 1 then
					 play_area[#play_area+1] = c.image
					 play_area_info[#play_area_info+1] = "T"
					 for i=2,#players do
					    udp:sendto('played '..c.image..",".."T", players[i].ip, players[i].port)
					 end
				      else
					 udp:send('played '..c.image..",".."T", s.ip_address)
				      end

				      if (c.type == 'action' or c.type == 'reaction' or c.type == 'attack' or c.type == 'av') and supply2_counts[6] > 0 then
					 if p.id == 1 then
					    supply2_counts[6] = supply2_counts[6] - 1
					    play_area[#play_area+1] = supply2[6].image
					    play_area_info[#play_area_info+1] = "G"

					    for i=2,#players do
					       udp:sendto('boughtdos '..6, players[i].ip, players[i].port)
					    end

					    for i=2,#players do
					       udp:sendto('played '..supply2[6].image..",".."G", players[i].ip, players[i].port)
					    end

					    for i=2,#players do
					       udp:sendto('lastbought '..supply2[6].name, players[i].ip, players[i].port)
					    end
					 else
					    udp:send('boughtdos '..6, s.ip_address)
					    udp:send('played '..supply2[6].image..",".."G", s.ip_address)
					    udp:send('lastbought '..supply2[6].name, s.ip_address)
					 end
					 p.discard_pile[#p.discard_pile+1] = supply2[6]
				      elseif c.type == 'treasure' or c.type == 'tv' then
					 for i,v in ipairs(supply1) do
					    if v.name == "Transmute" then
					       if supply1_counts[i] > 0 then
						  tg = i
					       end
					       break
					    end
					 end
				      elseif (c.type == 'victory' or c.type == 'av' or c.type == 'tv') and supply2_counts[3] > 0 then
					 if p.id == 1 then
					    supply2_counts[3] = supply2_counts[3] - 1
					    play_area[#play_area+1] = supply2[3].image
					    play_area_info[#play_area_info+1] = "G"

					    for i=2,#players do
					       udp:sendto('boughtdos '..3, players[i].ip, players[i].port)
					    end

					    for i=2,#players do
					       udp:sendto('played '..supply2[3].image..",".."G", players[i].ip, players[i].port)
					    end

					    for i=2,#players do
					       udp:sendto('lastbought '..supply2[3].name, players[i].ip, players[i].port)
					    end
					 else
					    udp:send('boughtdos '..3, s.ip_address)
					    udp:send('played '..supply2[3].image..",".."G", s.ip_address)
					    udp:send('lastbought '..supply2[3].name, s.ip_address)
					 end
					 p.discard_pile[#p.discard_pile+1] = supply2[3]
				      end

				      if tg > 0 then
					 if p.id == 1 then
					    supply1_counts[tg] = supply1_counts[tg] - 1
					    play_area[#play_area+1] = supply1[tg].image
					    play_area_info[#play_area_info+1] = "G"

					    for i=2,#players do
					       udp:sendto('boughtone '..tg, players[i].ip, players[i].port)
					    end

					    for i=2,#players do
					       udp:sendto('played '..supply1[tg].image..",".."G", players[i].ip, players[i].port)
					    end

					    for i=2,#players do
					       udp:sendto('lastbought '..supply1[tg].name, players[i].ip, players[i].port)
					    end
					 else
					    udp:send('boughtone '..tg, s.ip_address)
					    udp:send('played '..supply1[tg].image..",".."G", s.ip_address)
					    udp:send('lastbought '..supply1[tg].name, s.ip_address)
					 end
					 p.discard_pile[#p.discard_pile+1] = supply1[tg]
				      end

				      ui:remove(choice_panel)
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
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Treasure Map", type='action';
	image = 'treasuremap';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    for i,v in ipairs(p.hand) do
		       if v.name == "Treasure Map" then

			  if p.id == 1 then
			     play_area[#play_area+1] = v.image
			     play_area_info[#play_area_info+1] = "T"
			     for i=2,#players do
				udp:sendto('played '..v.image..",".."T", players[i].ip, players[i].port)
			     end
			  else
			     udp:send('played '..v.image..",".."T", s.ip_address)
			  end

			  p:trash_card(i)

			  for i=0,3 do
			     if supply2_counts[3] > 0 then
				p.deck[#p.deck+1] = supply2[3]
				if p.id == 1 then
				   supply2_counts[3] = supply2_counts[3] - 1
				   play_area[#play_area+1] = supply2[3].image
				   play_area_info[#play_area_info+1] = "G"

				   for i=2,#players do
				      udp:sendto('boughtdos '..3, players[i].ip, players[i].port)
				   end

				   for i=2,#players do
				      udp:sendto('played '..supply2[3].image..",".."G", players[i].ip, players[i].port)
				   end

				   for i=2,#players do
				      udp:sendto('lastbought '..supply2[3].name, players[i].ip, players[i].port)
				   end
				else
				   udp:send('boughtdos '..3, s.ip_address)
				   udp:send('played '..supply2[3].image..",".."G", s.ip_address)
				   udp:send('lastbought '..supply2[3].name, s.ip_address)
				end
			     end
			  end
			  return
		       end
		    end
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Treasury", type='action';
	image = 'treasury';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 1
		    p.coins = p.coins + 1
		 end;
	onend = function(s, p, index)

		   if p.victory_count > 0 then
		      return
		   end

		   choosing = true

		   choice_panel = panel:new(465, 50, 350, 500)
		   choice_panel.name = ""
		   choice_panel.color_bg = color(.2,.2,.2)

		   title_panel = panel:new(0, 0, 350, 30)
		   title_panel.name = "Put on Top of Deck?"
		   title_panel.color_bg = color(.4,.4,.4)

		   card_panel = panel:new(55, 40, 240, 380)
		   card_panel.name = ""
		   card_panel.align = 'center'

		   function card_panel.ondraw(s)
		      local img = imgs['treasury']
		      love.graphics.draw(img, 0, 0, 0, .8, .8)
		   end

		   yes_panel = panel:new(50, 440, 100, 40)
		   yes_panel.name = "Yes"
		   yes_panel.color_bg = color(.0,.6,.3)

		   function yes_panel.onclick(s, x, y, btn)
		      p.deck[#p.deck+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		   end

		   no_panel = panel:new(200, 440, 100, 40)
		   no_panel.name = "No"
		   no_panel.color_bg = color(.8,.2,.2)

		   function no_panel.onclick(s, x, y, btn)
		      p.discard_pile[#p.discard_pile+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		   end

		   choice_panel:add(title_panel)
		   choice_panel:add(card_panel)
		   choice_panel:add(yes_panel)
		   choice_panel:add(no_panel)
		   ui:add(choice_panel)
		end;
	set = {'S'};
     }

--IN PROGRESS
--addcard{name = "Tribute", type='action';
--	image = 'tribute';
--	cost = {gold=5, potion=0};
--	onturn = function(s, p)
--		    if p.id == 1 then
--		       udp:sendto('tribute', players[(active_player % #players)+1].ip, players[{active_player % #players)+1].port)
--		    else
--		       udp:send('tribute', s.ip_address)
--		    end
--		 end;
--	set = {'I'};
--     }

--COMPLETE
addcard{name = "University", type='action';
	image = 'university';
	cost = {gold=2, potion=1};
	onturn = function(s, p)
		    p.actions = p.actions+2
		    gain = 5
		    gaining = true
		 end;
	set = {'A'};
     }

--COMPLETE
addcard{name = "Village", type='action';
	image = 'village';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions+2
		 end;
	set = {'B'};
     }

--IN PROGRESS
addcard{name = "Vineyard", type='victory';
	image = 'vineyard';
	cost = {gold=0, potion=1};
	set = {'A'};
     }

--COMPLETE
addcard{name = "Walled Village", type='action';
	image = 'walledvillage';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions + 2
		 end;
	onend = function(s, p, index)

		   local a_count = 0
		   for i,v in ipairs(p.played) do
		      if v.type == 'action' or v.type == 'reaction' or v.type == 'attack' or v.type == 'av' then
			 a_count = a_count + 1
		      end
		   end

		   for i,v in ipairs(p.duration_cards) do
		      if v.type == 'action' or v.type == 'reaction' or v.type == 'attack' or v.type == 'av' then
			 a_count = a_count + 1
		      end
		   end

		   if a_count > 2 then
		      p.discard_pile[#p.discard_pile+1] = table.remove(p.played, index)
		      return
		   end

		   choosing = true

		   choice_panel = panel:new(465, 50, 350, 500)
		   choice_panel.name = ""
		   choice_panel.color_bg = color(.2,.2,.2)

		   title_panel = panel:new(0, 0, 350, 30)
		   title_panel.name = "Put on Top of Deck?"
		   title_panel.color_bg = color(.4,.4,.4)

		   card_panel = panel:new(55, 40, 240, 380)
		   card_panel.name = ""
		   card_panel.align = 'center'

		   function card_panel.ondraw(s)
		      local img = imgs['walledvillage']
		      love.graphics.draw(img, 0, 0, 0, .8, .8)
		   end

		   yes_panel = panel:new(50, 440, 100, 40)
		   yes_panel.name = "Yes"
		   yes_panel.color_bg = color(.0,.6,.3)

		   function yes_panel.onclick(s, x, y, btn)
		      p.deck[#p.deck+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		   end

		   no_panel = panel:new(200, 440, 100, 40)
		   no_panel.name = "No"
		   no_panel.color_bg = color(.8,.2,.2)

		   function no_panel.onclick(s, x, y, btn)
		      p.discard_pile[#p.discard_pile+1] = table.remove(p.played, index)
		      ui:remove(choice_panel)
		      choosing = false
		      ui:click(62, 693, 'l')
		   end

		   choice_panel:add(title_panel)
		   choice_panel:add(card_panel)
		   choice_panel:add(yes_panel)
		   choice_panel:add(no_panel)
		   ui:add(choice_panel)
		end;
	set = {'PR'};
     }

--COMPLETE
addcard{name = "Warehouse", type='action';
	image = 'warehouse';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p:drawcard(3)
		    p.actions = p.actions+1

		    choosing = true

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
		       local img = imgs['warehouse']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    local discard_count = 0
		    for i=0,6 do
		       for j=0,2 do
			  tmp = panel:new(i*90+285, j*124+66, 75, 120)
			  tmp.name = "Choice Card#"..(i+1)+(j*7)
			  tmp.align = 'center'
			  function tmp:card() return p.hand[(i+1)+(j*7)], (i+1)+(j*7) end

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
				   if discard_count < 3 then
				      p:discard(i)
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
		       if discard_count == 3 or #p.hand == 0 then
			  done_panel.color_bg = color(.0,.6,.3)
		       end
		    end

		    function done_panel.onclick(s, x, y, btn)
		       if discard_count == 3 or #p.hand == 0 then
			  ui:remove(choice_panel)
			  choosing = false
		       end
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    choice_panel:add(done_panel)
		    ui:add(choice_panel)
		 end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Wharf", type='action';
	image = 'wharf';
	cost = {gold=5, potion=0};
	duration = true;
	onturn = function(s, p)
		    p:drawcard(2)
		    p.buys = p.buys + 1
		 end;
	nextturn = function(s, p)
		      p:drawcard(2)
		      p.buys = p.buys + 1
		   end;
	set = {'S'};
     }

--COMPLETE
addcard{name = "Wishing Well", type='action';
	image = 'wishingwell';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p:drawcard()
		    p.actions = p.actions+1

		    choosing = true

		    local c_set = {}
		    for i,v in ipairs(p.deck) do
		       c_set[v.image] = true
		    end
		    for i,v in ipairs(p.discard_pile) do
		       c_set[v.image] = true
		    end
		    for i,v in ipairs(p.hand) do
		       c_set[v.image] = true
		    end
		    for i,v in ipairs(p.played) do
		       c_set[v.image] = true
		    end

		    local choices = {}
		    for k,v in pairs(c_set) do
		       choices[#choices+1] = k
		    end

		    table.sort(choices, function(a,b) return a<b end)

		    if next(choices) == nil then
		       choosing = false
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
		       local img = imgs['wishingwell']
		       love.graphics.draw(img, 0, 0, 0, .8, .8)
		    end

		    local tmp
		    for i=0,6 do
		       for j=0,2 do
			  tmp = panel:new(i*90+285, j*124+66, 75, 120)
			  tmp.name = "Choice Card#"..(i+1)+(j*7)
			  tmp.align = 'center'
			  function tmp:card() return choices[(i+1)+(j*7)] end

			  function tmp.ondraw(s)
			     if s:card() then
				local img = imgs[s:card()]
				love.graphics.draw(img, 0, 0, 0, .25, .25)
			     end
			  end

			  function tmp.onclick(s, x, y, btn)
			     if s:card() then
				if btn == 'l' then
				   local c = p:revealtop()
				   if p.id == 1 then
				      play_area[#play_area+1] = c.image
				      play_area_info[#play_area_info+1] = "R"

				      for i=2,#players do
					 udp:sendto('played '..c.image..",".."R", players[i].ip, players[i].port)
				      end
				   else
				      udp:send('played '..c.image..",".."R", s.ip_address)
				   end

				   if c.image == s:card() then
				      p.hand[#p.hand+1] = table.remove(p.deck, #p.deck)
				   end

				   ui:remove(choice_panel)
				   choosing = false
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
			  choice_panel:add(tmp)
		       end
		    end

		    choice_panel:add(title_panel)
		    choice_panel:add(card_panel)
		    ui:add(choice_panel)
		 end;
	set = {'B'};
     }

--COMPLETE
--BUGGY EXTRA CURSE
addcard{name = "Witch", type='attack';
	image = 'witch';
	cost = {gold=5, potion=0};
	onturn = function(s, p)
		    p:drawcard(2)

		    local witch_count = supply2_counts[8]

		    if p.id == 1 then
		       for i=2,#players do
			  if not players[i].unaffected and not players[i].lighthouse then
			     if witch_count == 0 then
				return
			     end
			     witch_count = witch_count - 1
			     udp:sendto('witch', players[i].ip, players[i].port)
			  else
			     players[i].unaffected = false
			  end
		       end
		    else
		       udp:send('witch', s.ip_address)
		    end
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Woodcutter", type='action';
	image = 'woodcutter';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    p.coins = p.coins+2
		    p.buys = p.buys+1
		 end;
	set = {'B'};
     }

--COMPLETE
addcard{name = "Workers Village", type='action';
	image = 'workersvillage';
	cost = {gold=4, potion=0};
	onturn = function(s, p)
		    p:drawcard(1)
		    p.actions = p.actions + 2
		    p.buys = p.buys + 1
		 end;
	set = {'P'};
     }

--COMPLETE
addcard{name = "Workshop", type='action';
	image = 'workshop';
	cost = {gold=3, potion=0};
	onturn = function(s, p)
		    gain = 4
		    gaining = true
		 end;
	set = {'B'};
     }

if _VERSION == "Lua 5.1" then _G[_M._NAME] = _M end

return _M