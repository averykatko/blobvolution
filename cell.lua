love.filesystem.load("defs.lua")()

function addCell(c)
	table.insert(cells,c)
end

function newNode(x,y,vx,vy,ax,ay)
	return {x=x,y=y,vx=vx,vy=vy,ax=ax,ay=ay}
end

function insertNode(m,idx,n)
	table.insert(m,idx,n)
end

function newCell(x, y)
	local cell = {}
	cell.nucleus = {x=x,y=y,vx=0,vy=0,ax=0,ay=0}

	cell.membrane = {}
	for i = 1,13 do
		cell.membrane[i] = {x=x+50*math.cos(math.rad(15*i)),y=y+50*math.sin(math.rad(15*i)),vx=0,vy=0,ax=0,ay=0,spring=0}
		cell.membrane[i].spring = fNucSpringLength(cell)
	end
	
	cell.genes = {}
	cell.genes.growtime = 2 --1 --time to grow a new node, in seconds
	cell.genes.splitnodes = 18 --18 --# membrane nodes to divide at
	cell.genes.speed = 15 --15 --movement speed
	cell.genes.attackdist = 100 --how close it has to be to player to attack
	cell.genes.bombgrav = 0 --how attracted (+) or repelled (-) it is by bombs
	cell.genes.attackstyle = "bump" --either "bump" or "engulf"
	cell.genes.acidity = 0 --how much player is damaged when inside cell
	cell.genes.damagestyle = "shrink" --either "shrink" or "split"
	
	cell.gtimer = 0 --in seconds
	cell.dir = math.random()*2*math.pi --movement direction
	return cell
end

function mutate(c)
	local g = c.genes
	--g.growtime = g.growtime + (math.random()-0.5)*0.01
	if 1 == math.random(10) then g.growtime = g.growtime + math.random(3) - 2 end
	if(g.growtime < 0.1) then g.growtime = 0.1 end
	if 1 == math.random(6) then g.splitnodes = g.splitnodes + 2*(math.random(3) - 2) end
	if(g.splitnodes < 12) then g.splitnodes = 12 end
	--g.speed = g.speed + (math.random()-0.5)
	--g.attackdist = g.attackdist + (math.random()-0.5)*10
	--c.genes.bombgrav = 0
	--c.genes.attackstyle = "bump"
	--g.acidity = g.acidity + math.random(-5,5)
	--c.genes.damagestyle = "shrink"
end

function grow(c)
	--insert new node into random part of membrane:
	local idx = math.random(table.getn(c.membrane))
	local idx2 = idx - 1
	if idx2 < 1 then idx2 = table.getn(c.membrane) end
	
	local nx = (c.membrane[idx2].x+c.membrane[idx].x)/2 -- average of surrounding node x coords
	local ny = (c.membrane[idx2].y+c.membrane[idx].y)/2 -- " " y coords
	
	local nvx = (c.membrane[idx2].vx+c.membrane[idx].vx)/2 -- average of surrounding node vx coords
	local nvy = (c.membrane[idx2].vy+c.membrane[idx].vy)/2 -- " " vy coords
	
	local nodax = (c.membrane[idx2].ax+c.membrane[idx].ax)/2 -- average of surrounding node ax coords
	local noday = (c.membrane[idx2].ay+c.membrane[idx].ay)/2 -- " " ay coords
	
	table.insert(c.membrane,idx,{x=nx,y=ny,vx=nvx,vy=nvy,ax=nodax,ay=noday,spring=fNucSpringLength(c)})
end

function mitosis(_n)
	local c = cells[_n]
	local oldsize = table.getn(c.membrane)
	local split = oldsize/2
	local oldc = c
	c = {}
	c.membrane = {}
	c.nucleus = {}
	
	local newcell = {}
	newcell.membrane = {}
	newcell.nucleus = {}
	
	for i = 1,split-1 do
		c.membrane[i] = table.copy(oldc.membrane[i])
	end
	local nucCopy = table.copy(oldc.nucleus)
	nucCopy.spring = fNucSpringLength(c)
	table.insert(c.membrane,nucCopy)
	
	for i = split,oldsize do
		newcell.membrane[i+1-split] = table.copy(oldc.membrane[i])
	end
	
	local nucCopy = table.copy(oldc.nucleus)
	nucCopy.spring = fNucSpringLength(c)
	table.insert(newcell.membrane,nucCopy)
	
	local cnx = 0
	local cny = 0
	local csize = table.getn(c.membrane)
	for i = 1,csize do
		cnx = cnx + c.membrane[i].x
		cny = cny + c.membrane[i].y
	end
	c.nucleus.x = cnx/csize
	c.nucleus.y = cny/csize
	c.nucleus.vx = oldc.nucleus.vx -- / 2
	c.nucleus.vy = oldc.nucleus.vy -- / 2
	c.nucleus.ax = oldc.nucleus.ax --0
	c.nucleus.ay = oldc.nucleus.ay --0
	
	local nnx = 0
	local nny = 0
	local nsize = table.getn(newcell.membrane)
	for i = 1,nsize do
		nnx = nnx + newcell.membrane[i].x
		nny = nny + newcell.membrane[i].y
	end
	newcell.nucleus.x = nnx/nsize
	newcell.nucleus.y = nny/nsize
	newcell.nucleus.vx = oldc.nucleus.vx -- / 2
	newcell.nucleus.vy = oldc.nucleus.vy -- / 2
	newcell.nucleus.ax = oldc.nucleus.ax --0
	newcell.nucleus.ay = oldc.nucleus.ay --0
	
	c.genes = table.copy(oldc.genes)
	c.gtimer = 0
	newcell.genes = table.copy(oldc.genes)
	newcell.gtimer = 0
	
	mutate(c)
	mutate(newcell)
	
	c.dir = math.random()*2*math.pi
	newcell.dir = math.random()*2*math.pi
	
	cells[_n] = c
	addCell(newcell)
