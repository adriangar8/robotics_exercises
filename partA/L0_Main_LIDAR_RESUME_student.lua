-- L0 Open-loop control of UABotet
-- By:      Lluis Ribas-Xirgo
--          Universitat Autonoma de Barcelona
-- Date:    September 2023
-- License: Creative Commons, BY-SA = attribution, share-alike
--          [https://creativecommons.org/licenses/by-sa/4.0/]

-- L0 UI interface
L0_UI = {}
L0_UI.xml = [[
  <ui title="L0 User Interface" resizable="true"
      style="background-color:lightBlue"
  >
    <group layout="hbox" flat="true">
    <group layout="vbox" flat="true">
    <group layout="hbox" flat="true">
    <label text="Angle" />
    <edit	id="110" value="0"
      on-editing-finished="L0_UI.updateAtext"
      style="background-color:white"
    />
    <label text="deg" />
    </group>
    <hslider id="115" minimum="-90" maximum="90" value="0" 
      tick-interval="10" tick-position="below" on-change="L0_UI.updateAslider" />
    <group layout="hbox" flat="true">
    <label text="Distance" />
    <edit	id="120" value="0"
      on-editing-finished="L0_UI.updateDtext"
      style="background-color:white"
    />
    <label text="cm" />
    </group>        
    <hslider id="125" minimum="0" maximum="255" value="0" 
      tick-interval="10" tick-position="below" on-change="L0_UI.updateDslider" />
    <group layout="hbox" flat="true">
    <button id="1" text="GO" style="background-color:lightGreen"
      on-click="L0_UI.GO" />
    <button id="4" text="HALT" style="background-color:red"
      on-click="L0_UI.HALT" />
    </group>
    <group layout="hbox" flat="true">
    <button id="2" text="LIDAR" style="background-color:lightGreen"
      on-click="L0_UI.LIDAR" />
    <button id="3" text="RESUME" style="background-color:lightGreen"
      on-click="L0_UI.RESUME" />
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
  </ui>
]]
if sim then
  L0_UI.handle = simUI.create(L0_UI.xml)
  simUI.setPosition(L0_UI.handle, 50, 450)
end -- if
L0_UI.angle = 0
L0_UI.radius = 0
L0_UI.C = nil
L0_UI.L0msg = "..."
L0_UI.updateAtext = function(uiHandle, id, newValue)
  local angle = tonumber(newValue)
  if angle then
    if angle < -90 then angle = -90 end
    if angle > 90 then angle = 90 end
    L0_UI.angle = angle
    simUI.setSliderValue(uiHandle, 115, angle)
  else
    angle = L0_UI.angle
  end
  simUI.setEditValue(uiHandle, 110, string.format("%d", angle))
end
L0_UI.updateAslider = function(uiHandle, id, newValue)
  L0_UI.angle = newValue
  simUI.setEditValue(uiHandle, 110, string.format("%d", newValue))
end
L0_UI.updateDtext = function(uiHandle, id, newValue)
  local radius = tonumber(newValue)
  if radius then
    if radius < 0 then radius = 0 end
    if radius > 255 then radius = 255 end
    L0_UI.radius = radius
    simUI.setSliderValue(uiHandle, 125, radius)
  else
    radius = L0_UI.radius
  end
  simUI.setEditValue(uiHandle, 120, string.format("%d", radius))
end
L0_UI.updateDslider = function(uiHandle, id, newValue)
  L0_UI.radius = newValue
  simUI.setEditValue(uiHandle, 120, string.format("%d", newValue))
end
L0_UI.GO = function(uiHandle, id)
  L0_UI.C = string.format("1 %d %d", L0_UI.angle, L0_UI.radius)
end
L0_UI.HALT = function(uiHandle, id) L0_UI.C = "4" end
L0_UI.LIDAR = function(uiHandle, id) L0_UI.C = "2" end
L0_UI.RESUME = function(uiHandle, id) L0_UI.C = "3" end
L0_UI.setA = function(self, angle)
  if angle then
    if angle < -90 then angle = -90 end
    if angle > 90 then angle = 90 end
    self.angle = angle
    simUI.setLabelText(self.handle, 110, string.format("%d", angle))
    simUI.setSliderValue(self.handle, 115, angle)
  end
end
L0_UI.setD = function(self, radius)
  if angle then
    if radius < 0 then radius = 0 end
    if radius > 255 then radius = 255 end
    self.radius = radius
    simUI.setLabelText(self.handle, 120, string.format("%d", radius))
    simUI.setSliderValue(self.handle, 125, radius)
  end
end
L0_UI.getC = function(self)
  local C = self.C
  self.C = nil
  return C
end
L0_UI.appendM = function(self, M)
  self.L0msg = M..'\n'..self.L0msg
  simUI.setText(self.handle, 40, self.L0msg)
end

-- L0 CONTROLLER

L0Main = {}

L0Main.init = function(self)
  self.V =  1.23 -- cm/s  -- REPLACE BY VALUES FROM CoppeliaSim
  self.W = 45.67 -- deg/s -- SIMULATION!!! *************
  self.I = { 0, 0, 0 } -- Instruction table
  self.T = 0           -- Time
  self.state = {}; self.state.next = "LISTEN"
  self.B = {}; self.B.next = 0     -- Begin time 
  self.A = {}; self.A.next = nil   -- Absolute angle rotation
  self.S = {}; self.S.next = nil   -- Space/distance to move ahead
  self.L = {}; self.L.next = 0     -- DC value for left motor
  self.R = {}; self.R.next = 0     -- DC value for right motor
  self.M = {}; self.M.next = nil   -- Message to user/upper-level controllers
  self.g = {}; self.g.next = false -- Get distance to obstacle (request)
  self.P = {}; self.P.next = 0     -- Lidar servo orientation, P in [-90, 90]  
end -- L0Main.init()

L0Main.forward = function(self)
  -- Update the current state of various variables to their next values.
  -- This is typically done at the end of a frame or game loop.
  self.state.curr = self.state.next
  self.B.curr = self.B.next
  self.A.curr = self.A.next
  self.S.curr = self.S.next
  self.L.curr = self.L.next
  self.R.curr = self.R.next
  self.M.curr = self.M.next
  self.g.curr = self.g.next
  self.P.curr = self.P.next
end -- forward()

L0Main.read_inputs = function(self, D, u)
  local C = L0_UI:getC()
  if sim then
    self.T = sim.getSimulationTime()
  else -- console input
    self.T = self.T + 0.05
    io.write(string.format("> T = %.2fs or ... ", self.T))
    local newT = tonumber(io.read())
    if newT and newT>T then self.T = newT end
    io.write(string.format("> I = "))
    C = io.read()
  end -- if
  if C and #C>0 then
      local words = {}
      for w in string.gmatch(C, "-?%d+") do table.insert(words, w) end
      self.I[1] = tonumber(words[1])
      if self.I[1] then
        if self.I[1]==1 then -- GO
          if #words>1 then self.I[2] = tonumber(words[2]) end
          if #words>2 then self.I[3] = tonumber(words[3]) end
        else
          self.I[2] = 0; self.I[3] = 0
        end -- if
      end -- if
  else
      self.I[1] = 0 -- no command received
  end -- if
  if sim then
    self.Q = D or 0
    self.u = u
  elseif self.I[1] then
    io.write(string.format("> Q = %d or ... ", self.Q))
    local Q = tonumber(io.read())
    if Q then self.Q = math.floor(Q) end
    io.write(string.format("> u (0, empty = false; true otherwise) ... "))
    local text = io.read()
    if text and #text>0 then
       local u = tonumber(text)
       if u and u==0 then self.u = false else self.u = true end
    else
       self.u = false
    end -- if
    if Q then self.Q = math.floor(Q) end    
  end -- if
end -- read_inputs()

L0Main.write_outputs = function(self)
  if sim then
    if self.M.curr then L0_UI:appendM(self.M.curr) end
    sim.setInt32Signal("DC_left", self.L.curr)
    sim.setInt32Signal("DC_right", self.R.curr)
  else
    io.write(string.format("< L= %i, R= %i, M= ", self.L.curr, self.R.curr))
    if self.M.curr then io.write(self.M.curr) else io.write("nil") end
    local u = "false"; if self.u.curr then u = "true" end
    io.write(string.format(" u= %s, Q= %i\n", u, self.Q.curr))
  end -- if 
end -- L0Main.write_outputs()

L0Main.get_target = function(self)
  return self.P.curr
end -- L0Main.get_target()

L0Main.get_request = function(self)
  return self.g.curr
end -- L0Main.get_request()

L0Main.minangle = function(a)
  while a<-180 do a = a + 360 end
  while a> 180 do a = a - 360 end
  return a
end -- L0Main.minangle()
    
L0Main.step = function(self)
  if not sim and self.I[1]==nil then -- standalone version
    self.state.next = "STOP"; self.state.curr = "STOP"
  end -- if
  if self.state.curr=="LISTEN" then
    if self.I[1] == 0 then 
      self.state.next = "LISTEN"
      self.M.next = nil
    elseif self.I[1] == 1 and (self.I[2] == nil or self.I[3] == nil) then
      self.state.next = "LISTEN"
      self.M.next = "E GO - -"
    elseif self.I[1] == 1 and self.I[2] == 0 and self.I[3] == 0 then
      self.state.next = "LISTE"
      self.M.next = "E GO 0 0"
    elseif self.I[1] == 3 then
      self.state.next = "LISTEN"
      self.M.next = "E RESUME LISTEN?"
    elseif self.I[1]  == 4 then
      self.state.next = "LISTEN"
      self.M.next = "E HALT LISTEN?"
    elseif self.I[1] > 4 then
      self.state.next = "LISTEN"
      self.M.next = "E invalid opcode"
    elseif self.I[1] == 2 then
      self.state.next = "LIDAR"
      self.J.next = 1
      self.M.next = nil
    else -- Not sure of
      self.M.next = nil
    end  -- if..elseif
  elseif self.state.curr=="LIDAR" then
    if self.I[1] == 4 then 
      self.state.next = "DONE"
      self.M.next = "D LIDAR HALTed"
    elseif self.I[1] != 4 then
      self.state.next = "ECHO"
      self.P.next = minianlge(C[J])
      self.g.next = true
      self.M.next = nil
  elseif self.state.curr == "ECHO" then
    if (self.I[1] != 4) and (not u) then
      self.state.next = "ECHO"
      self.g.next = false
    elseif (self.I[1] != 4) and (u) then
      self.state.next = "RAY"
      self.J.next = J * mod(N + 1)
      self.g.next = false
    elseif self.I[1] == 4 then
      self.state.next == "DONE"
      self.P.next = 0
      self.g.next = true
      self.M.next = "D LIDAR HALTed"
  elseif self.state.curr = "RAY" then
    if self.I[1] == 4 then
      self.state.next == "DONE"
      self.P.next = 0
      self.g.next = true
      self.M.next = "D LIDAR HALTed"
    elseif self.I[1] != 4 then
      self.state.next = "RESUME"
      self.P.next = miniangle(C[J])
      self.M.next = "D RAY"
  elseif self.state.curr = "RESUME" then
    if (self.I[1] != 3) and (self.I[1] != 4) then
      self.state.next = "RESUME"
      self.M.next = nil
    elseif (self.I[1] == 3) and (C[J] != 360) then
      self.state.next = "RAY"
      self.M.next = nil
      self.g.next = true
    elseif self.I[4] == 4 then
      self.state.next = "DONE"
      self.P.next = 0
      self.g.next = true
      self.M.next = "D RESUME HALTed"
    elseif (self.I[1] == 3) and (C[J] == 360) then
      self.state.next = "DONE"
      self.M.next = "D LIDAR OK"
      self.P.next = 0
      self.g.next = true
  elseif self.state.curr = "DONE" then
    self.g.next = false
    if not u then
      self.state.next = "DONE"
      self.M.next = nil
    elseif u then
      self.state.next = "LISTEN"
      self.M.next = nil
  else -- Error
      self.state.next = "STOP"
  end -- if..ifelse
end -- L0Main.step()

L0Main.active = function(self)
  return self.state.curr=="LISTEN"
    or self.state.curr=="TURN"
    or self.state.curr=="FWD"
    or self.state.curr=="LIDAR"
    or self.state.curr=="STOP"
end -- L0Main.active()

if not sim then -- LOCAL SIMULATION ENGINE
  L0Main:init()
  L0Main:forward()
  while L0Main:active() do
    L0Main:write_outputs()
    L0Main:read_inputs()
    L0Main:step()
    L0Main:forward()
  end -- while
end -- if