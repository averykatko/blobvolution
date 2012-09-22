function distance(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end