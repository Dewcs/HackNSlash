local tileinfo = dofile("tile.lua")

local scDungeon = director:createScene()

local map = {}
local mw = 78
local mh = 78

local tt = 0

local unusedTiles = {}

local drawnTiles = {}
local tileInfo = {}

local tile={}

local p0={}
local p1={}
local p2={}
local p3={}
local currarea=0

local biomeID=1


local tsize = math.floor(math.min(director.displayHeight,director.displayWidth)/6)
local rsize = math.ceil(tsize*45/math.sqrt(22.5*22.5*2))+tsize/30

local speed = 3

local spawnCount = 0
local spawns = {}

local cameraPos = {}

local centerPos = {}

local playerId = 0
local playerPos = {}

local frameID=1

local target = {}
target.x=-1
target.y=-1

function coord(x,y)
	return (x-1)*mh+y
end

function dist2P(x0,y0,x1,y1)
	return math.sqrt((x0-x1)*(x0-x1)+(y0-y1)*(y0-y1))
end

function map2char(value)
	if value==-2 then
		return ' '
	elseif value==-1 then
		return '.'
	elseif value==0 then
		return '_'
	elseif value==1 then
		return 'x'
	elseif value==2 then
		return 'S'
	elseif value==3 then
		return 'P'
	elseif value==4 then
		return 'B'
	elseif value==5 then
		return 'E'
	else
		return '@'
	end
end

function makeWay(x0,y0,x1,y1)
	if dist2P(x0,y0,x1,y1)>7 then
		-- too big ??
		local x2=math.random(math.max(math.min(x0,x1)-2,2),math.min(math.max(x0,x1)+2,mw-1))
		local y2=math.random(math.max(math.min(y0,y1)-2,2),math.min(math.max(y0,y1)+2,mh-1))
		while map[coord(x2,y2)]<0 do
			x2=math.random(math.max(math.min(x0,x1)-2,2),math.min(math.max(x0,x1)+2,mw-1))
			y2=math.random(math.max(math.min(y0,y1)-2,2),math.min(math.max(y0,y1)+2,mh-1))
		end
		makeWay(x0,y0,x2,y2)
		makeWay(x2,y2,x1,y1)
	else
		local w = math.abs(x0-x1)
		local h = math.abs(y0-y1)
		if (w+h)%2==0 and map[coord(x0,y1)]>=0 then
			for i=math.min(x0,x1),math.max(x0,x1) do
				if map[coord(i,y1)]<=0 then
					map[coord(i,y1)]=1
				end
				if y1<y0 then
					if map[coord(i,y1+1)]<=0 then
						map[coord(i,y1+1)]=1
					end
				else
					if map[coord(i,y1-1)]<=0 then
						map[coord(i,y1-1)]=1
					end
				end 
			end
			for i=math.min(y0,y1),math.max(y0,y1) do
				if map[coord(x0,i)]<=0 then
					map[coord(x0,i)]=1
				end
				if x0<x1 then
					if map[coord(x0+1,i)]<=0 then
						map[coord(x0+1,i)]=1
					end
				else
					if map[coord(x0-1,i)]<=0 then
						map[coord(x0-1,i)]=1
					end
				end 
			end
		elseif map[coord(x1,y0)]>=0 then
			for i=math.min(x0,x1),math.max(x0,x1) do
				if map[coord(i,y0)]<=0 then
					map[coord(i,y0)]=1
				end
				if y0<y1 then
					if map[coord(i,y0+1)]<=0 then
						map[coord(i,y0+1)]=1
					end
				else
					if map[coord(i,y0-1)]<=0 then
						map[coord(i,y0-1)]=1
					end
				end
			end
			for i=math.min(y0,y1),math.max(y0,y1) do
				if map[coord(x1,i)]<=0 then
					map[coord(x1,i)]=1
				end
				if x0<x1 then
					if map[coord(x1-1,i)]<=0 then
						map[coord(x1-1,i)]=1
					end
				else
					if map[coord(x1+1,i)]<=0 then
						map[coord(x1+1,i)]=1
					end
				end
			end
		else
			for i=math.min(x0,x1),math.max(x0,x1) do
				if map[coord(i,y1)]<=0 then
					map[coord(i,y1)]=1
				end
				if y1<y0 then
					if map[coord(i,y1+1)]<=0 then
						map[coord(i,y1+1)]=1
					end
				else
					if map[coord(i,y1-1)]<=0 then
						map[coord(i,y1-1)]=1
					end
				end 
			end
			for i=math.min(y0,y1),math.max(y0,y1) do
				if map[coord(x0,i)]<=0 then
					map[coord(x0,i)]=1
				end
				if x0<x1 then
					if map[coord(x0+1,i)]<=0 then
						map[coord(x0+1,i)]=1
					end
				else
					if map[coord(x0-1,i)]<=0 then
						map[coord(x0-1,i)]=1
					end
				end
			end 
		end
	end
