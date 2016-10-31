local terrain = {}



function terrain.create(act, group, level)
	if level == 1 then
		local r = display.newRect(act.xCenter, act.yCenter + 100, 1000000, 15)
		physics.addBody(r, "static", {bounce = 0, friction = 1000000})
		group:insert(r)

		for i = -500000, 500000, 10 do
			r = display.newRect(i, act.yCenter + 90, 5, 5)
			group:insert(r)
		end
		for i = -500000, 500000, 100 do
			r = display.newRect(i, act.yCenter + 60, 50, 50)
			group:insert(r)
		end
		for i = -500000, 500000, 400 do
			r = display.newRect(i, act.yCenter - 100, 200, 200)
			group:insert(r)
		end

		r = display.newRect(act.xCenter + 1000, act.yCenter + 100, 100, 15)
		physics.addBody(r, "static", {bounce = 0, friction = 1000000})
		r.rotation = -30
		group:insert(r)

		r = display.newRect(act.xCenter + 1500, act.yCenter + 100, 100, 15)
		physics.addBody(r, "static", {bounce = 0, friction = 1000000})
		r.rotation = 30
		group:insert(r)
	elseif level == 2 then	-- Flat runway
		local r = display.newRect(act.xCenter, act.yCenter + 100, 1000000, 15)
		physics.addBody(r, "static", {bounce = 0, friction = 1000000})
		group:insert(r)

		for i = -500000, 500000, 10 do
			r = display.newRect(i, act.yCenter + 90, 5, 5)
			group:insert(r)
		end
		for i = -500000, 500000, 100 do
			r = display.newRect(i, act.yCenter + 60, 50, 50)
			group:insert(r)
		end
		for i = -500000, 500000, 400 do
			r = display.newRect(i, act.yCenter - 100, 200, 200)
			group:insert(r)
		end
	end
end



return terrain
