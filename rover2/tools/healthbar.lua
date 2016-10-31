--A general use healthbar that displays a background, a bar that changes colors as it decreases/increases, and text
--Does not need to be used for health; can be HP, MP, stamina, fuel, shields, whatever.  Even just a progress bar if you want



local zBuffer = require("tools.zBuffer")



local healthbarScript = {}

function healthbarScript.create(x, y, width, height, z, font) --x and y are center
	local healthbar

	local function init()
		local textOptions --Do this first (need center x, y that was passed in for this)
		if font then
			textOptions = {text = "", x = x, y = y, font = font}
		else
			textOptions = {text = "", x = x, y = y, font = native.systemFont}
		end

		x, y = x - width / 2, y - height / 2 --Adjust given coordinates from center to upper left (makes a few things easier)

		healthbar = display.newRect(x, y, width, height) --The healthbar background
		healthbar.anchorX, healthbar.anchorY = 0, 0
		healthbar.zBuffer, healthbar.z = zBuffer, z
		zBuffer.add(healthbar, z + 1)
		healthbar.objType = "Healthbar Background"

		healthbar.filling = display.newRect(x + 1, y + 1, width - 2, height - 2) --The main part of the healthbar (the part that changes; the filling)
		healthbar.filling.anchorX, healthbar.filling.anchorY = 0, 0
		zBuffer.add(healthbar.filling, z)
		healthbar.filling.objType = "Healthbar Filling"

		healthbar.text = display.newText(textOptions) --The label (the actual text; uses an empty string by default and must be set using setText() method if you want text)
		healthbar.text:setFillColor(textR, textG, textB, textA)
		zBuffer.add(healthbar.text, -3)
		healthbar.text.objType = "Healthbar text"

		healthbar.setBackgroundColor(0, 0, 0, 1) --Default to black
		healthbar.setFullColor(0, .8, 0, 1) --Default to green
		healthbar.setEmptyColor(1, 0, 0, 1) --Default to red
		healthbar.setTextColor(1, 1, 1, 1) --Default to white
		healthbar.set(100) --Start out full by default
	end
	init()



	function healthbar.setBackgroundColor(r, g, b, a)
		healthbar:setFillColor(r, g, b, a)
	end

	function healthbar.setFullColor(r, g, b, a)
		healthbar.fullR, healthbar.fullG, healthbar.fullB, healthbar.fullA = r, g, b, a
	end

	function healthbar.setEmptyColor(r, g, b, a)
		healthbar.emptyR, healthbar.emptyG, healthbar.emptyB, healthbar.emptyA = r, g, b, a
	end

	function healthbar.setTextColor(r, g, b, a)
		healthbar.text:setFillColor(r, g, b, a)
	end

	function healthbar.setText(string)
		healthbar.text.text = string
	end

	function healthbar.set(percent) --Give it a value from 0 (empty) to 100 (full)
		healthbar.percent = percent
		if healthbar.percent < 0 then --Limit the given value
			healthbar.percent = 0
		end
		if healthbar.percent > 100 then
			healthbar.percent = 100
		end

		percent = percent / 100

		if percent == 0 then --Empty; set alpha to 0 because we can't set xScale to 0
			healthbar.filling.alpha = 0
		else --Not empty
			--Blend filling color based on empty color, full color, and current percentage filled
			healthbar.filling:setFillColor(
				healthbar.fullR * percent + healthbar.emptyR * (1 - percent),
				healthbar.fullG * percent + healthbar.emptyG * (1 - percent),
				healthbar.fullB * percent + healthbar.emptyB * (1 - percent),
				healthbar.fullA * percent + healthbar.emptyA * (1 - percent))

			healthbar.filling.alpha = healthbar.emptyA
			healthbar.filling.xScale = percent
		end
	end

	return healthbar
end

return healthbarScript
