Player = class('Player')

local id
local name
local ip
local port

local actions
local buys
local coins
local potions
local victory_points

local hand
local played
local deck
local discard_pile
local trash

local last_played

--CARD SPECIFIC
local unaffected
local coppersmith
local crossroads
local tactician
local outpost
local outpost_block
local lighthouse
local haven
local island
local action_count
local victory_count

local duration_cards

local active

function Player:initialize(id, ip, port)
   self.id = id
   self.name = "Player "..id
   self.ip = ip
   self.port = port

   self.actions = 1
   self.buys = 1
   self.coins = 0
   self.potions = 0
   self.victory_points = 0

   self.hand = {}
   self.played = {}
   self.deck = {}
   self.discard_pile = {}
   self.trash = {}

   self.last_played = nil
   self.throne = false
   self.unaffected = false
   self.coppersmith = 0
   self.crossroads = false
   self.tactician = 0
   self.outpost = false
   self.outpost_block = false
   self.lighthouse = false
   self.haven = {}
   self.island = {}
   self.action_count = 0
   self.victory_count = 0

   self.duration_cards = {}

   self.active = false
end

function Player:start()
   for i=1, 7 do
      self.deck[#self.deck+1] = cards:newcard(cards.set["Copper"])
   end

   for i=1, 3 do
      self.deck[#self.deck+1] = cards:newcard(cards.set["Estate"])
   end

   shuffle(self.deck)

   self:drawcard(5)
end

function Player:getId()
   return self.id
end

function Player:getCoins()
   return self.coins
end

function Player:addCoins(value)
   self.coins = self.coins + value
end

function Player:play(card, index)

   self.last_played = card

   if card.name == "Feast" or card.name == "Treasure Map" then
      self.trash[#self.trash+1] = table.remove(self.hand, index)
   elseif card.name == "Island" then
      self.island[#self.island+1] = table.remove(self.hand, index)
   elseif card.duration then
      self.duration_cards[#self.duration_cards+1] = table.remove(self.hand, index)
   else
      self.played[#self.played+1] = table.remove(self.hand, index)
   end

   --Check for Reactions
   if card.type == 'attack' then
      waiting = true
      if self.id == 1 then
	 for i=2,#players do
	    udp:sendto("canreact", players[i].ip, players[i].port)
	 end
      else
	 udp:send("canreact", self.ip_address)
      end
   else
      card:onturn(self)
   end
end

function Player:play_clear(card)
   card:onturn(self)
end

function Player:can_react()
   for i,v in ipairs(self.hand) do
      if v.type == 'reaction' then
	 return true
      end
   end
   return false
end

--TODO: Multiple Reactions
function Player:react()
   for i,v in ipairs(self.hand) do
      if v.type == 'reaction' then
	 v:reaction(self)
	 return
      end
   end
end

function Player:drawcard(n)
   n = n or 1
   for i=1,n do
      if next(self.deck) == nil then
	 shuffle(self.discard_pile)
	 self.deck = self.discard_pile
	 self.discard_pile = {}
      end
      self.hand[#self.hand+1] = self.deck[#self.deck]
      self.deck[#self.deck] = nil
   end
   table.sort(self.hand, function(a,b) return a.name<b.name end)
end

function Player:revealtop()
   if next(self.deck) == nil then
      shuffle(self.discard_pile)
      self.deck = self.discard_pile
      self.discard_pile = {}
   end
   return self.deck[#self.deck]
end

function Player:discardtop()
   if next(self.deck) == nil then
      shuffle(self.discard_pile)
      self.deck = self.discard_pile
      self.discard_pile = {}
   end
   local card = self.deck[#self.deck]
   self.discard_pile[#self.discard_pile+1] = table.remove(self.deck, #self.deck)
   return card
end

function Player:discard(index)
   local card, i = self.hand[index], index
   self.discard_pile[#self.discard_pile+1] = table.remove(self.hand, i)
end

function Player:trash_card(index)
   local card, i = self.hand[index], index
   self.trash[#self.trash+1] = table.remove(self.hand, i)
end

function Player:deck_into_discard()
   while #self.deck > 0 do
      self.discard_pile[#self.discard_pile+1] = table.remove(self.deck, 1)
   end
end

function Player:count_victory()
   local victory = 0
   local duchys = 0
   local dukes = 0
   local actions = 0
   local vineyards = 0
   local num_cards = #self.deck + #self.discard_pile + #self.hand + #self.played

   for i,v in ipairs(self.deck) do
      if v.type == 'action' or v.type == 'av' or v.type == 'tv' then
	 actions = actions + 1
      end

      if v.name == 'Estate' then
	 victory = victory + 1
      elseif v.name == 'Duchy' then
	 victory = victory + 3
	 duchys = duchys + 1
      elseif v.name == 'Province' then
	 victory = victory + 6
      elseif v.name == 'Curse' then
	 victory = victory - 1
      elseif v.name == 'Island' then
	 victory = victory + 2
      elseif v.name == 'Gardens' then
	 victory = victory + math.floor(num_cards / 10)
      elseif v.name == 'Duke' then
	 dukes = dukes + 1
      elseif v.name == 'Nobles' then
	 victory = victory + 2
      elseif v.name == 'Great Hall' then
	 victory = victory + 1
      elseif v.name == 'Harem' then
	 victory = victory + 2
      elseif v.name == 'Vineyard' then
	 vineyards = vineyards + 1
      end
   end

   for i,v in ipairs(self.discard_pile) do
      if v.type == 'action' or v.type == 'av' or v.type == 'tv' then
	 actions = actions + 1
      end

      if v.name == 'Estate' then
	 victory = victory + 1
      elseif v.name == 'Duchy' then
	 victory = victory + 3
	 duchys = duchys + 1
      elseif v.name == 'Province' then
	 victory = victory + 6
      elseif v.name == 'Curse' then
	 victory = victory - 1
      elseif v.name == 'Island' then
	 victory = victory + 2
      elseif v.name == 'Gardens' then
	 victory = victory + math.floor(num_cards / 10)
      elseif v.name == 'Duke' then
	 dukes = dukes + 1
      elseif v.name == 'Nobles' then
	 victory = victory + 2
      elseif v.name == 'Great Hall' then
	 victory = victory + 1
      elseif v.name == 'Harem' then
	 victory = victory + 2
      elseif v.name == 'Vineyard' then
	 vineyards = vineyards + 1
      end
   end

   for i,v in ipairs(self.hand) do
      if v.type == 'action' or v.type == 'av' or v.type == 'tv' then
	 actions = actions + 1
      end

      if v.name == 'Estate' then
	 victory = victory + 1
      elseif v.name == 'Duchy' then
	 victory = victory + 3
	 duchys = duchys + 1
      elseif v.name == 'Province' then
	 victory = victory + 6
      elseif v.name == 'Curse' then
	 victory = victory - 1
      elseif v.name == 'Island' then
	 victory = victory + 2
      elseif v.name == 'Gardens' then
	 victory = victory + math.floor(num_cards / 10)
      elseif v.name == 'Duke' then
	 dukes = dukes + 1
      elseif v.name == 'Nobles' then
	 victory = victory + 2
      elseif v.name == 'Great Hall' then
	 victory = victory + 1
      elseif v.name == 'Harem' then
	 victory = victory + 2
      elseif v.name == 'Vineyard' then
	 vineyards = vineyards + 1
      end
   end

   for i,v in ipairs(self.played) do
      if v.type == 'action' or v.type == 'av' or v.type == 'tv' then
	 actions = actions + 1
      end

      if v.name == 'Estate' then
	 victory = victory + 1
      elseif v.name == 'Duchy' then
	 victory = victory + 3
	 duchys = duchys + 1
      elseif v.name == 'Province' then
	 victory = victory + 6
      elseif v.name == 'Curse' then
	 victory = victory - 1
      elseif v.name == 'Island' then
	 victory = victory + 2
      elseif v.name == 'Gardens' then
	 victory = victory + math.floor(num_cards / 10)
      elseif v.name == 'Duke' then
	 dukes = dukes + 1
      elseif v.name == 'Nobles' then
	 victory = victory + 2
      elseif v.name == 'Great Hall' then
	 victory = victory + 1
      elseif v.name == 'Harem' then
	 victory = victory + 2
      elseif v.name == 'Vineyard' then
	 vineyards = vineyards + 1
      end
   end

   for i,v in ipairs(self.island) do
      if v.type == 'action' or v.type == 'av' or v.type == 'tv' then
	 actions = actions + 1
      end

      if v.name == 'Estate' then
	 victory = victory + 1
      elseif v.name == 'Duchy' then
	 victory = victory + 3
	 duchys = duchys + 1
      elseif v.name == 'Province' then
	 victory = victory + 6
      elseif v.name == 'Curse' then
	 victory = victory - 1
      elseif v.name == 'Island' then
	 victory = victory + 2
      elseif v.name == 'Gardens' then
	 victory = victory + math.floor(num_cards / 10)
      elseif v.name == 'Duke' then
	 dukes = dukes + 1
      elseif v.name == 'Nobles' then
	 victory = victory + 2
      elseif v.name == 'Great Hall' then
	 victory = victory + 1
      elseif v.name == 'Harem' then
	 victory = victory + 2
      elseif v.name == 'Vineyard' then
	 vineyards = vineyards + 1
      end
   end

   victory = victory + (dukes * duchys)
   victory = victory + (math.floor(actions / 3) * vineyards)

   return victory
end


