--require('dungeon')

scMainMenu = director:createScene()

local scOptions = director:createScene()

local scGameTown = director:createScene()

local scDungeon = dofile("dungeon.lua")

mapId = -1

function scMainMenu:setUp(event)
    dbg.print("scMainMenu:setUp")
    self.lPlay = director:createLabel(0, director.displayHeight/2+director.displayHeight/8, "Play")
    self.lOptions = director:createLabel(0, director.displayHeight/2-director.displayHeight/8, "Options")
    self.lPlay.hAlignment='center'
    self.lOptions.hAlignment='center'
    function self.lOptions:touch(event)
	    if (event.phase == 'began') then
	        director:moveToScene(scOptions, {transitionType="slideInR", transitionTime=0.5})
	    end
	end
	function self.lPlay:touch(event)
	    if (event.phase == 'began') then
	        director:moveToScene(scDungeon, {transitionType="slideInT", transitionTime=0.5})
	    end
	end
	self.lOptions:addEventListener('touch', self.lOptions)
	self.lPlay:addEventListener('touch', self.lPlay)
end
function scMainMenu:tearDown(event)
    dbg.print("scMainMenu:tearDown")
    self.lPlay = self.lPlay:removeFromParent() -- remove from the scene graph, and set self.label to nil
    self.lOptions = self.lOptions:removeFromParent()
end
scMainMenu:addEventListener({"setUp", "tearDown"}, scMainMenu)

function scOptions:setUp(event)
    dbg.print("scOptions:setUp")
    self.lBack = director:createLabel(0, 0, "Back")
    function self.lBack:touch(event)
	    if (event.phase == 'began') then
	        director:moveToScene(scMainMenu, {transitionType="slideInL", transitionTime=0.5})
	    end
	end
	self.lBack:addEventListener('touch', self.lBack)
end
function scOptions:tearDown(event)
    dbg.print("scOptions:tearDown")
    self.lBack = self.lBack:removeFromParent() -- remove from the scene graph, and set self.label to nil
end
scOptions:addEventListener({"setUp", "tearDown"}, scOptions)


--system:setFrameRateLimit(25)
director:moveToScene(scMainMenu) -- start with instantaneous change to scene1