end

function recNodes(nodes,i,g,visited)
	g[i]=1
	visited[i]=1
	for k,v in pairs(nodes[i]) do
		if v==1 and visited[k]==0 then
			g[k]=1
			recNodes(nodes,k,g,visited)
		end
	end
end

function makeGroups(nodes,spawnCount)
	local visited={}
	for i=1,spawnCount do
		visited[i]=0
	end
	-- how many groups of nodes we have?
	local groups={}
	local gid=1
	for i=1,spawnCount do
		if visited[i]==0 then
			groups[gid]={}
			recNodes(nodes,i,groups[gid],visited)
			local line=gid.." :"
			for k,v in pairs(groups[gid]) do
				line = line .. ", " .. k
			end
			dbg.print(line)
			gid=gid+1
		end
	end
	return groups
end

function spawnValid(s,total,x,y)
	for i=1,total do
		local dist=dist2P(s[i].x,s[i].y,x,y)
		if dist<=9 then
			return false
		end
	end
	return true
end

function createMap(id)
	map={}
	for i=1,mw*mh do
		map[i]=-1
		drawnTiles[i]=-1
		tileInfo[i]={}
	end
	-- nondisplay areas -2
	for i=1,(mw/2-1) do
		for j=1,i do
			map[coord(mw/2-i,j)]=-2
			map[coord(mw/2+i+1,j)]=-2
			map[coord(mw/2-i,mh-j+1)]=-2
			map[coord(mw/2+i+1,mh-j+1)]=-2
		end
	end
	-- buildable areas 0
	local maxw=math.ceil(director.displayWidth/2/tsize)
	local maxh=math.ceil(director.displayHeight/2/tsize)
	local max=math.max(maxw,maxh)+1
	local width0=2
	for i=max,mw/2 do
		for j=(mh/2-width0/2+1),(mh/2+width0/2) do
			map[coord(i,j)]=0
		end
		width0 = width0 + 2
	end
	width0 = width0 - 2
	for i=(mw/2+1),(mw-max+1) do
		for j=(mh/2-width0/2+1),(mh/2+width0/2) do
			map[coord(i,j)]=0
		end
		width0 = width0 - 2
	end
	--ready to build the map!!
	if id==-1 then
		math.randomseed( os.time() )
		-- Generate Spawns
		spawnCount=1
		spawns={}
		local dists={}
		local nodes={}
		for i=max+3,mw/2 do
			for j=(mh/2-width0/2+1),(mh/2+width0/2) do
				if spawnValid(spawns,spawnCount-1,i,j) and math.random(1,100)<=5 then
					spawns[spawnCount]={x=i,y=j,mobCount=math.random(2,5),tdist=0}
					map[coord(i,j)]=2
					spawnCount = spawnCount + 1
				end
			end
			width0 = width0 + 2
		end
		width0 = width0 - 2
		for i=(mw/2+1),(mw-max+1-3) do
			for j=(mh/2-width0/2+1),(mh/2+width0/2) do
				if spawnValid(spawns,spawnCount-1,i,j) and math.random(1,100)<=5 then
					spawns[spawnCount]={x=i,y=j,mobCount=math.random(2,5),tdist=0}
					map[coord(i,j)]=2
					spawnCount = spawnCount + 1
				end
			end
			width0 = width0 - 2
		end
		spawnCount = spawnCount - 1
		dbg.print(spawnCount)
		for i=1,spawnCount do
			-- make a room
			local rw=math.random(2,math.floor(math.sqrt(spawns[i].mobCount*3)))
			local rh=math.random(2,math.floor(math.sqrt(spawns[i].mobCount*3)))
			for l=spawns[i].x-rw,spawns[i].x+rw do
				for m=spawns[i].y-rh,spawns[i].y+rh do
					if map[coord(l,m)]<=0 then
						map[coord(l,m)]=1
					end
				end
			end
			-- precalc dists
			dists[i]={}
			nodes[i]={}
			for j=1,i-1 do
				dists[i][j]=dist2P(spawns[i].x,spawns[i].y,spawns[j].x,spawns[j].y)
				dists[j][i]=dists[i][j]
				nodes[i][j]=0
				nodes[j][i]=0
				spawns[j].tdist = spawns[j].tdist + dists[i][j]
				spawns[i].tdist = spawns[i].tdist + dists[i][j]
			end
			nodes[i][i]=0
		end
		-- Select Player Spawn farther point
		local playerSpawn=1
		for i=2,spawnCount do
			if spawns[i].tdist>spawns[playerSpawn].tdist then
				playerSpawn=i
			end
		end

		cameraPos.x=spawns[playerSpawn].x+0.5
		cameraPos.y=spawns[playerSpawn].y+0.5
		centerPos.x=spawns[playerSpawn].x+0.5
		centerPos.y=spawns[playerSpawn].y+0.5
		playerPos.x=spawns[playerSpawn].x+0.5
		playerPos.y=spawns[playerSpawn].y+0.5
		target.x=spawns[playerSpawn].x+0.5
		target.y=spawns[playerSpawn].y+0.5

		map[coord(spawns[playerSpawn].x,spawns[playerSpawn].y)]=3
		-- Select Boss Spawn closest point
		local bossSpawn=1
		for i=2,spawnCount do
			if spawns[i].tdist<spawns[bossSpawn].tdist then
				bossSpawn=i
			end
		end
		map[coord(spawns[bossSpawn].x,spawns[bossSpawn].y)]=4
		-- Select Exit farther point to player spawn
		local exitSpawn=0
		local bestDist=-1
		for i=1,spawnCount do
			if i ~= playerSpawn and i ~= bossSpawn then
				local dist=dist2P(spawns[i].x,spawns[i].y,spawns[playerSpawn].x,spawns[playerSpawn].y)
				if exitSpawn==0 or dist>bestDist then
					exitSpawn=i
					bestDist=dist
				end 
			end
		end
		map[coord(spawns[exitSpawn].x,spawns[exitSpawn].y)]=5

		-- easy ways 
		for i=1,spawnCount do
			bestId=0
			for j=1,spawnCount do
				if j~=i then
					if bestId==0 or dists[i][j]<dists[i][bestId] then
						bestId=j
					end
				end
			end
			makeWay(spawns[i].x,spawns[i].y,spawns[bestId].x,spawns[bestId].y)
			nodes[i][bestId]=1
			nodes[bestId][i]=1
		end
		-- hard ways
		-- how many groups of nodes we have?
		local groups=makeGroups(nodes,spawnCount)
		while table.getn(groups)>1 do
			-- Select the smaller group and find the closest nn group node ^^
			local smallId=0
			for i=1,table.getn(groups) do
				if smallId==0 or table.getn(groups[i])<table.getn(groups[smallId]) then
					smallId=i
				end
			end
			local bs=0
			local bo=0
			for i=1,table.getn(groups) do
				if i~=smallId then
					for ko,vo in pairs(groups[i]) do
						for ks,vs in pairs(groups[smallId]) do
							if bs==0 or dists[ko][ks]<dists[bo][bs] then
								bo=ko
								bs=ks
							end
						end
					end
				end
			end
			makeWay(spawns[bs].x,spawns[bs].y,spawns[bo].x,spawns[bo].y)
			nodes[bs][bo]=1
			nodes[bo][bs]=1
			groups=makeGroups(nodes,spawnCount)
		end 
		-- 
		dbg.print(table.getn(groups))
	end
	-- dump map
	for i=1,mw do
		local line=""
		for j=1,mh do
			line = line .. map2char(map[coord(i,j)])
		end
		dbg.print(line)
	end