end

function updateCell(_n,dt)
	local c = cells[_n]
	c.gtimer = c.gtimer + dt
	if c.gtimer >= c.genes.growtime then --grow
		c.gtimer = c.gtimer - c.genes.growtime --reset timer
		grow(c)
	end
	
	--BEGIN MITOSIS:
	if table.getn(c.membrane) >= c.genes.splitnodes then --mitosis!
		mitosis(_n)
	end
	--END MITOSIS.
	
	--c.nucleus acc
	local nax = 0
	local nay = 0
	
	--acceleration for constant speed
	local acc = mediumDamping * c.genes.speed
	
	if distance(c.nucleus.x,c.nucleus.y,player.x,player.y) <= c.genes.attackdist then
		c.dir = math.atan2(player.y-c.nucleus.y,player.x-c.nucleus.x)
	end
	local dir = c.dir
	--[[if love.keyboard.isDown("right","f","left","s","down","d","up","e") then
		acc = mediumDamping * c.genes.speed
		if love.keyboard.isDown("right","f") then dir = 0 end
		if love.keyboard.isDown("left","s") then dir = math.pi  end
		if love.keyboard.isDown("down","d") then dir = 0.5*math.pi end
		if love.keyboard.isDown("up","e") then dir = 1.5*math.pi end
	end]]
	nax = nax + acc*math.cos(dir)
	nay = nay + acc*math.sin(dir)
	
	local avgx = 0
	local avgy = 0
	--Verlet integration
	local i = 1
	while i < table.getn(c.membrane) do
		local continue = false
		local newax = 0
		local neway = 0
		avgx = avgx + c.membrane[i].x
		avgy = avgy + c.membrane[i].y
		
		--check for COLLISIONS:
		--TODO: precise polygon collision detection
		
		--with player:
		if distance(c.membrane[i].x,c.membrane[i].y,player.x,player.y) < plen+2 then
			hitPlayer(1)
			table.insert(debugPts,{x = c.membrane[i].x, y = c.membrane[i].y, r = 2})
			table.insert(debugPts,{x = c.nucleus.x, y = c.nucleus.y, r = 4})
		end
		--with bullets:
		local j = 1
		while j <= table.getn(bullets) do
			if distance(c.membrane[i].x,c.membrane[i].y,bullets[j].x,bullets[j].y) < 4 then
				
				table.insert(debugPts,{x = c.membrane[i].x, y = c.membrane[i].y, r = 2})
				table.insert(debugPts,{x = c.nucleus.x, y = c.nucleus.y, r = 4})
				
				table.remove(bullets,j)
				table.remove(c.membrane,i)
				
				continue = true
				break
			else
			 	j = j + 1
			end
		end
		if not continue then
		--update position:
		c.membrane[i].x = c.membrane[i].x + c.membrane[i].vx*dt + 0.5*c.membrane[i].ax*dt*dt --update x
		c.membrane[i].y = c.membrane[i].y + c.membrane[i].vy*dt + 0.5*c.membrane[i].ay*dt*dt --update y
		--boundaries:
		if c.membrane[i].x < xmin then c.membrane[i].x = xmin+2; c.dir = c.dir + math.pi
		elseif c.membrane[i].x > xmax then c.membrane[i].x = xmax-2; c.dir = c.dir + math.pi end
		if c.membrane[i].y < ymin then c.membrane[i].y = ymin+2; c.dir = c.dir + math.pi
		elseif c.membrane[i].y > ymax then c.membrane[i].y = ymax-2; c.dir = c.dir + math.pi end
		--calculating acceleration:
		
		local accn = acc + 80*(math.random() - 0.5)
		newax = newax + accn*math.cos(dir)
		neway = neway + accn*math.sin(dir)
		
		--Hooke's law for spring connecting c.membrane point to c.nucleus:
		local distance = math.sqrt((c.membrane[i].x-c.nucleus.x)^2 + (c.membrane[i].y-c.nucleus.y)^2)
		local force = -kNucSpring*(distance-c.membrane[i].spring)
		local theta = math.atan2(c.membrane[i].y-c.nucleus.y,c.membrane[i].x-c.nucleus.x)
		newax = newax + (force/distance)*math.cos(theta)
		neway = neway + (force/distance)*math.sin(theta)
		nax = nax - --[[0.5*]](force/distance)*math.cos(theta)
		nay = nay - --[[0.5*]](force/distance)*math.sin(theta)
		
		--Hooke's law for springs connecting to adjacent points:
		--preceding:
		local otherx = 0
		local othery = 0
		if 1 == i then
			otherx = c.membrane[table.getn(c.membrane)].x
			othery = c.membrane[table.getn(c.membrane)].y
		else
			otherx = c.membrane[i-1].x
			othery = c.membrane[i-1].y
		end
		distance = math.sqrt((c.membrane[i].x-otherx)^2 + (c.membrane[i].y-othery)^2)
		force = -kMemSpring*(distance-memSpringLength)
		theta = math.atan2(c.membrane[i].y-othery,c.membrane[i].x-otherx)
		newax = newax + (force/distance)*math.cos(theta)
		neway = neway + (force/distance)*math.sin(theta)
		
		--succeeding:
		if c.mbsize == i then
			otherx = c.membrane[1].x
			othery = c.membrane[1].y
		else
			otherx = c.membrane[i+1].x
			othery = c.membrane[i+1].y
		end
		distance = math.sqrt((c.membrane[i].x-otherx)^2 + (c.membrane[i].y-othery)^2)
		force = -kMemSpring*(distance-memSpringLength)
		theta = math.atan2(c.membrane[i].y-othery,c.membrane[i].x-otherx)
		newax = newax + (force/distance)*math.cos(theta)
		neway = neway + (force/distance)*math.sin(theta)
		
		--damping:
		newax = newax - mediumDamping*c.membrane[i].vx
		neway = neway - mediumDamping*c.membrane[i].vy
		
		--update velocity:
		c.membrane[i].vx = c.membrane[i].vx + (c.membrane[i].ax+newax)*dt/2 --update vx
		c.membrane[i].vy = c.membrane[i].vy + (c.membrane[i].ay+neway)*dt/2 --update vy
		c.membrane[i].ax = newax
		c.membrane[i].ay = neway
		i = i + 1
		end--if not continue; hackish workaround since Lua apparently doesn't have continue
	end

	avgx = avgx / table.getn(c.membrane)
	avgy = avgy / table.getn(c.membrane)
	
	--[[if distance(avgx,avgy,c.nucleus.x,c.nucleus.y) > nucSpringLength then
		c.nucleus.x = avgx
		c.nucleus.y = avgy
	end]]

	--c.nucleus motion: (verlet)
	c.nucleus.x = c.nucleus.x + c.nucleus.vx*dt + 0.5*c.nucleus.ax*dt*dt
	c.nucleus.y = c.nucleus.y + c.nucleus.vy*dt + 0.5*c.nucleus.ay*dt*dt
	 
	--damping:
	c.nucleus.ax = c.nucleus.ax - mediumDamping*c.nucleus.vx
	c.nucleus.ay = c.nucleus.ay - mediumDamping*c.nucleus.vy
	
	c.nucleus.vx = c.nucleus.vx + (c.nucleus.ax+nax)*dt/2
	c.nucleus.vy = c.nucleus.vy + (c.nucleus.ay+nay)*dt/2
	c.nucleus.ax = nax
	c.nucleus.ay = nay
end

function drawCell(c)
	local red = 0
	local green = 0
	if c.genes.acidity > 0 then
		--red = 4*c.genes.acidity
		green = -4*c.genes.acidity
	elseif c.genes.acidity < 0 then
		red = -4*c.genes.acidity
		--green = 4*c.genes.acidity
	end
	local pgon = {}
	for i,node in ipairs(c.membrane) do
		table.insert(pgon,node.x)
		table.insert(pgon,node.y)
	end
	love.graphics.setColor(255-red,255-green,255-red-green,64)
	love.graphics.polygon("fill",pgon)
	love.graphics.setColor(255,255,255,255)
	love.graphics.polygon("line",pgon)
	love.graphics.circle("line",c.nucleus.x,c.nucleus.y,2,10)
	love.graphics.setColor(0,0,0,255)
	for j = 1,table.getn(c.membrane) do love.graphics.point(c.membrane[j].x,c.membrane[j].y) end
end