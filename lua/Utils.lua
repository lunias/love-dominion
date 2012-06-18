function round(n)
	if n < 0 then return math.floor(n)
	else return math.ceil(n)
	end
end


function color(r, g, b, a)
	assert(r and g and b, "Must give RGB(A) values.")
	return {round(r*255),round(g*255),round(b*255),round((a or 1)*255),}
end

function grey(r, g, b)
  if type(r) == 'table' then r, g, b = unpack(r) end
  local g = (r+g+b)/(255*3)
  return g, g, g
end


function bbox(bx, by, bw, bh, tx, ty)
	return (tx >= bx and tx <= (bx+bw)) and (ty >= by and ty <= (by+bh))
end

function tdump(t)
   for k, v in pairs(t) do
      print(k,v.name)
   end
end

function pick(t)
   assert(type(t) == 'table', "expected array-like table, got '"..type(t).."'")
   local p = math.random(#t)
   return t[p], p
end

function shuffle (list)
  local n = #list
  while n > 1 do
    k = math.random(n)
    if k ~= n then
      list[n], list[k] = list[k], list[n]
    end
    n = n - 1
  end
end

