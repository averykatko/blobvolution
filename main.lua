function love.load()
	time = 0
	nInitCells = 1 --5
	nCells = nInitCells
	dist = 7
	kbacc = 13
	charge = 1
	ke = 0.01
	kNucSpring = 15
	nucSpringLength = 18
	nucSpringDamping = 0
	kMemSpring = 20
	memSpringLength = 7
	memSpringDamping = 0
	mediumDamping = 2
	drag = 1
	player = {x = 200, y = 150, vx = 0, vy = 0, ax = 0, ay = 0, dir = 0}
	plen = 5
	bullets = {}
	cells = {}
	for i = 1,nInitCells do
		cells[i] = {}
		cells[i].nucleus = {x=112*i,y=103*i,vx=0,vy=0,ax=0,ay=0}
		cells[i].membrane = {100,100; 105,95; 110,95; 115,90; 120,95; 120,100; 125,105; 125,110; 120,115; 115,115; 110,110; 105,110; 100,105}
		cells[i].mbsize = table.getn(cells[i].membrane)
		for j = 1,cells[i].mbsize do
			cells[i].membrane[j] = cells[i].membrane[j] * i
		end
		cells[i].springs = {}
		for j = 1,13 do cells[i].springs[j] = fNucSpringLength(cells[i]) end
		cells[i].membraneVel = { }
		for j = 1,cells[i].mbsize do
			cells[i].membraneVel[j] = 0 --set initial velocities to zero
		end
		--membraneVel[1] = 0.5
		--membraneVel[2] = 0.5
		cells[i].membraneAcc = { }
		for j = 1,cells[i].mbsize do
			cells[i].membraneAcc[j] = 0 --set initial acceleration to zero
		end
		cells[i].genes = {}
		cells[i].genes.growtime = 2 --1 --time to grow a new node, in seconds
		cells[i].genes.splitnodes = 18 --18 --# membrane nodes to divide at
		cells[i].genes.speed = 15 --15 --movement speed
		cells[i].genes.attackdist = 25 --how close it has to be to player to attack
		cells[i].genes.bombgrav = 0 --how attracted (+) or repelled (-) it is by bombs
		cells[i].genes.attackstyle = "bump" --either "bump" or "engulf"
		cells[i].genes.acidity = 0 --how much player is damaged when inside cell
		cells[i].genes.damagestyle = "shrink" --either "shrink" or "split"
		
		cells[i].gtimer = 0 --in seconds
		cells[i].dir = math.random()*2*math.pi --movement direction
	end
	love.graphics.setBackgroundColor(128,128,255)
	--love.graphics.setBackgroundColor(0,0,128)
	love.graphics.setColor(255,255,255,255)
end

function fNucSpringLength(c)
	return nucSpringLength --(nucSpringLength*c.mbsize/2)/(2*math.pi)
end

