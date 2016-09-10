-----------------------------------------------------------------------------------------
--
-- roverdata.lua
--
-- Contains a table of common data for the rover activity of the Mars App
--
-----------------------------------------------------------------------------------------

local data = {}

data.act = nil

-----------------------------------------------------------------------------------------
-- Display groups
-----------------------------------------------------------------------------------------
data.staticBgGrp = nil			-- display group for static background display objects
data.staticFgGrp = nil			-- display group for static foreground display objects
data.displayPanelGrp = nil		-- display group for the display panel
data.ctrlPanelGrp = nil			-- display group for the control panel
data.mapGrp = nil 				-- display group for map display objects not subject to zooming/panning
data.mapZoomGrp = nil			-- display group for map display objects subject to zooming/panning
data.dynamicGrp = nil 			-- display group for dynamic scroll-view objects

-----------------------------------------------------------------------------------------
-- Terrain variables
-----------------------------------------------------------------------------------------
data.terrain = {} 				-- basic terrain objects
data.shape = {} 				-- terrain obstacle shapes
data.craterHeightMap = {}		-- crater height values
data.courseHeightMap = {}		-- course height values
data.cratersOnCourse = {}		-- craters that are intercepted by the current course
data.defaultElevation = nil 	-- default terrain elevation; set in init() in rover.lua
data.nextX = -220				-- x-coordinate for the next terrain object
data.basicTerrainObjWidth = 50	-- basic terrain object width
data.nObstacles = 25			-- total number of obstacles 
data.courseHeightIndex = 1					-- course height table index
data.terrainColor = { 0.8, 0.35, 0.25 }		-- terrain color
data.obstacleColor = { 0.3, 0.1, 0.1 }		-- obstacle color
data.removalSensor = nil					-- terrain removal sensor display object
data.marsToMapScale = 2610  	-- Mars-to-map scale; Sinai Planum image actual length of ~460km divided by map length
data.sideToMarsScale = 0.00005 	-- side-to-Mars scale based on a rover length of 5.39 meters (320CU*(5.39M/75CU))/460KM
data.mapScaleFactor = 0.25		-- map-to-Mars scaling; set to 1 for actual scale; increase for greater terrain scale
data.mapSpeedFactor = 25		-- side-to-map scaling; set to 1 for actual scale; increase for greater rover map speed
data.craterResolution = 30		-- crater terrain physics object width
data.craterHeightScale = 0.08	-- crater height scaling
data.maxCraterHeight = nil		-- side view crater terrain height limit; set in init() in rover.lua
data.drawingCrater = false		-- true when a crater is to be drawn
data.elevationFactor = 0.25		-- allows the adjustment of side view terrain elevation
data.craterMarkers = {}			-- holds display objects representing craters recorded in game.saveState (for testing)

-----------------------------------------------------------------------------------------
-- Rover variables
-----------------------------------------------------------------------------------------
data.rover = nil 			-- rover display object
data.wheelSprite = {} 		-- rover wheel display objects
data.roverPosition = 100	-- rover position in the x-axis

-----------------------------------------------------------------------------------------
-- Control panel variables
-----------------------------------------------------------------------------------------
data.accelButton = nil
data.recoverButton = nil
data.waterButton = nil

-----------------------------------------------------------------------------------------
-- Display panel variables
-----------------------------------------------------------------------------------------
data.map = nil				-- the map display object
data.mapLength = nil 		-- overhead map width and height; set in init() in rover.lua
data.zoomInButton = nil
data.zoomOutButton = nil
data.speedText = nil		-- speed text display object
data.scrollViewTop = nil 	-- used to determine data.defaultElevation & data.maxCraterHeight. Set in init(). COULD BE LOCAL TO INIT()
data.scrollViewBtm = nil 	-- used to determine data.defaultElevation & data.maxCraterHeight. Set in init(). COULD BE LOCAL TO INIT()
data.energyGaugeSprite = {} -- energy gauge display objects
data.energyGaugeIndex = nil -- current energy gauge level

return data
