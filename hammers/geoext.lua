local fun = require 'luarocks/fun'
local geoext = {}
geoext.logger = hs.logger.new('geoext')

-- TODO: complete the frameCover function

-- return frame list that visible from frameA covered by frameB
-- both frameA and frameB should be table conform with hs.geometry type
function geoext.frameCover(frameA, frameB)
  local x1 = hs.min(frameA.x1, frameA.x2)
  local x2 = hs.max(frameA.x1, frameA.x2)
  local y1 = hs.min(frameA.y1, frameA.y2)
  local y2 = hs.max(frameA.y1, frameA.y2)
  local xx1 = hs.min(frameB.x1, frameB.x2)
  local xx2 = hs.max(frameB.x1, frameB.x2)
  local yy1 = hs.min(frameB.y1, frameB.y2)
  local yy2 = hs.max(frameB.y1, frameB.y2)

  local rs = {}

  if geoext.pointInFrame() then
  end
end

function geoext.pointInFrame(x, y, frameA)
  local x1 = hs.min(frameA.x1, frameA.x2)
  local x2 = hs.max(frameA.x1, frameA.x2)
  local y1 = hs.min(frameA.y1, frameA.y2)
  local y2 = hs.max(frameA.y1, frameA.y2)

  return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

return geoext