function updateCell(_n,dt)
	local c = cells[_n]
	--print(c.membrane[1],c.membrane[2],c.membrane[mbsize-1],c.membrane[mbsize])
	--print(c.nucleus.x,c.nucleus.y,c.nucleus.vx,c.nucleus.vy,c.nucleus.ax,c.nucleus.ay)
	c.gtimer = c.gtimer + dt
	if c.gtimer >= c.genes.growtime then --grow
		c.gtimer = c.gtimer - c.genes.growtime --reset timer
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
	
	--BEGIN MITOSIS:
	if c.mbsize/2 >= c.genes.splitnodes then --mitosis!
		--[[io.write("c: {")
		for itr = 1,c.mbsize do io.write(c.membrane[itr]," ") end
		io.write("}\n")]]
		local split = (c.mbsize/2)+1 --divide in two; currently just midpoint; should do random split maybe?
		print("split:",split)
		local oldc = c
		io.write("oldc: {")
		for itr = 1,oldc.mbsize do io.write(oldc.membrane[itr]," ") end
		io.write("}\n")
		print(oldc)
		c = {}
		c.membrane = {}
		print(c,oldc)
		c.membraneVel = {}
		c.membraneAcc = {}
		c.springs = {}
		c.nucleus = {}
		local newcell = {}
		newcell.membrane = {}
		newcell.membraneVel = {}
		newcell.membraneAcc = {}
		newcell.springs = {}
		newcell.nucleus = {}
		for i = 1,split-1 do
			--print(oldc.membrane[i])
			c.membrane[i] = oldc.membrane[i]
			--print(c.membrane[i])
			c.membraneVel[i] = oldc.membraneVel[i]
			c.membraneAcc[i] = oldc.membraneAcc[i]
			--[[if (math.floor(i/2) ~= i/2) then
				c.springs[(i+1)/2] = oldc.springs[(i+1)/2]
			end]]
		end
		for i = split,oldc.mbsize do
			newcell.membrane[i+1-split] = oldc.membrane[i]
			print(newcell.membrane[i+1-split])
			newcell.membraneVel[i+1-split] = oldc.membraneVel[i]
			newcell.membraneAcc[i+1-split] = oldc.membraneAcc[i]
			--[[if (math.floor(i/2) ~= i/2) then
				newcell.springs[(i+2-split)/2] = oldc.springs[(i+1)/2]
			end]]
			--[[table.insert(newcell.membrane,i,table.remove(c.membrane,i))
			table.insert(newcell.membraneVel,i,table.remove(c.membraneVel,i))
			table.insert(newcell.membraneAcc,i,table.remove(c.membraneAcc,i))
			if (math.floor(i/2) ~= i/2) then --since springs array has half as many elements
				table.insert(newcell.springs,(i+1)/2,table.remove(c.springs,(i+1)/2))
			end]]
		end
		--add extra node
		c.membrane[split] = oldc.nucleus.x
		c.membrane[split+1] = oldc.nucleus.y
		c.membraneVel[split] = oldc.nucleus.vx
		c.membraneVel[split+1] = oldc.nucleus.vy
		c.membraneAcc[split] = oldc.nucleus.ax
		c.membraneAcc[split+1] = oldc.nucleus.ay
		
		--[[newcell.membrane[oldc.mbsize+1-split] = oldc.nucleus.x
		newcell.membrane[oldc.mbsize+1-split+1] = oldc.nucleus.y
		newcell.membraneVel[(oldc.mbsize+1)-split] = oldc.nucleus.vx
		newcell.membraneVel[(oldc.mbsize+2)-split] = oldc.nucleus.vy
		newcell.membraneAcc[(oldc.mbsize+1)-split] = oldc.nucleus.ax
		newcell.membraneAcc[(oldc.mbsize+2)-split] = oldc.nucleus.ay]]
		
		c.mbsize = table.getn(c.membrane)
		for itr = 1,c.mbsize/2 do c.springs[itr] = fNucSpringLength(c) end
		io.write("c: {")
		for itr = 1,c.mbsize do io.write(c.membrane[itr]," ") end
		io.write("}\n")
		newcell.mbsize = table.getn(newcell.membrane)
		
		newcell.membrane[newcell.mbsize+1] = oldc.nucleus.x
		newcell.membrane[newcell.mbsize+2] = oldc.nucleus.y
		newcell.membraneVel[newcell.mbsize+1] = oldc.nucleus.vx
		newcell.membraneVel[newcell.mbsize+2] = oldc.nucleus.vy
		newcell.membraneAcc[newcell.mbsize+1] = oldc.nucleus.ax
		newcell.membraneAcc[newcell.mbsize+2] = oldc.nucleus.ay
		
		newcell.mbsize = table.getn(newcell.membrane)
		for itr = 1,newcell.mbsize/2 do newcell.springs[itr] = fNucSpringLength(newcell) end
		print("n mbsz",newcell.mbsize)
		io.write("newcell: {")
		for itr = 1,newcell.mbsize do io.write(newcell.membrane[itr]," ") end
		io.write("}\n")
		local cnx = 0
		local cny = 0
		local j = 1
		while j < c.mbsize do
			cnx = cnx + c.membrane[j]
			cny = cny + c.membrane[j+1]
			j = j + 2
		end
		--[[newcell.nucleus.x = cnx/(c.mbsize/2)
		newcell.nucleus.y = cny/(c.mbsize/2)]]
		c.nucleus.x = cnx/(c.mbsize/2)
		c.nucleus.y = cny/(c.mbsize/2)
		c.nucleus.vx = oldc.nucleus.vx -- / 2
		c.nucleus.vy = oldc.nucleus.vy -- / 2
		c.nucleus.ax = oldc.nucleus.ax --0
		c.nucleus.ay = oldc.nucleus.ay --0
		local nnx = 0
		local nny = 0
		local j = 1
		while j < newcell.mbsize do
			nnx = nnx + newcell.membrane[j]
			nny = nny + newcell.membrane[j+1]
			j = j + 2
		end
		--[[c.nucleus.x = nnx/(newcell.mbsize/2)
		c.nucleus.y = nny/(newcell.mbsize/2)]]
		newcell.nucleus.x = nnx/(newcell.mbsize/2)
		newcell.nucleus.y = nny/(newcell.mbsize/2)
		newcell.nucleus.vx = oldc.nucleus.vx -- / 2
		newcell.nucleus.vy = oldc.nucleus.vy -- / 2
		newcell.nucleus.ax = oldc.nucleus.ax --0
		newcell.nucleus.ay = oldc.nucleus.ay --0
		
		--TODO: mutations
		c.genes = {}
		c.gtimer = 0
		newcell.genes = {}
		newcell.gtimer = 0
		
		for k,v in pairs(oldc.genes) do
			c.genes[k] = v
			newcell.genes[k] = v
		end
		c.genes.acidity = c.genes.acidity + math.random(-5,5)
		newcell.genes.acidity = newcell.genes.acidity + math.random(-5,5)
		
		c.dir = math.random()*2*math.pi
		newcell.dir = math.random()*2*math.pi
		
		cells[_n] = c
		nCells = nCells + 1
		cells[nCells] = newcell
		--table.insert(cells,newcell)
	end
	--END MITOSIS.
	
	--c.nucleus acc
	local nax = 0
	local nay = 0
	
	--acceleration for constant speed
	local acc = mediumDamping * c.genes.speed
	local dir = c.dir
	--[[if love.keyboard.isDown("right","left","down","up") then
		acc = mediumDamping * c.genes.speed
		if love.keyboard.isDown("right") then dir = 0 end
		if love.keyboard.isDown("left") then dir = math.pi  end
		if love.keyboard.isDown("down") then dir = 0.5*math.pi end
		if love.keyboard.isDown("up") then dir = 1.5*math.pi end
	end]]
	nax = nax + acc*math.cos(dir)
	nay = nay + acc*math.sin(dir)
	
	--Verlet integration
	local i = 1
	while i < c.mbsize do
		--update position:
		--print(i,c.mbsize)
		c.membrane[i] = c.membrane[i] + c.membraneVel[i]*dt + 0.5*c.membraneAcc[i]*dt*dt --update x
		c.membrane[i+1] = c.membrane[i+1] + c.membraneVel[i+1]*dt + 0.5*c.membraneAcc[i+1]*dt*dt --update y
		--calculating acceleration:
		local newax = 0
		local neway = 0
		
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
		print(i,c.mbsize)
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
	end

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