end

function scDungeon:setUp(event)
    dbg.print("scDungeon:setUp")
    createMap(mapId)
    -- screen
    director.isAlphaInherited=false
    self.gui=director:createRectangle({
                 x=0, y=0,
                 w=director.displayWidth,
                 h=director.displayHeight,
                 strokeWidth=0,
                 color={255,255,255},
                 alpha=0.1,
                 zOrder=-10,
                 })
    director.addNodesToScene=false
    self.light=director:createSprite({
    x=director.displayWidth/2, y=director.displayHeight/2+tsize/2, source="antorxa.png",
    xAnchor=0.5,yAnchor=0.5,
    blendMode="normal", alpha=1,
    zOrder=-1,
    })
    local maxScale=math.max((director.displayWidth / self.light.w),(director.displayHeight / self.light.h))
    self.light.xScale = maxScale*1.5
	self.light.yScale = maxScale*1.5
    self.gui:addChild(self.light)
    --draw map
    self.map = director:createNode({x=0,y=0,w=director.displayWidth,
                 h=director.displayHeight,zOrder=-2})
    self.gui:addChild(self.map)

    prepareTile()

    for k,v in pairs(tile) do
    	drawTile(v.i,v.j)
    end

    self.goku = director:createSprite(director.displayCenterX, director.displayCenterY, "goku.png")
    self.goku.xScale=tsize/self.goku.w
    self.goku.yScale=tsize/self.goku.h
    self.goku.xAnchor=0.5
    self.goku.zOrder=3
	self.gui:addChild(self.goku)

    function self.gui:touch(event)
    	if event.phase=="began" then
    		
    		local targetMap=coordInsideMap(event.x,event.y)
    		dbg.print("touch",targetMap.x,targetMap.y)
    		if map[coord(math.floor(targetMap.x),math.floor(targetMap.y))]>0 then
    			target.x=targetMap.x
    			target.y=targetMap.y
    		end
    	end
    end
	self.gui:addEventListener('touch', self.gui)
	dbg.print("scDungeon:done")
	system:addEventListener("update", update)
	collectgarbage("collect")
