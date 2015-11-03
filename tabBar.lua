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

-- The tab bar widget and info
local tabBar          -- the tab bar widget
local selectedTab     -- the tab id of the currently selected tab

-- The tab bar buttons
local buttons = {
    { id = "mainAct",    defaultFile = "media/game/map.png" },
    { id = "resources",  defaultFile = "media/game/gauge.png"  },
    { id = "documents",  defaultFile = "media/game/folder.png" },
    { id = "messages",   defaultFile = "media/game/messages.png" },
    { id = "menu",       defaultFile = "media/game/menu.png", selected = true, },
}

-- Table that keeps track of the currnet act viewed on each tab, indexed by tab id.
-- If an entry is nil, the default (act = id) is used.
local currentActForTab = {}


-- Handle tab bar button events
local function handleTabBarEvent( event )
    -- Go to the current (or default) act for this tab
    selectedTab = event.target._id
    local act = currentActForTab[selectedTab] or selectedTab  -- tab id is default act
    game.gotoAct( act )
end

-- Initialize the app tab bar on the bottom of the screen
function initTabBar()
    -- Assign properties common to all buttons and set the selectedTab
    local dxyIcon = game.dyTabBar - 10
    for i = 1, #buttons do
        local b = buttons[i]
        b.onPress = handleTabBarEvent
        b.overFile = b.defaultFile
        b.width = dxyIcon
        b.height = dxyIcon
        if b.selected then
            selectedTab = b.id
        end
    end
    assert( selectedTab )

    -- Create the tab bar widget
    tabBar = widget.newTabBar
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
end

-- Set the current act for the currently selected tab to name
function game.setCurrentTabAct( name )
    currentActForTab[selectedTab] = name
end

-- Select the given tab (1 = main tab) on the tab bar, and press it if press is true
function game.selectGameTab( index, press )
    tabBar:setSelected( index, press )
    selectedTab = buttons[index].id
end

-- Create and return a new item indicator badge at the given screen position, initially hidden
function game.createBadge( x, y )
    local badge = display.newCircle( x, y, 5)
    badge:setFillColor( 1, 1, 0 ) -- yellow fill
    badge:setStrokeColor( 0 )     -- black frame
    badge.strokeWidth = 1
    badge.alpha = 0
    badge.showing = false
    return badge
end

-- Show the given badge if it is not already showing
function game.showBadge( badge )
    assert( badge )
    if not badge.showing then
        transition.fadeIn( badge, { time = 200 } )
        badge.showing = true
    end
end

-- Hide the given badge if it exists and is showing
function game.hideBadge( badge )
    if badge and badge.showing then
        transition.fadeOut( badge, { time = 200 } )
        badge.showing = false
    end
end


-- Init and return the tab bar
initTabBar()
return tabBar
