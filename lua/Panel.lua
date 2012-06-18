local _M = {_NAME = "panel", _TYPE = 'module'}

require "lua.Utils"

local panel_mt ={__index = _M}

local p_bgcol = color(.4,.4,.4)
local p_fgcol = color(.0,.0,.0)
local p_txtcol = color(.9,.9,.9)
local cnt = 0

function _M:new(x,y,w,h)
	local p = {x=x, y=y, height=h, width=w, id = cnt}
	cnt = cnt+1
	setmetatable(p, panel_mt)
	p._TYPE = 'panel'
	p.color_bg = p_bgcol
	p.color_fg = p_fgcol
	p.color_txt = p_txtcol
	p.name = "Panel#"..cnt
	p.align = 'center'
	p.valign = 'middle'
	p.font = 12
	p.children = {}
	p.border = true
	p.index = 0

	return p
end

function _M:draw()
	local lg = love.graphics
	local absx, absy = self:abspos()

	local sis = {lg.getScissor()}
	lg.setScissor(absx, absy, self.width, self.height)
	lg.translate(self.x, self.y)

	self:ondraw()

	lg.setScissor(unpack(sis))

	if self.children then
		for i=1, #self.children do
			self.children[i]:draw()
		end
	end
	lg.translate(-self.x, -self.y)
end

function _M:ondraw()
   local lg = love.graphics
   lg.setColor(self.color_bg)
   lg.rectangle('fill', 0, 0, self.width, self.height)
   if self.border then
      lg.setColor(self.color_fg)
      lg.rectangle('line', 0, 0, self.width, self.height)
   end

   local msg = self.text or self.name or string.format("Panel#%d", self.id)
   local f = fonts[self.font]
   lg.setColorMode('modulate')
   lg.setColor(self.color_txt)
   lg.setFont(f)
   local w, l = f:getWrap(msg, self.width)
   if self.valign == 'top' then
      lg.printf(msg, 0, 0, self.width, self.align)
   else
      local offset = (l*f:getHeight())
      if self.valign == 'middle' then
	 offset = ((-offset) / 2) + (self.height / 2)
	 lg.printf(msg, 0, offset, self.width, self.align)

      else -- valign == bottom
	 offset = (-offset) + self.height
	 lg.printf(msg, 0, offset, self.width, self.align)
      end
   end
   lg.setColorMode('replace')

end

function _M:hover(x, y)
   if not bbox(self.x, self.y, self.width, self.height, x, y) then return false end

   local child
   for i=#self.children, 1, -1 do
      child = self.children[i]:hover(x-self.x,y-self.y)
      if child then return child end
   end


   -- if none of the children matched, then we're it; return self.
   return self
end

function _M:magnify(x, y) end

function _M:update(dt)
	self:onupdate(dt)

	for i=#self.children, 1, -1 do
		self.children[i]:update(dt)
	end
end

-- dummy so nothing crashes if instances don't supply their own.
function _M:onupdate() end


function _M:click(x, y, btn)
	self:hover(x, y):onclick(x, y, btn)
end

-- dummy so nothing crashes if instances don't supply their own.
function _M:onclick() end

function _M:add(p)
   table.insert(self.children, p)
   p.parent = self
end

local function count_children(p)
   local c = 1
   for i,v in ipairs(p.children) do
      if #v.children == 0 then
	 c = c + 1
      else
	 c = c + count_children(v)
      end
   end
   return c
end

function _M:remove(p)
   for k,v in pairs(self.children) do
      if v == p then
	 cnt = cnt - count_children(v)
	 table.remove(self.children, k)
	 --p.parent = nil
	 p = nil
	 break
      end
   end
end

function _M:abspos()
	local x, y
	if self.parent then
		x, y = self.parent:abspos()
		return x+self.x, y+self.y
	else
		return self.x, self.y
	end
end

-------------------------------------------------------------------------
if _VERSION == "Lua 5.1" then _G[_M._NAME] = _M end

return _M