end

function scDungeon:tearDown(event)
	-- TODO
    dbg.print("scDungeon:tearDown")
end

function prepareTile()
	tile={}
	local tid=1
	p0=coordInsideMap(-tsize*2,-tsize*2)
	p1=coordInsideMap(-tsize*2,director.displayHeight+tsize)
	p2=coordInsideMap(director.displayWidth+tsize*2,director.displayHeight+tsize)
	p3=coordInsideMap(director.displayWidth+tsize*2,-tsize*2)
	currarea=triangleA(p3,p0,p1)+triangleA(p2,p0,p1)
	for i=1,mw do
    	for j=1,mh do
    		if insideScreen(i,j) then
    			drawnTiles[coord(i,j)]=1
    			tile[tid]={}
    			tile[tid].i=i
    			tile[tid].j=j
    			--[[local p=coordInsideScreen(i,j)
    			tile[tid].x=p.x
    			tile[tid].y=p.y]]--
    			tid=tid+1
    		end
    	end
    end
end

function triangleA(a,b,c)
	return math.abs(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y))/2
end

function insideScreen(x,y)
	-- x,y to cameraPos.x,cameraPos.y there 1 to tsize is displayed inside screen
	-- versio amb radi
	p={x=x,y=y}
	
	local radius=math.max(director.displayWidth/2,director.displayHeight/2)/tsize+3
	local distToCamera=dist2P(x,y,cameraPos.x,cameraPos.y)
	if radius>distToCamera then
		calcarea=triangleA(p,p0,p1)+triangleA(p,p1,p2)+triangleA(p,p2,p3)+triangleA(p,p3,p0)
		if (calcarea-currarea)<0.001 then
			return true
		end
	end
	return false
