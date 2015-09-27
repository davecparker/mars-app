-----------------------------------------------------------------------------------------
--
-- tabBar.lua
--
-- Create and handle the tab bar widget on the bottom of the screen
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )


-- Handle tab bar button events
local function handleTabBarEvent( event )
    local tab = event.target._id
    game.gotoAct( tab )     -- button id is the Lua module name to run
end

-- The tab bar buttons
local buttons = {
    { id = "mainAct",    defaultFile = "media/game/map.png" },
    { id = "resources",  defaultFile = "media/game/gauge.png"  },
    { id = "documents",  defaultFile = "media/game/folder.png" },
    { id = "messages",   defaultFile = "media/game/messages.png" },
    { id = "menu",       defaultFile = "media/game/menu.png", selected = true, },
}

-- Assign properties common to all buttons
local dxyIcon = game.dyTabBar - 10
for i = 1, #buttons do
    local b = buttons[i]
    b.onPress = handleTabBarEvent
    b.overFile = b.defaultFile
    b.width = dxyIcon
    b.height = dxyIcon
end

-- Create the tab bar widget
local tabBar = widget.newTabBar
{
	left = game.xMin,
    top = game.yMax - game.dyTabBar,
    width = game.width,
    height = game.dyTabBar,
    backgroundFile = "media/game/redGradient.png",
    tabSelectedLeftFile = "media/game/darkRed.png",
    tabSelectedRightFile = "media/game/darkRed.png",
    tabSelectedMiddleFile = "media/game/darkRed.png",
    tabSelectedFrameWidth = 10,
    tabSelectedFrameHeight = game.dyTabBar - 10,
    buttons = buttons,
}

-- Select the given tab (1 = main tab) on the tab bar, and press it if press is true
function game.selectGameTab( index, press )
    tabBar:setSelected( index, press )
end


-- Return the tab bar in case the caller needs it
return tabBar
