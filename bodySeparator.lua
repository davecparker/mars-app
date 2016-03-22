------------------------------------------------------------------------------------------------------------------------
--Convex Separator for Box2D Flash for Corona SDK
--The original class has been written by Antoan Angelov.
--This LUA port was done by Ragdog Studios SRL (http://www.ragdogstudios.com)
--It is designed to work with Erin Catto's Box2D physics library implementation in Corona SDK (http://www.coronalabs.com)
--Everybody can use this software for any purpose, under two restrictions:
--1. You cannot claim that you wrote this software.
--2. You cannot remove or alter this notice.

--How to use it:

--local bodySeparator = require "bodySeparator";
--local shape = {x1, y1, x2, y2, x3, y3....}; --your series of points
--local polygon = display.newPolygon(240, 160, shape); --can be any display object
--bodySeparator.addNonConvexBody(polygon, {shape = shape, bodyType = "static", bounce = 0, friction = 1, density = 1});
------------------------------------------------------------------------------------------------------------------------

local bodySeparator = {};

local reverseIfClockewise, reverseTable, calcShapes, validate, hitRay, hitSegment, isOnSegment, pointsMatch, isOnLine, det, err;

reverseIfClockwise = function(points)
  local lastIndex = 1;
  local totalPoints = #points;
  for i = 2, totalPoints do
    local currPoint = points[i];
    local lastPoint = points[lastIndex];
    if (currPoint.y < lastPoint.y) or ((currPoint.y == lastPoint.y) and (currPoint.x > lastPoint.x)) then
      lastIndex = i
    end
  end
  local index1 = ((lastIndex-2)%totalPoints)+1;
  local index2 = ((lastIndex-1)%totalPoints)+1;
  local index3 = ((lastIndex)%totalPoints)+1;
  local point1 = points[index1];
  local point2 = points[index2];
  local point3 = points[index3];
  if  (((point2.x-point1.x)*(point3.y-point1.y))-((point3.x-point1.x)*(point2.y-point1.y))) <= 0 then
    local dumTab = {};
    for i = 1, totalPoints do
      dumTab[totalPoints+1-i] = points[i];
    end
    return dumTab
  else
    return points;
  end
end

reverseTable = function(tab)
  local size = #tab;
  local newTable = {}
 
  for i = 1, size do
    newTable[i] = tab[size-i+1];
  end
 
  return newTable
end

calcShapes = function(vertices)
  local vec;
  local i, n, j;
  local d, t, dx, dy, minLen;
  local i1, i2, i3, p1, p2, p3;
  local j1, j2, v1, v2, k, h;
  local vec1, vec2;
  local v, hitV;
  local isConvex;
  local figsVec = {};
  local queue = {vertices};
  
  while #queue > 0 do
    vec = queue[1];
    n = #vec;
    isConvex = true;
    
    for i = 1, n, 1 do
      i1 = i;
      i2 = (i < n) and i+1 or i+1-n;
      i3 = (i < n-1) and i+2 or i+2-n;
      
      p1 = vec[i1];
      p2 = vec[i2];
      p3 = vec[i3];
      
      d = det(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
      if (d < 0) then
        isConvex = false;
        minLen = 8.9884656743116e+307;
        for j = 1, n, 1 do
          if j ~= i1 and j ~= i2 then
            j1 = j;
            j2 = (j < n) and j+1 or 1;
            v1 = vec[j1];
            v2 = vec[j2];
            
            v = hitRay(p1.x, p1.y, p2.x, p2.y, v1.x, v1.y, v2.x, v2.y);
            
            if (v) then
              dx = p2.x-v.x;
              dy = p2.y-v.y;
              t = dx*dx+dy*dy;
              if t < minLen then
                h = j1;
                k = j2;
                hitV = v;
                minLen = t;
              end
            end
          end
        end
        
        if minLen == 8.9884656743116e+307 then err(1); end
        
        vec1 = {};
        vec2 = {};
        
        j1 = h;
        j2 = k;
        v1 = vec[j1];
        v2 = vec[j2];
        
        if (not pointsMatch(hitV.x, hitV.y, v2.x, v2.y)) then
          vec1[#vec1+1] = hitV;
        end
        if (not pointsMatch(hitV.x, hitV.y, v1.x, v1.y)) then
          vec2[#vec2+1] = hitV;
        end
        
        h = 0;
        k = i1;
        while true do
          if k ~= j2 then
            vec1[#vec1+1] = vec[k];
          else
            if h < 1 or h > n then err(2); end
            
            if (not isOnSegment(v2.x, v2.y, vec[h].x, vec[h].y, p1.x, p1.y)) then
              vec1[#vec1+1] = vec[k];
            end
            break;
          end
          
          h = k;
          if k-1 < 1 then
            k = n;
          else
            k = k-1;
          end
        end
        
        vec1 = reverseTable(vec1);
        
        h = 0;
        k = i2;
        while true do
          if k ~= j1 then
            vec2[#vec2+1] = vec[k];
          else
            if h < 1 or h > n then err(3) end
            if k == j1 and not isOnSegment(v1.x, v1.y, vec[h].x, vec[h].y, p2.x, p2.y) then
              vec2[#vec2+1] = vec[k];
            end
            break;
          end
          
          h = k;
          if k+1 > n then
            k = 1;
          else
            k = k+1;
          end
        end
        
        queue[#queue+1] = vec1;
        queue[#queue+1] = vec2;
        table.remove(queue, 1);
        break;
      end
    end
    
    if isConvex then
      figsVec[#figsVec+1] = queue[1];
      table.remove(queue, 1);
    end
  end
  
  return figsVec;
end

hitRay = function(x1, y1, x2, y2, x3, y3, x4, y4)
  local t1 = x3-x1;
  local t2 = y3-y1;
  local t3 = x2-x1;
  local t4 = y2-y1;
  local t5 = x4-x3;
  local t6 = y4-y3;
  local t7 = t4*t5-t3*t6;
  
  local a = (((t5*t2)-t6*t1)/t7);
  local px = x1+a*t3;
  local py = y1+a*t4;
  local b1 = isOnSegment(x2, y2, x1, y1, px, py);
  local b2 = isOnSegment(px, py, x3, y3, x4, y4);
  
  if (b1 and b2) then
    return {x = px, y = py};
  end
  return nil;
end

hitSegment = function(x1, y1, x2, y2, x3, y3, x4, y4)
  local t1 = x3-x1;
  local t2 = y3-y1;
  local t3 = x2-x1;
  local t4 = y2-y1;
  local t5 = x4-x3;
  local t6 = y4-y3;
  local t7 = t4*t5-t3*t6;
  
  local a = (((t5*t2)-t6*t1)/t7);
  local px = x1+a*t3;
  local py = y1+a*t4;
  local b1 = isOnSegment(px, py, x1, y1, x2, y2);
  local b2 = isOnSegment(px, py, x3, y3, x4, y4);
  
  if (b1 and b2) then
    return {x = px, y = py};
  end
  return nil;
end

isOnSegment = function(px, py, x1, y1, x2, y2)
  local b1 = ((((x1+0.1) >= px) and px >= x2-0.1) or (((x1-0.1) <= px) and px <= x2+0.1));
  local b2 = ((((y1+0.1) >= py) and py >= y2-0.1) or (((y1-0.1) <= py) and py <= y2+0.1));
  return ((b1 and b2) and isOnLine(px, py, x1, y1, x2, y2));
end

pointsMatch = function(x1, y1, x2, y2) 
  local dx = (x2 >= x1) and x2-x1 or x1-x2;
  local dy = (y2 >= y1) and y2-y1 or y1-y2;
  return ((dx < 0.1) and dy < 0.1);
end

isOnLine = function(px, py, x1, y1, x2, y2)
  if ((((x2-x1) > 0.1) or x1-x2>0.1)) then
    local a = (y2-y1)/(x2-x1);
    local possibleY = a*(px-x1)+y1;
    local diff;
    if possibleY > py then
      diff = possibleY-py;
    else
      diff = py-possibleY;
    end
    return (diff<0.1);
  end
  return (((px-x1)<0.1) or x1-px<0.1);
end

det = function(x1, y1, x2, y2, x3, y3)
  return x1*y2+x2*y3+x3*y1-y1*x2-y2*x3-y3*x1;
end

err = function(where)
  print(where);
  assert(false, "An error has occured in the creation of the non-convex body shape");
end

bodySeparator.addNonConvexBody = function(object, params)
  local physics = require "physics";
  
  local verticesVec = {};
  
  local minimumX, minimumY = 8.9884656743116e+307, 8.9884656743116e+307;
  
  local n = #params.shape;
  local count = 1;
  for i = 1, n, 2 do
    verticesVec[count] = {x = params.shape[i], y = params.shape[i+1]};
    if params.shape[i] < minimumX then
      minimumX = params.shape[i];
    end
    if params.shape[i+1] < minimumY then
      minimumY = params.shape[i+1];
    end
    count = count+1;
  end

  local figsVec;
  
  verticesVec = reverseIfClockwise(verticesVec);
  
  figsVec = calcShapes(verticesVec);
  
  physics.start();
  --physics.setDrawMode("hybrid");
  
  n = #figsVec;
  
  local finalShapes = {};
  for i = 1, n do
    local shape = {};
    for a = 1, #figsVec[i] do
      shape[#shape+1] = figsVec[i][a].x-object.width*.5-minimumX;
      shape[#shape+1] = figsVec[i][a].y-object.height*.5-minimumY;
    end
    finalShapes[#finalShapes+1] = {bounce = params.bounce, friction = params.friction, density = params.density, shape = shape};
  end

  physics.addBody(object, params.bodyType or "dynamic", unpack(finalShapes));
end

return bodySeparator;