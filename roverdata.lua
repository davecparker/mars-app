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
data.mapGrp = nil 				-- display group for map display objects
data.mapZoomGrp = nil			-- display group for map objects subject to zooming/panning
data.dynamicGrp = nil 			-- display group for dynamic scroll-view objects

-----------------------------------------------------------------------------------------
-- Terrain variables
-----------------------------------------------------------------------------------------
data.terrain = {} 				-- basic terrain objects
data.shape = {} 				-- terrain obstacle shapes
data.craterHeightMap = {}		-- crater height values
data.courseHeightMap = {}		-- course height values
data.cratersOnCourse = {}
data.defaultElevation = nil 	-- terrain elevation
data.nextX = -220				-- x-coordinate for the next terrain object
data.basicTerrainObjWidth = 50	-- basic terrain object width
data.nObstacles = 25			-- total number of obstacles 
data.courseHeightIndex = 1					-- course height array index
data.terrainColor = { 0.8, 0.35, 0.25 }		-- terrain color
data.obstacleColor = { 0.3, 0.1, 0.1 }		-- obstacle color
data.removalSensor = nil					-- terrain removal sensor display object
data.mapToMarsScale = 2610  	-- map-to-Mars scale based on Sinai Planum image actual length of ~460km
data.sideToMarsScale = 0.00005 	-- side-to-map scale based on rover length of 15.3'
data.mapScaleFactor = 0.25		-- map-to-Mars scaling; set to 1 for actual scale; increase for greater terrain scale
data.mapSpeedFactor = 25		-- side-to-map scaling; set to 1 for actual scale; increase for greater rover map speed
data.craterResolution = 30		-- crater terrain object width
data.craterHeightScale = 0.08	-- crater height scaling
data.maxCraterHeight = nil
data.drawingCrater = false		-- true when a crater is to be drawn
data.elevationFactor = 0.25
data.craterMarkers = {}

-----------------------------------------------------------------------------------------
-- Rover variables
-----------------------------------------------------------------------------------------
data.rover = nil 			-- rover display object
data.wheelSprite = {} 		-- rover wheel display objects
data.roverPosition = 100

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
data.zoomInButton = nil
data.zoomOutButton = nil
data.speedText = nil		-- speed display object
data.scrollViewTop = nil
data.scrollViewBtm = nil


return data