end

function rota2P(x,y,side)
	if side==true then
		return {x=(x+y)/math.sqrt(2),y=(y-x)/math.sqrt(2)}
	else
		return {x=(x-y)/math.sqrt(2),y=(y+x)/math.sqrt(2)}
	end
end

function coordInsideScreen(x,y)
	-- x,y from map to x,y from screen
	t=rota2P(cameraPos.x,cameraPos.y,true)
	p=rota2P(x,y,true)
	p.x=(p.x-t.x)*tsize+director.displayWidth/2
	p.y=(p.y-t.y)*tsize+director.displayHeight/2
	return p
end

function coordInsideScreen2(x,y)
	-- x,y from map to x,y from screen
	t=rota2P(centerPos.x,centerPos.y,true)
	p=rota2P(x,y,true)
	p.x=(p.x-t.x)*tsize+director.displayWidth/2
	p.y=(p.y-t.y)*tsize+director.displayHeight/2
	return p
end

function coordInsideMap(x,y)
	t=rota2P(cameraPos.x,cameraPos.y,true)
	x=(x-director.displayWidth/2)/tsize+t.x
	y=(y-director.displayHeight/2)/tsize+t.y
	return rota2P(x,y,false)
end

function normVector(v1)
	local mod=math.sqrt(v1.x*v1.x+v1.y*v1.y)
	if mod==0 then
		return {x=0,y=0}
	end
	return {x=v1.x/mod,y=v1.y/mod}
end

function makeVector(orig,targ)
	return {x=targ.x-orig.x,y=targ.y-orig.y}
end

function round(num)
	base=math.floor(num)
	if (num-base)<0.5 then
		return base
	else 
		return base+1
	end
end

