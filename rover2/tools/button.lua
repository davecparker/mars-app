--A general use button that calls a function you pass it when it is pressed



local buttonScript = {}



function buttonScript.create(x, y, width, height, zBuffer, z, string, buttonFunction)
	local button = display.newRect(x, y, width, height) --The button background (and collision box)

	local function init()
		local textOptions = {text = string, x = x, y = y, font = native.systemFont} --The button text/label
		button.text = display.newText(textOptions)

		if zBuffer and z then
			button.zBuffer, button.z = zBuffer, z
			zBuffer.add(button, z)
			button.objType = "Button"

			button.text.objType = "Button text"
			zBuffer.add(button.text, z - 1)
		end

		button.func = buttonFunction --The function (argument) that is run when button is pressed
		button:addEventListener("tap", button.func) --This is where we set the function to the button

		button.setColor(0, 0, 0, 1) --Default to black

		button:addEventListener("touch", touch) --Defined below
	end

	

	function button.setTextColor(r, g, b, a) --White by default
		button.text:setFillColor(r, g, b, a)
	end

	function button.setColor(r, g, b, a)
		button:setFillColor(r, g, b, a)
	end

	function button.touch() --This simply consumes the touch event (we use the tap event instead; see above)
		return true
	end



	init()



	return button
end

return buttonScript