function love.update(dt)
	time = time + dt
	--print(time,1/dt)
	for i,c in ipairs(cells) do
		updateCell(i,dt)
	end
	
	local mx,my = love.mouse.getPosition()
	player.dir = math.atan2(my-player.y,mx-player.x)
	
	local md = nil
	if love.keyboard.isDown("right") then
		if love.keyboard.isDown("up") then md = 1.75*math.pi
		elseif love.keyboard.isDown("down") then md = 0.25*math.pi
		else md = 0 end
	elseif love.keyboard.isDown("left") then
		if love.keyboard.isDown("up") then md = 1.25*math.pi
		elseif love.keyboard.isDown("down") then md = 0.75*math.pi
		else md = math.pi end
	elseif love.keyboard.isDown("up") then md = 1.5*math.pi
	elseif love.keyboard.isDown("down") then md = 0.5*math.pi end
	
	local nax,nay = 0,0
	
	if md then
		--[[local acc = 50
		nax = nax + acc * math.cos(md)
		nay = nay + acc * math.sin(md)]]
		local vel = 120
		player.vx = vel * math.cos(md)
		player.vy = vel * math.sin(md)
	else
		player.vx = 0
		player.vy = 0
	end
	
	--nax = nax - 0.01 * player.vx^2
	--nay = nay - 0.01 * player.vy^2
	
	player.x = player.x + player.vx*dt + player.ax*dt*dt/2
	player.y = player.y + player.vy*dt + player.ay*dt*dt/2
	player.vx = player.vx + (player.ax+nax)*dt/2
	player.vy = player.vy + (player.ay+nay)*dt/2
	
	--bullets
	for i,b in ipairs(bullets) do
		b.x = b.x + b.vx * dt
		b.y = b.y + b.vy * dt
	end
end

function love.mousepressed(x,y,button)
	player.dir = math.atan2(y-player.y,x-player.x)
	local proj = {}
	local vel = 200
	proj.x = player.x
	proj.y = player.y
	proj.vx = vel * math.cos(player.dir)
	proj.vy = vel * math.sin(player.dir)
	table.insert(bullets,proj)
end

function love.draw()
	--love.graphics.scale(3,3)
	love.graphics.scale(2,2)
	--draw bullets:
	for i,b in ipairs(bullets) do
		love.graphics.setColor(255,255,0,255)
		love.graphics.circle("fill",b.x,b.y,2)
	end
	--draw player:
	love.graphics.push()
	love.graphics.setColor(255,255,0,255)
	love.graphics.translate(player.x,player.y)
	love.graphics.rotate(player.dir)
	love.graphics.translate(-player.x,-player.y)
	love.graphics.polygon("fill",player.x+2*plen,player.y, player.x-2*plen,player.y+plen, player.x-2*plen,player.y-plen)
	love.graphics.pop()
	for i,c in ipairs(cells) do
		local red = 0
		local green = 0
		if c.genes.acidity > 0 then
			--red = 4*c.genes.acidity
			green = -4*c.genes.acidity
		elseif c.genes.acidity < 0 then
			red = -4*c.genes.acidity
			--green = 4*c.genes.acidity
		end
		love.graphics.setColor(255-red,255-green,255-red-green,64)
		love.graphics.polygon("fill",c.membrane)
		love.graphics.setColor(255,255,255,255)
		love.graphics.polygon("line",c.membrane)
		love.graphics.circle("line",c.nucleus.x,c.nucleus.y,2,10)
	end
end