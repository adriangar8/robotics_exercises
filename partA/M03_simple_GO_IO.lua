-- L0 Open-loop control of UABotet
-- By:      Lluis Ribas-Xirgo
--          Universitat Autonoma de Barcelona
-- Date:    September 2023
-- License: Creative Commons, BY-SA = attribution, share-alike
--          [https://creativecommons.org/licenses/by-sa/4.0/]

-- L0 Main
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

init = function()
  rW = 17       -- Radius of wheels = 17mm
  dW = 105      -- wheel distance [mm]
  CPR = 1440    -- Counts per revolution
  eticks2mm =  rW*2*math.pi/CPR
  I = {0, 0, 0} -- Instruction table
  state = {}; state.next = "LISTEN"
  B = {}; B.next = 0   -- Begin time 
  A = {}; A.next = nil -- Absolute angle rotation
  S = {}; S.next = nil -- Space/distance to move ahead
  L = {}; L.next = 0   -- DC value for left motor
  R = {}; R.next = 0   -- DC value for right motor
  M = {}; M.next = nil -- Message to user/upper-level controllers
  if sim then
    eL = sim.getInt32Signal("enc_left") or 0  -- as they depend on order of execution of
    eR = sim.getInt32Signal("enc_right") or 0 -- init()'s, default init values are given
  else
    eL = 0
    eR = 0
  end -- if
  dA = 0
  dS = 0
end -- init()

forward = function() -- Current state update
  -- Closed-loop control here
  local error_angle = I[2] - dA  -- Desired angle - actual angle
  local error_distance = I[3] - dS  -- Desired distance - actual distance

  -- Use the P controller to update the control variables
  local control_variable_angle, control_variable_distance = p_controller(error_angle, error_distance)

  -- Use the control variables to control the motors
  if error_angle > 0 then  -- Need to turn right
    L.curr = control_variable_distance + control_variable_angle
    R.curr = control_variable_distance - control_variable_angle
  elseif error_angle < 0 then  -- Need to turn left
    L.curr = control_variable_distance - control_variable_angle
    R.curr = control_variable_distance + control_variable_angle
  else  -- Go straight
    L.curr = control_variable_distance
    R.curr = control_variable_distance
  end

  -- Optionally, update the message to indicate that this is closed-loop control
  M.curr = "Closed-loop control active"
end

-- P-controller function
Kp_angle = 1.0  -- Proportional gain for angle
Kp_distance = 1.0  -- Proportional gain for distance

function p_controller(error_angle, error_distance)
  local control_variable_angle = Kp_angle * error_angle
  local control_variable_distance = Kp_distance * error_distance
  return control_variable_angle, control_variable_distance
end


read_inputs = function()
  local C = L0_UI:getC()
  if sim then
    local cL = sim.getInt32Signal("enc_left") - self.eL
    local cR = sim.getInt32Signal("enc_right") - self.eR
    eL = eL + cL;
    eR = eR + cR;
    local dL = eticks2mm*cL
    local dR = eticks2mm*cR
    dA = (dR-dL)/dW -- dA = 0.5*(dAL+dAR) = 0.5*(2*dR/dW-2*dL/dW)
    dA = math.abs(dA*180/math.pi)
    dS = 0.5*(dL+dR)
    dS = self.dS/10.0 -- mm into cm
  else -- console input
    io.write(string.format("> dA [deg] = "))
    local x = tonumber(io.read())
    if x then dA = x end
    io.write(string.format("> dS [cm] = "))
    local x = tonumber(io.read())
    if x then dS = x end
    io.write(string.format("> I = "))
    C = io.read()
  end -- if
  if C and #C>0 then
      local words = {}
      for w in string.gmatch(C, "-?%d+") do table.insert(words, w) end
      I[1] = tonumber(words[1])
      if I[1] then
        if I[1]==1 then -- GO
          if #words>1 then I[2] = tonumber(words[2]) end
          if #words>2 then I[3] = tonumber(words[3]) end
        else
          I[2] = 0; I[3] = 0
        end -- if
      end -- if
  else
      I[1] = 0 -- no command received
  end -- if
end -- read_inputs()

write_outputs = function()
  if sim then
    --print(string.format("< L= %i, R= %i, M= ", L.curr, R.curr))
    --if M.curr then println(M.curr) else println("nil") end
    if M.curr then L0_UI:appendM(M.curr) end
    sim.setInt32Signal("DC_left", L.curr)
    sim.setInt32Signal("DC_right", R.curr)
  else
    io.write(string.format("< L= %i, R= %i, M= ", L.curr, R.curr))
    if M.curr then io.write(M.curr.."\n") else io.write("nil\n")  end
  end -- if 
end -- write_outputs()

step = function() -- Next state computation
  if not sim and I[1]==nil then state.next = "STOP"; state.curr = "STOP" end
  
  local error_angle = I[2] - dA
  local error_distance = I[3] - dS
  
  if state.curr=="LISTEN" then

    if I[1] == 1 then
      if math.abs(error_angle) < angle_tolerance and math.abs(error_distance) < distance_tolerance then
          state.next = "SOME_NEW_STATE"
      else
          state.next = "LISTEN"
      end
    elseif I[1] == 4 then
      state.next = "HALT"
    elseif I[1] == 2 then
      state.next = "LIDAR"
    elseif I[1] == 3 then
      state.next = "RESUME"
    else
      state.next = "STOP"
    end
  end

  else -- Error
    state.next = "STOP"
  end -- if..ifelse
end -- step()

if not sim then -- LOCAL SIMULATION ENGINE
  init()
  forward()
  while state.curr~="STOP" do
    write_outputs()
    read_inputs()
    step()
    forward()
  end -- while
end -- if
