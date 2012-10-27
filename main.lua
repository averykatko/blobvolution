love.filesystem.load("defs.lua")()
love.filesystem.load("cell.lua")()

function love.load()
	time = 0
	paused = false
	xmin = 0 -- -100
	ymin = 0 -- -100
	xmax = love.graphics.getWidth() -- + 100
	ymax = love.graphics.getHeight() -- + 100
	debugPts = {} --array of coord pairs to mark
	nInitCells = 5 --5
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
	inithp = 10
	player = {x = 200, y = 150, vx = 0, vy = 0, ax = 0, ay = 0, dir = 0, hp = inithp, lives = 3, hitTime = 0, fireTime = 0}
	plen = 5
	bullets = {}
	cells = {}
	for i = 1,nInitCells do
       cells[i] = newCell(112*i, 103*i)
	end
	love.graphics.setBackgroundColor(128,128,255)
	--love.graphics.setBackgroundColor(0,0,128)
	love.graphics.setColor(255,255,255,255)
end

function fNucSpringLength(c)
	return nucSpringLength --(nucSpringLength*c.mbsize/2)/(2*math.pi)
end



function love.update(dt)
	if paused then return end
	time = time + dt
	player.hitTime = player.hitTime - dt
	if player.hitTime < 0 then player.hitTime = 0 end
	--print(time,1/dt)
	--for i,c in ipairs(cells) do
	debugPts = {}
	local i = 1
	while i <= table.getn(cells) do
		if cells[i] then
			updateCell(i,dt)
			if table.getn(cells[i].membrane) < 6 then
				table.remove(cells,i)
				print("DESTROYED:",i)
			else
				i = i + 1
			end
		else i = i + 1 end
	end
	
	local mx,my = love.mouse.getPosition()
	if USECAM then
		mx = mx + player.x - love.graphics.getWidth()/2
		my = my + player.y - love.graphics.getHeight()/2
	end
	player.dir = math.atan2(my-player.y,mx-player.x)
	if love.mouse.isDown("l","r") then fire(mx,my) end
	
	local md = nil
	if love.keyboard.isDown("right","f") then
		if love.keyboard.isDown("up","e") then md = 1.75*math.pi
		elseif love.keyboard.isDown("down","d") then md = 0.25*math.pi
		else md = 0 end
	elseif love.keyboard.isDown("left","s") then
		if love.keyboard.isDown("up","e") then md = 1.25*math.pi
		elseif love.keyboard.isDown("down","d") then md = 0.75*math.pi
		else md = math.pi end
	elseif love.keyboard.isDown("up","e") then md = 1.5*math.pi
	elseif love.keyboard.isDown("down","d") then md = 0.5*math.pi end
	
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
	
	player.fireTime = player.fireTime - dt
	if player.fireTime < 0 then player.fireTime = 0 end
	
	print("cells:",table.getn(cells),"bullets:",table.getn(bullets))
	
	--bullets
	local i = 1
	while i <= table.getn(bullets) do
		local b = bullets[i]
		if(b.timer <= 0) then
			table.remove(bullets,i)
		else
			b.x = b.x + b.vx * dt
			b.y = b.y + b.vy * dt
			b.timer = b.timer - dt
			i = i + 1
		end
	end
	
	--if love.keyboard.isDown("escape") then love.graphics.toggleFullscreen() end
end

function love.keypressed(key)
	if "p" == key then paused = not paused
	elseif "escape" == key then love.graphics.toggleFullscreen() end
end

function hitPlayer(damage)
	if 0 == player.hitTime then
		player.hp = player.hp - damage
		player.hitTime = 1
		if player.hp <= 0 then
			player.lives = player.lives - 1
			player.hp = inithp
			if player.lives < 0 then
			end
		end
	end
end

function fire(x,y)--love.mousepressed(x,y,button)
	if 0 == player.fireTime then
		--player.dir = math.atan2(y-player.y,x-player.x)
		local proj = {}
		local vel = 200
		proj.x = player.x
		proj.y = player.y
		proj.vx = vel * math.cos(player.dir)
		proj.vy = vel * math.sin(player.dir)
		proj.timer = 10 --#seconds until projectile is destroyed (to avoid having thousands of stray bullets cause lag (esp. w/ collision checks)
		table.insert(bullets,proj)
		player.fireTime = 1/6
	end
end

function love.draw()
	--love.graphics.scale(3,3)
	--love.graphics.scale(2,2)
	if USECAM then
		local height,width = love.graphics.getHeight(),love.graphics.getWidth()
		love.graphics.translate(-player.x+width/2,-player.y+height/2)
	end
	--draw bullets:
	for i,b in ipairs(bullets) do
		love.graphics.setColor(255,255,0,255)
		love.graphics.circle("fill",b.x,b.y,2)
	end
	--draw player:
	love.graphics.push()
	if 0 == player.hitTime then
		love.graphics.setColor(255,255,0,255)
	else
		love.graphics.setColor(255,0,0,255)
	end
	love.graphics.translate(player.x,player.y)
	love.graphics.rotate(player.dir)
	love.graphics.translate(-player.x,-player.y)
	love.graphics.polygon("fill",player.x+2*plen,player.y, player.x-2*plen,player.y+plen, player.x-2*plen,player.y-plen)
	love.graphics.pop()
	for i,c in ipairs(cells) do
		drawCell(c)
	end
	for i,p in ipairs(debugPts) do love.graphics.circle("fill",p.x,p.y,p.r) end
	love.graphics.print("HP: " .. player.hp .. "   Lives: " .. player.lives , 0,0)
end