function getTile(id)
	if unusedTiles[id]==nil or #unusedTiles[id]==0 then
		tt=tt+1
		local tile=director:createSprite(0,0, tileinfo.tiles[id])
		tile.xAnchor = 0.5
		tile.yAnchor = 0.5
		tile.xScale = rsize / tile.w
		tile.yScale = rsize / tile.h
		tile.tileid=id
		return tile
	else
		local tile=unusedTiles[id][#unusedTiles[id]]
		table.remove(unusedTiles[id])
		return tile
	end
end

function drawTile(x,y)
	pos=coord(x,y)
	pt=coordInsideScreen2(x+0.5,y+0.5)
    local tid=1
    -- draw walking tiles
	if map[pos]>0 then
		tileInfo[pos][tid]=getTile(tileinfo.biomes[biomeID].floor)
		tileInfo[pos][tid].x=pt.x
		tileInfo[pos][tid].y=pt.y
		tileInfo[pos][tid].zOrder = -9
		scDungeon.map:addChild(tileInfo[pos][tid])
		tid = tid + 1
	end
	if map[pos]<=0 then
		if x<mw and map[coord(x+1,y)]>0 then
			tileInfo[pos][tid]=getTile(tileinfo.biomes[biomeID].wallb)
			tileInfo[pos][tid].x=pt.x
			tileInfo[pos][tid].y=pt.y
			tileInfo[pos][tid].zOrder = -7
			scDungeon.map:addChild(tileInfo[pos][tid])
			tid = tid + 1
		end
		if y>1 and map[coord(x,y-1)]>0 then
			tileInfo[pos][tid]=getTile(tileinfo.biomes[biomeID].walll)
			tileInfo[pos][tid].x=pt.x
			tileInfo[pos][tid].y=pt.y
			tileInfo[pos][tid].zOrder = -7
			scDungeon.map:addChild(tileInfo[pos][tid])
			tid = tid + 1
		end
	end
	if map[pos]<=0 then
		tileInfo[pos][tid]=getTile(tileinfo.biomes[biomeID].ceil)
		tileInfo[pos][tid].x=pt.x
		tileInfo[pos][tid].y=pt.y+rsize*10/22
		tileInfo[pos][tid].zOrder = -2
		scDungeon.map:addChild(tileInfo[pos][tid])
		tid = tid + 1
	end
end

function deleteTile(pos)
	for i=1,#tileInfo[pos] do
		if unusedTiles[tileInfo[pos][i].tileid]==nil then
			unusedTiles[tileInfo[pos][i].tileid]={}
		end
		table.insert(unusedTiles[tileInfo[pos][i].tileid], tileInfo[pos][i])
	end
	tileInfo[pos]={}
end

function update()
	--dbg.print(system.deltaTime,tt)
	-- update player pos
	local v1=normVector(makeVector(playerPos,target))
	playerPos.x=playerPos.x+v1.x*speed*system.deltaTime
	playerPos.y=playerPos.y+v1.y*speed*system.deltaTime
	if map[coord(math.floor(playerPos.x),math.floor(playerPos.y))]<=0 then
		if map[coord(math.floor(playerPos.x)-1,math.floor(playerPos.y))] then
			playerPos.x=math.floor(playerPos.x)
		end
		if map[coord(math.floor(playerPos.x),math.floor(playerPos.y)-1)] then
			playerPos.y=math.floor(playerPos.y)
		end
	end
	local vcheck=normVector(makeVector(playerPos,target))
	if v1.x*vcheck.x<0 or v1.y*vcheck.y<0 then
		playerPos.x=target.x
		playerPos.y=target.y
	end
	--dbg.print(v1.x,v1.y,v1.x*speed*system.deltaTime,v1.y*speed*system.deltaTime)
	-- update camera pos
	local v2=normVector(makeVector(cameraPos,playerPos))
	local dist=dist2P(cameraPos.x,cameraPos.y,playerPos.x,playerPos.y)
	local cspeed=dist+1
	cameraPos.x=cameraPos.x+v2.x*cspeed*system.deltaTime
	cameraPos.y=cameraPos.y+v2.y*cspeed*system.deltaTime
	local vcheck2=normVector(makeVector(cameraPos,playerPos))
	if v2.x*vcheck2.x<0 or v2.y*vcheck2.y<0 then
		cameraPos.x=playerPos.x
		cameraPos.y=playerPos.y
	end
	-- update char position
	local pPos1=coordInsideScreen(playerPos.x,playerPos.y)
	scDungeon.goku.x=pPos1.x
	scDungeon.goku.y=pPos1.y
	scDungeon.light.x=pPos1.x
	scDungeon.light.y=pPos1.y+tsize/2

	-- update map position
	local pPos2=coordInsideScreen(centerPos.x,centerPos.y)
	scDungeon.map.x=pPos2.x-director.displayWidth/2
	scDungeon.map.y=pPos2.y-director.displayHeight/2

	-- update tiles
	-- new tiles
	local diff={i=round(centerPos.x-cameraPos.x),j=round(centerPos.y-cameraPos.y)}
	for k,v in pairs(tile) do
		local pos=coord(v.i-diff.i,v.j-diff.j)
		if drawnTiles[pos]==-1 then
			drawTile(v.i-diff.i,v.j-diff.j)
		end
		drawnTiles[pos]=frameID
    end
	-- delete tiles
	for i=1,mw*mh do
		if drawnTiles[i]~=-1 and drawnTiles[i]~=frameID then
			deleteTile(i)
			drawnTiles[i]=-1
		end
	end
	-- garbage collect
	
	frameID=frameID+1
end

scDungeon:addEventListener({"setUp", "tearDown"}, scDungeon)
dbg.print(tileinfo.tiles[1])
return scDungeon