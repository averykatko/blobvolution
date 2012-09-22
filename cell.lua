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
		cell.membrane[i] = {x=x+50*math.cos(math.rad(15*i)),y=y+50*math.sin(math.rad(15*i)),vx=0,vy=0,ax=0,ay=0}
		--cell.membrane[i] = x+50*math.cos(math.rad(15*i))
		--cell.membrane[i+1] = y+50*math.sin(math.rad(15*i))
	end
	cell.mbsize = table.getn(cell.membrane)

	cell.springs = {}
	for i = 1,13 do cell.springs[i] = fNucSpringLength(cell) end
	cell.membraneVel = { }
	for i = 1,cell.mbsize do
		cell.membraneVel[i] = 0 --set initial velocities to zero
	end
	--membraneVel[1] = 0.5
	--membraneVel[2] = 0.5
	cell.membraneAcc = { }
	for i = 1,cell.mbsize do
		cell.membraneAcc[i] = 0 --set initial acceleration to zero
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
	local idx = math.random(c.mbsize-1)
	local idx2 = idx - 2
	if idx2 < 1 then idx2 = c.mbsize-1 end
	local nx = (c.membrane[idx2]+c.membrane[idx])/2 -- average of surrounding node x coords
	local ny = (c.membrane[idx2+1]+c.membrane[idx+1])/2 -- " " y coords
	table.insert(c.membrane,idx,nx)
	table.insert(c.membrane,idx+1,ny)
	local nvx = (c.membraneVel[idx2]+c.membraneVel[idx])/2 -- average of surrounding node vx coords
	local nvy = (c.membraneVel[idx2+1]+c.membraneVel[idx+1])/2 -- " " vy coords
	table.insert(c.membraneVel,idx,nvx)
	table.insert(c.membraneVel,idx+1,nvy)
	local nodax = (c.membraneAcc[idx2]+c.membraneAcc[idx])/2 -- average of surrounding node ax coords
	local noday = (c.membraneAcc[idx2+1]+c.membraneAcc[idx+1])/2 -- " " ay coords
	table.insert(c.membraneAcc,idx,nodax)
	table.insert(c.membraneAcc,idx+1,noday)
	--add spring to nucleus:
	table.insert(c.springs,(idx+1)/2,fNucSpringLength(c))
	c.mbsize = table.getn(c.membrane)
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
		c.membrane[i] = oldc.membrane[i]
	end
	table.insert(c.membrane,table.copy(oldc.nucleus))
	
	for i = split,oldsize do
		newcell.membrane[i+1-split] = oldc.membrane[i]
	end
	table.insert(newcell.membrane,table.copy(oldc.nucleus))
	
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
	--print(_n,c)
	--print(c.membrane[1],c.membrane[2],c.membrane[mbsize-1],c.membrane[mbsize])
	--print(c.nucleus.x,c.nucleus.y,c.nucleus.vx,c.nucleus.vy,c.nucleus.ax,c.nucleus.ay)
	c.gtimer = c.gtimer + dt
	if c.gtimer >= c.genes.growtime then --grow
		c.gtimer = c.gtimer - c.genes.growtime --reset timer
		grow(c)
	end
	
	--BEGIN MITOSIS:
	if c.mbsize/2 >= c.genes.splitnodes then --mitosis!
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
	while i < c.mbsize do
		local continue = false
		local newax = 0
		local neway = 0
		avgx = avgx + c.membrane[i]
		avgy = avgy + c.membrane[i+1]
		--check for COLLISIONS:
		--with player:
		if distance(c.membrane[i],c.membrane[i+1],player.x,player.y) < plen+2 then
			hitPlayer(1)
			table.insert(debugPts,{x = c.membrane[i], y = c.membrane[i+1], r = 2})
			table.insert(debugPts,{x = c.nucleus.x, y = c.nucleus.y, r = 4})
		end
		--with bullets:
		local j = 1
		while j <= table.getn(bullets) do
			if distance(c.membrane[i],c.membrane[i+1],bullets[j].x,bullets[j].y) < 4 then
				
				table.insert(debugPts,{x = c.membrane[i], y = c.membrane[i+1], r = 2})
				table.insert(debugPts,{x = c.nucleus.x, y = c.nucleus.y, r = 4})
				
				table.remove(bullets,j)
				table.remove(c.membrane,i)
				table.remove(c.membrane,i)
				table.remove(c.membraneVel,i)
				table.remove(c.membraneVel,i)
				table.remove(c.membraneAcc,i)
				table.remove(c.membraneAcc,i)
				table.remove(c.springs,(i+1)/2)
				c.mbsize = table.getn(c.membrane)
				continue = true
				break
			else
			 	j = j + 1
			end
		end
		if not continue then
		--update position:
		--print(i,c.mbsize)
		c.membrane[i] = c.membrane[i] + c.membraneVel[i]*dt + 0.5*c.membraneAcc[i]*dt*dt --update x
		c.membrane[i+1] = c.membrane[i+1] + c.membraneVel[i+1]*dt + 0.5*c.membraneAcc[i+1]*dt*dt --update y
		--boundaries:
		if c.membrane[i] < xmin then c.membrane[i] = xmin+2; c.dir = c.dir + math.pi
		elseif c.membrane[i] > xmax then c.membrane[i] = xmax-2; c.dir = c.dir + math.pi end
		if c.membrane[i+1] < ymin then c.membrane[i+1] = ymin+2; c.dir = c.dir + math.pi
		elseif c.membrane[i+1] > ymax then c.membrane[i+1] = ymax-2; c.dir = c.dir + math.pi end
		--calculating acceleration:
		
		local accn = acc + 80*(math.random() - 0.5)
		newax = newax + accn*math.cos(dir)
		neway = neway + accn*math.sin(dir)
		
		--print(c.springs[(i+1)/2])
		
		--Hooke's law for spring connecting c.membrane point to c.nucleus:
		local distance = math.sqrt((c.membrane[i]-c.nucleus.x)^2 + (c.membrane[i+1]-c.nucleus.y)^2)
		local force = -kNucSpring*(distance-c.springs[(i+1)/2]) -- -kNucSpring*(distance-nucSpringLength)
		--if 1 == i or 13 == i then force = -kNucSpring*(distance-nucSpringLength*1.75) end
		local theta = math.atan2(c.membrane[i+1]-c.nucleus.y,c.membrane[i]-c.nucleus.x)
		newax = newax + (force/distance)*math.cos(theta)
		neway = neway + (force/distance)*math.sin(theta)
		nax = nax - --[[0.5*]](force/distance)*math.cos(theta)
		nay = nay - --[[0.5*]](force/distance)*math.sin(theta)
		
		--Hooke's law for springs connecting to adjacent points:
		--preceding:
		local otherx = 0
		local othery = 0
		--print(i,c.mbsize)
		if 1 == i then
			otherx = c.membrane[c.mbsize-1]
			othery = c.membrane[c.mbsize]
		else
			otherx = c.membrane[i-2]
			othery = c.membrane[i-1]
		end
		distance = math.sqrt((c.membrane[i]-otherx)^2 + (c.membrane[i+1]-othery)^2)
		force = -kMemSpring*(distance-memSpringLength)
		theta = math.atan2(c.membrane[i+1]-othery,c.membrane[i]-otherx)
		newax = newax + (force/distance)*math.cos(theta)
		neway = neway + (force/distance)*math.sin(theta)
		
		--succeeding:
		if c.mbsize-1 == i then
			otherx = c.membrane[1]
			othery = c.membrane[2]
		else
			otherx = c.membrane[i+2]
			othery = c.membrane[i+3]
		end
		distance = math.sqrt((c.membrane[i]-otherx)^2 + (c.membrane[i+1]-othery)^2)
		force = -kMemSpring*(distance-memSpringLength)
		theta = math.atan2(c.membrane[i+1]-othery,c.membrane[i]-otherx)
		newax = newax + (force/distance)*math.cos(theta)
		neway = neway + (force/distance)*math.sin(theta)
		
		--damping:
		newax = newax - mediumDamping*c.membraneVel[i]
		neway = neway - mediumDamping*c.membraneVel[i+1]
		
		--update velocity:
		c.membraneVel[i] = c.membraneVel[i] + (c.membraneAcc[i]+newax)*dt/2 --update vx
		c.membraneVel[i+1] = c.membraneVel[i+1] + (c.membraneAcc[i+1]+neway)*dt/2 --update vy
		c.membraneAcc[i] = newax
		c.membraneAcc[i+1] = neway
		i = i + 2
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