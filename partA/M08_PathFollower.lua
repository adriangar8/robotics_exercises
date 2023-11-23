-- L1 Path Follower
-- By:      Lluis Ribas-Xirgo
--          Universitat Autonoma de Barcelona
-- Date:    September 2023
-- License: Creative Commons, BY-SA = attribution, share-alike
--          [https://creativecommons.org/licenses/by-sa/4.0/]

-- L1 UI interface
L1_UI = {}
L1_UI.xml = [[
  <ui title="L1 User Interface" resizable="true"
      style="background-color:lightBlue"
  >
    <group layout="vbox" flat="true">
    
    <group layout="hbox" flat="true">
    <button id="9" text="FOLLOW" style="background-color:lightGreen"
      on-click="L1_UI.followPressed" />
    <label text="Path:" />
    <edit	id="90" value="0 5 90 5 90 5 90 5 90 0"
      on-editing-finished="L1_UI.updatePath"
      style="background-color:white"
    />
    </group>
    
    <group layout="hbox" flat="true">
    
    <group layout="vbox" flat="true">
    <group layout="hbox" flat="true">
    <label text="Angle" />
    <edit	id="110" value="0"
      on-editing-finished="L1_UI.updateAtext"
      style="background-color:white"
    />
    <label text="deg" />
    </group>
    <hslider id="115" minimum="-90" maximum="90" value="0" 
      tick-interval="10" tick-position="below" on-change="L1_UI.updateAslider" />
    <group layout="hbox" flat="true">
    <label text="Distance" />
    <edit	id="120" value="0"
      on-editing-finished="L1_UI.updateDtext"
      style="background-color:white"
    />
    <label text="cm" />
    </group>        
    <hslider id="125" minimum="0" maximum="255" value="0" 
      tick-interval="10" tick-position="below" on-change="L1_UI.updateDslider" />
    <group layout="hbox" flat="true">
    <button id="1" text="GO" style="background-color:lightGreen"
      on-click="L1_UI.GO" />
    <button id="4" text="HALT" style="background-color:red"
      on-click="L1_UI.HALT" />
    </group>
    <group layout="hbox" flat="true">
    <button id="2" text="LIDAR" style="background-color:lightGreen"
      on-click="L1_UI.LIDAR" />
    <button id="3" text="RESUME" style="background-color:lightGreen"
      on-click="L1_UI.RESUME" />
    </group>
    </group>

    <group layout="vbox" flat="true">
    <label text="From L0: "/>
    <text-browser id="40" text="..."
       html="false" read-only="true" style="align:left"
    />
    <!--tree id="40" show-header="false" style="align:left">
      <row> <item> ... </item> </row>
    </tree-->
    </group>
    
    </group>

    </group>
  </ui>
]]
if sim then
  L1_UI.handle = simUI.create(L1_UI.xml)
  simUI.setPosition(L1_UI.handle, 50, 400)
  L1_UI.path = simUI.getEditValue(L1_UI.handle, 90)
end -- if
L1_UI.follow_req = false
L1_UI.follow_text = "FOLLOW"
L1_UI.angle = 0
L1_UI.radius = 0
L1_UI.C = nil
L1_UI.L0msg = "..."
L1_UI.followPressed = function(ui, id)
  L1_UI.follow_req = true 
end -- L2ui.explorePressed
L1_UI.updatePath = function(uiHandle, id, newValue)
  L1_UI.path = newValue
end
L1_UI.updateAtext = function(uiHandle, id, newValue)
  local angle = tonumber(newValue)
  if angle then
    if angle < -90 then angle = -90 end
    if angle > 90 then angle = 90 end
    L1_UI.angle = angle
    simUI.setSliderValue(uiHandle, 115, angle)
  else
    angle = L1_UI.angle
  end
  simUI.setEditValue(uiHandle, 110, string.format("%d", angle))
end
L1_UI.updateAslider = function(uiHandle, id, newValue)
  L1_UI.angle = newValue
  simUI.setEditValue(uiHandle, 110, string.format("%d", newValue))
end
L1_UI.updateDtext = function(uiHandle, id, newValue)
  local radius = tonumber(newValue)
  if radius then
    if radius < 0 then radius = 0 end
    if radius > 255 then radius = 255 end
    L1_UI.radius = radius
    simUI.setSliderValue(uiHandle, 125, radius)
  else
    radius = L1_UI.radius
  end
  simUI.setEditValue(uiHandle, 120, string.format("%d", radius))
end
L1_UI.updateDslider = function(uiHandle, id, newValue)
  L1_UI.radius = newValue
  simUI.setEditValue(uiHandle, 120, string.format("%d", newValue))
end
L1_UI.GO = function(uiHandle, id)
  L1_UI.C = string.format("1 %d %d", L1_UI.angle, L1_UI.radius)
end
L1_UI.HALT = function(uiHandle, id) L1_UI.C = "4" end
L1_UI.LIDAR = function(uiHandle, id) L1_UI.C = "2" end
L1_UI.RESUME = function(uiHandle, id) L1_UI.C = "3" end
L1_UI.getFollow = function(self)
  local state = false
  if self.follow_text=="FOLLOW" then
    if self.follow_req then
      self.follow_req = false
      self.follow_text = "STOP"
      simUI.setButtonText(self.handle, 9, self.follow_text)
      simUI.setStyleSheet(self.handle, 9, "background-color:red")
      state = true
    end
  end -- if
  return state
end
L1_UI.getStop = function(self)
  local state = false
  if self.follow_text=="STOP" then
    if self.follow_req then
      self.follow_req = false
      self.follow_text = "FOLLOW"
      simUI.setButtonText(self.handle, 9, self.follow_text)
      simUI.setStyleSheet(self.handle, 9, "background-color:lightGreen")
      state = true
    end
  end -- if
  return state
end
L1_UI.setFollow = function(self)
  self.follow_text = "FOLLOW"
  simUI.setButtonText(self.handle, 9, self.follow_text)
  simUI.setStyleSheet(self.handle, 9, "background-color:lightGreen")
end  
L1_UI.getPath = function(self)
  return self.path
end
L1_UI.setA = function(self, angle)
  if angle then
    if angle<-90 then angle = -90
    elseif angle>90 then angle = 90 end
    self.angle = angle
    simUI.setEditValue(self.handle, 110, string.format("%d", angle))
    simUI.setSliderValue(self.handle, 115, angle)
  end
end
L1_UI.setD = function(self, radius)
  if radius then
    if radius<0 then radius = 0 end
    if radius>255 then radius = 255 end
    self.radius = radius
    simUI.setEditValue(self.handle, 120, string.format("%d", radius))
    simUI.setSliderValue(self.handle, 125, radius)
  end
end
L1_UI.getC = function(self)
  local C = self.C
  self.C = nil
  return C
end
L1_UI.appendM = function(self, M)
  self.L0msg = M..'\n'..self.L0msg
  simUI.setText(self.handle, 40, self.L0msg)
end
L1_UI.appendM2 = function(self, M)
  local col = simUI.getColumnCount(self.handle, 40)
  simUI.addTreeItem(self.handle, 40, col, {M})
end

-- uncomment to hide UI ***
--if sim then simUI.hide(L1_UI.handle) end

local PathFollower = {
  state = {},
  I = nil, -- instruction by user
  W = nil, -- input L2 instruction
  T = nil, -- input L2 path (trail)
  R = nil, -- reply from L0
  C = {}, -- command to L0
  D = {}, -- data from sensor
  J = {}, -- index of P
  P = {}, -- path to follow 
  Q = {}, -- backup path 
  A = {}, -- answer to L2
  z = nil,-- reset 'follow' button
  forward = function(self)
    self.state.curr = self.state.next
    self.A.curr = self.A.next
    self.C.curr = self.C.next
    self.D.curr = self.D.next
    self.P.curr = self.P.next
    self.Q.curr = self.Q.next
    self.J.curr = self.J.next
    self.z = (self.state.curr=="BEGIN")
    local extout = false
    if self.C.curr and #self.C.curr>0 then
      extout = true
    end -- if
    return extout
  end, 
  init = function(self, initial_path)
    self.constant_path = initial_path -- constant for standalone, console simulation
    self.T = initial_path or {}
    self.state.prev = "NONE"
    self.state.next = "NEXT" --[[ CHANGE TO "INIT" FOR COPPELIASIM --]]
    self.P.next = self.T
    self.Q.next = nil
    self.J.next = 1
    self.C.next = ""; self.D.next = ""; self.A.next = ""
    self:forward()
  end,
  read_inputs = function(self, C)
    self.robots = sim.getInt32Signal("L0L1robots")
    local line = ""
    local reply = sim.getStringSignal("L0L1")
    if reply and reply~="" then
      local i = 0
      while(i < #reply) do
        i = i + 1
        if(string.sub(reply, i, i) ~= "\n") then
          line = line .. string.sub(reply, i, i)
        else 
          L1_UI:appendM(line)
          line = ""
       end -- if
      end -- while
      if line~="" then L1_UI:appendM(line) end
    else
      reply = nil
    end -- if
    self.R = reply
    local userinput = L1_UI:getC()
    if userinput then self.I = userinput else self.I = "" end
    if C==nil or #C==0 then -- check button follow pressed
      if L1_UI:getFollow() then
        C = "F "..L1_UI:getPath()
      elseif L1_UI:getStop() then
        C = "Q"
      end -- if
    end -- if
    if C and #C>0 then
      self.W = string.sub(C, 1, 1)
      if self.W=="F" then
        local numbers = {}
        for w in string.gmatch(C, "-?%d+") do
          table.insert(numbers, tonumber(w))
        end -- for
        local trail = {}
        local i = 1
        while i<#numbers do
          if -90>numbers[i] then numbers[i]=-90 end
          if numbers[i]>90 then numbers[i]=90 end
          if 0>numbers[i+1] then numbers[i+1]=0 end
          if numbers[i+1]>255 then numbers[i+1]=255 end
          table.insert(trail, string.format("1 %d %d",
            math.floor(numbers[i]), math.floor(numbers[i+1])))
          i = i + 2
        end -- while
        table.insert(trail, "")
        self.T = trail
      elseif self.W=="S" then -- sweep
        self.T = nil
      elseif self.W=="Q" then -- quit current operation
        self.T = nil
      else -- not dealt with
        self.W = nil
        self.T = nil
      end -- if
    else
      self.W = nil
      self.T = nil
    end -- if
    if self.T==nil then self.T = self.constant_path end
  end,
  monitor = function(self)
    local pj = "nil"
    if self.P.curr and self.P.curr[self.J.curr] then pj = self.P.curr[self.J.curr] end
    println(string.format("# PathFollower: state = %s P[%d] = %s",
      self.state.curr, self.J.curr, pj ) )
    if self.W then println("                W = " .. self.W) end
    if self.R then println("                R = " .. self.R) end
    if self.A.curr and #self.A.curr>0 then
      println(             "                A = " .. self.A.curr )
    end -- if
    if self.C.curr and #self.C.curr>0 then
      println(             "                C = " .. self.C.curr )
    end -- if
  end,
  cmonitor = function(self)
    if (self.state.prev~=self.state.curr) then
      self.state.prev = self.state.curr; self.monitor( self )
    end -- if
  end,
  step = function(self)
    local change = true -- to account for variable changes, including main state
    if self.state.curr=="INIT" then
      if self.robots>0 then
        self.P.next = { "1 90 0", "1 -90 0" }
        self.J.next = 1
        self.C.next = ""
        self.state.next = "NEXT"
      else
        change = false
      end -- if
    elseif self.state.curr=="NEXT" then
      
        --[[ ******* TO COMPLETE ******* --]]   
      
      --[[ ******* CODE HINTS ******* --]]
      --[[
      -- n1 gets the first positive integer of the reply from L0, self.R
      local n1 = (tonumber(string.match(self.R or "", "%d+")) or 0)
      -- n2 gets the second integer of instruction string self.P.curr[self.J.curr]
      local n2 = (tonumber(string.match(self.P.curr[self.J.curr] or "", "%d+[^%d]*(-?%d+)")) or 0)
      -- n3 gets the third  positive integer of instruction string self.P.curr[self.J.curr]
      local n3 = (tonumber(string.match(self.P.curr[self.J.curr] or "",
        "%d+[^%d]*-?%d+[^%d]*(%d+)")) or 0)
      -- inserts element into next value of table Q, self.Q.next
      table.insert(self.Q.next, "1 90 0")
      --]]

      -- Complete the code here
      local n1 = (tonumber(string.match(self.R or "", "%d+")) or 0)
      local n2 = (tonumber(string.match(self.P.curr[self.J.curr] or "", "%d+[^%d]*(-?%d+)")) or 0)
      local n3 = (tonumber(string.match(self.P.curr[self.J.curr] or "", "%d+[^%d]*-?%d+[^%d]*(%d+)")) or 0)
      table.insert(self.Q.next, string.format("%d %d %d", n1, n2, n3))

    else -- STOP or ERROR or anything else
      self.C.next = ""
      self.J.next = -1
      self.state.next = "STOP"
    end -- if chain
    return change
  end,
  write_outputs = function(self)
    if self.C.curr and #self.C.curr>0 then
      sim.setStringSignal("L1L0", self.C.curr)
      local numbers = {}
      for w in string.gmatch(self.C.curr, "-?%d+") do
          table.insert(numbers, tonumber(w))
      end -- for
      if #numbers>0 and numbers[1]==1 then -- update menu's data
        L1_UI:setA(numbers[2])
        L1_UI:setD(numbers[3])
      end -- if
    else
      sim.setStringSignal("L1L0", "")
    end -- if
    if self.z then L1_UI:setFollow() end
  end,
  get_Answer = function(self)
    local A = ""
    if self.A.curr and #self.A.curr>0 then
      A = self.A.curr
    end -- if
    return A
  end,    
  active = function(self)
    if self.state.curr == "INIT" or self.state.curr == "NEXT" then
      -- Check if the simulation is running in stand-alone mode
      if not sim then
        -- Add your stand-alone simulation logic here
        -- For example, you can simulate the robot's movement or perform any other actions
        -- Return true if the simulation is active, false otherwise
        return true
      end
    end

    -- Return the original condition if not in stand-alone mode
    return self.state.curr == "INIT" or self.state.curr == "NEXT"
  end
} -- PathFollower

if sim then
  return PathFollower
else
  -- CHANGE I/O TO CONSOLE
  PathFollower.read_inputs = function(self)
    self.W = nil
    io.write("> PathFollower: R (reply from L0) = ")
    local reply = io.read()
    if reply and #reply>0 then self.R = reply else self.R = nil end 
  end -- PathFollower.read_inputs
  PathFollower.monitor = function(self)
    local pj = "nil"
    if self.P.curr[self.J.curr] then pj = self.P.curr[self.J.curr] end
    io.write(string.format("# PathFollower: state = %s P[%d] = %s\n",
      self.state.curr, self.J.curr, pj))
    if self.Q.curr and #self.Q.curr>0 then
      io.write(string.format("# PathFollower.Q = {"))
      local i = 1; while i<=#self.Q.curr do
        io.write(self.Q.curr[i]); i = i + 1
        if i<=#self.Q.curr then io.write(", ") end
      end -- while
      io.write("}\n")
    end -- if
  end -- PathFollower.monitor
  PathFollower.write_outputs = function(self)
    if self.C.curr and #self.C.curr>0 then
      io.write(string.format("< PathFollower: C = %s\n", self.C.curr))
    end -- if
  end -- PathFollower.write_outputs
  -- SIMULATION ENGINE
  -- * SETUP
  PathFollower:init({"1 0 10", "1 90 10", "1 90 10", "1 90 10", "1 90 0"})
  -- * MAIN LOOP
  Xvar = true; sT = 0; dT = 0.05; C = 0
  Xout = PathFollower:forward()
  io.write(string.format("Time = %.2fs Cycle = %04i:\n", sT, C))
  while PathFollower:active() do
    if Xvar then PathFollower:monitor() end -- if
    if Xout or not Xvar then
      PathFollower:write_outputs()
      C = 0; sT = sT + dT
    end -- if
    PathFollower:read_inputs(C)
    Xvar = PathFollower:step()
    Xout = PathFollower:forward()
    io.write(string.format("Time = %.2fs Cycle = %04i:\n", sT, C))
    C = C + 1
  end -- while
  PathFollower:monitor()
  PathFollower:write_outputs()
  io.write( "Program exited!\n" )
end -- if
