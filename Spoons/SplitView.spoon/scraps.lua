   -- local thisapp,otherapp=thiswin:application(),otherwin:application()

   
   -- self.appsToHide, self.winsToTeleport={},{}

   -- local filter=hs.window.filter.new()
   -- filter:setScreens(screen:id())
   -- local wins=filter:getWindows()
   -- filter:pause()
   -- for _,w in pairs(wins) do
   --    local wa=w:application()
   --    if w~=thiswin and w~=otherwin and w:id() and w:isVisible() and not w:isMinimized() then
   -- 	 if (wa==thisapp and w~=thiswin) or (wa==otherapp and w~=otherwin) then
   -- 	    self.winsToTeleport[w:id()]=w -- same app, but different window, teleport it
   -- 	 end
   --    end 
   --    if (wa~=thisapp and wa~=otherapp) then self.appsToHide[wa:pid()]=wa end
   -- end

   -- -- Hide and/or remove everything else
   -- for _,ah in pairs(self.appsToHide) do
   --    if self.debug then print("Hiding ",ah:name()) end
   --    ah:hide() 
   -- end

   -- if next(self.winsToTeleport)~=nil then
   --    local uuid=screen:spacesUUID()
   --    self.thisSpace=spaces.spacesByScreenUUID(spaces.masks.currentSpaces)[uuid][1]
   --    local toSpace=hs.fnutils.find(spaces.layout()[uuid], 
   -- 				    function(x) -- first other user space
   -- 				       return spaces.spaceType(x)==spaces.types.user and
   -- 				       x~=self.thisSpace end)
   --    if not toSpace then
   -- 	 self:createSpace(uuid,frame, -- async!
   -- 			  function (toSpace)
   -- 			     self:teleport(toSpace)
   -- 			     self:doUISplitView(frame,thiswin,otherwin)
   -- 	 end)
   -- 	 return
   --    else self:teleport(toSpace) end
   -- end
   -- self:doUISplitView(frame,thiswin,otherwin)

-- Teleport self.winsToTeleport to another space
-- function obj:teleport(toSpace)
--    for _,wm in pairs(self.winsToTeleport) do
--       if self.debug then print("Teleporting: ",wm:title()) end
--       wm:spacesMoveTo(toSpace)
--    end
-- end 

--- Internal method to actually perform the Split View UI interactions
-- function obj:doUISplitView(frame,thiswin,otherwin)
--    thiswin:setTopLeft(frame.x,frame.y)
--    local wsz=otherwin:size()  -- move to RHS for repeatable click target
--    otherwin:setTopLeft(frame.x+frame.w/2+(frame.w/2-wsz.w)/2,
-- 		       frame.y+(frame.h-wsz.h)/2)
--    local clickPoint = thiswin:zoomButtonRect()
--    hsee.newMouseEvent(hsee.types.leftMouseDown, clickPoint):post()
--    hst.doAfter(
--       self.delayZoomHold, -- hold green button to activate SV!
--       function()
-- 	 local cnt=0
-- 	 local winProp=ax.windowElement(thiswin)
-- 	 hsee.newMouseEvent(hsee.types.leftMouseUp,clickPoint):post() -- finish
-- 	 print("Frame Before: ",hs.inspect(winProp:frame()))
-- 	 hst.waitUntil(
-- 	    function() -- wait until it's full screen
-- 	       print("Waiting for win FullScreen -- ",thiswin:isFullScreen())
-- 	       cnt=cnt+1
-- 	       if cnt<5 then return false end -- abort
-- 	       return winProp:fullScreen()
-- 	    end,
-- 	    function()			        -- then click the other screen
-- 	       local cnt=0
-- 	       local owinProp=ax.windowElement(otherwin)
-- 	       hse.leftClick({x=frame.x + frame.w*3/4,y=frame.y + frame.h/2})
-- 	       hst.waitUntil(
-- 		  function()  -- wait for other to go full
-- 		     print("Waiting for oWin FullScreen -- ",otherwin:isFullScreen())
-- 		     cnt=cnt+1
-- 		     if cnt>20 then return true end -- abort
-- 		     return owinProp:fullScreen()
-- 		  end, 
-- 		  function()				-- then restore apps/wins
-- 		     for _,ah in pairs(self.appsToHide) do ah:unhide() end
-- 		     for _,w in pairs(self.winsToTeleport) do w:spacesMoveTo(self.thisSpace) end
-- 		  end, self.checkInterval)
-- 	    end,self.checkInterval)
--    end)
-- end
