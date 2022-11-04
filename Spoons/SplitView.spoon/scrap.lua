
-- SplitView:createSpace(screenUUID,frame,callback)
-- Internal method to create a space, working around a bug in spaces screen-based creation
-- spaces.createScreen() always creates a space on the primary screen.
-- Use accessibility, if available, as a backup option for secondary screens.
-- This method works asynchronously, and when the new space is ready,
-- calls `callback` with the new space ID.
function obj:createSpace(scrUUID,frame,callback)
   if scrUUID==hs.screen.primaryScreen():spacesUUID() then -- simple case
      callback(spaces.createSpace()) -- always creates on primary
      return
   end

   hs.application.open("Mission Control")
   local layout=spaces.layout()[scrUUID]
   local spaces, newSpaceButton=self:spaceButtons(frame)
   if not newSpaceButton then return end
   
   newSpaceButton:doPress();

   -- Find the new space id
   local layoutRev={}
   for _,v in pairs(layout) do layoutRev[v]=true end
   local newSpace=hs.fnutils.find(spaces.layout()[scrUUID],
				  function(x) return not layoutRev[x] end)
   -- Wait for new mini window to show
   
   hst.waitUntil(
      function() return #self:spaceButtons(frame) > #spaces end,
      function()
	 local prop=ax.windowElement(self.thiswin)
	 hse.keyStroke({},"ESCAPE")
	 hst.waitWhile( 
	    function() return self:spaceButtons(frame) end,
	    function() callback(newSpace) end, self.checkInterval)
      end,self.checkInterval)
   return
end 


-- The AXList throws AXUIElementDestroyed when a space is closed, and an AXCreated when one is added (!)

   -- mcObserver=ax.observer.new(self.dockAX:pid()):
   -- 			       addWatcher(sbl,'AXUIElementDestroyed'):
   -- 			       callback(function(oo,elem,noti,_)
   -- 				     print("Received ",noti," for ", elem)
   -- 				     spaceDestroyed = true
   -- 			       end):start())
   
   --local spaceDestroyed = false
   --local mcObserver

