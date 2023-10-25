-- L0 Lidar
-- By:      Lluis Ribas-Xirgo
--          Universitat Autonoma de Barcelona
-- Date:    September 2023
-- License: Creative Commons, BY-SA = attribution, share-alike
--          [https://creativecommons.org/licenses/by-sa/4.0/]

servo_sensor = "servo_sensor"
sensor_ping  = "lidar_ping"
sensor_echo  = "lidar_echo"

Lidar = {
    A = nil,     -- Input target angle, must be kept constant
    r = nil,     -- Input request obstacle distance
    E = nil,     -- Input obstacle distance
    T = nil,     -- Time [s]
    dT = nil,    -- Time step [s]
    _wrot = nil, -- Sensor servo speed in degrees per cyle
    state = {},
    B = {},      -- Begin time
    D = {},      -- Delay
    Y = {},      -- Yaw
    Z = {},      -- Control variable for yaw Y 
    Q = {},      -- Output obstacle distance
    p = {},      -- Pending request
    u = {},      -- Distance update 
    s = false,   -- Send ping
    Y2Z = function(A)
      if A==360 then A=0 else A=math.floor(1500-A*160/90) end
      return A
    end, -- function Y2Z
    forward = function(self)
      self.state.curr = self.state.next
      self.B.curr = self.B.next
      self.D.curr = self.D.next
      self.Y.curr = self.Y.next
      self.Z.curr = self.Z.next
      self.Q.curr = self.Q.next
      self.p.curr = self.p.next
      self.u.curr = self.u.next
      self.s = (self.state.curr=="PING")
    end, -- function forward()
    init = function(self)
        self._wrot = 120; -- deg/s (aprox. half of reality)
        self.T = sim.getSimulationTime()
        self.state.prev = "NONE" -- for use in cmonitor() only
        self.state.next = "ROTATE"
        self.B.next = self.T
        self.D.next = 90/self._wrot
        self.Y.next = 0
        self.Z.next = self.Y2Z(0)
        self.Q.next = 0
        self.p.next = false
        self.u.next = false
        self.s = false
        self:forward()
    end, -- function init()
    monitor = function(self)
        print(string.format("Lidar: state=%s p=", self.state.curr)) 
        if self.p.curr then print("true") else print("false") end
        print(string.format(" B= %.4fs D= %.4fs Y= %ideg Z=%ius Q=%icm u=",
            self.B.curr, self.D.curr, self.Y.curr, self.Z.curr, self.Q.curr)) 
        if self.u.curr then println("true") else println("false") end
    end, -- function monitor()
    cmonitor = function(self)
        if self.state.prev~=self.state.curr then
            self.state.prev = self.state.curr; self.monitor(self)
        end -- if
    end, -- function cmonitor()
    read_inputs = function(self, A, r)
        if A~=nil then
            if A<-90 then self.A = -90
            elseif A>90 then self.A = 90
            else self.A = A
            end -- if chain
        else
            self.A = 0
        end -- if
        if r~=nil then self.r = r else self.r = false end
        local echo = sim.getInt32Signal(sensor_echo)
        if echo==nil or echo<0 then
            self.E = nil
        else
            self.E = echo -- [cm]
        end -- if
        self.T = sim.getSimulationTime()
        self.dT = sim.getSimulationTimeStep()
    end, -- function read_inputs()
    step = function(self)
      if self.state.curr=="ROTATE" then
        self.p.next = self.p.curr or self.r
        if self.T-self.B.curr>=self.D.curr then
          self.Z.next = self.Y2Z(360)
          self.state.next = "PING"
        end -- if
      elseif self.state.curr=="PING" then
        self.p.next = self.p.curr or self.r
        if self.A~=self.Y.curr then
          self.B.next = self.T
          self.D.next = math.abs(self.A-self.Y.curr)/self._wrot
          self.Y.next = self.A
          self.Z.next = self.Y2Z(self.A)
          self.u.next = false
          self.state.next = "ROTATE"
        else
          self.state.next = "ECHO"
        end -- if chain                                
      elseif self.state.curr=="ECHO" then
        if self.r then
          self.p.next = true
          self.state.next = "PING"         
        elseif self.E~=nil then
          self.p.next = false
          self.u.next = self.p.curr
          self.Q.next = self.E
          self.state.next = "PING"
        end -- if
      else -- Stop state or error
      end -- if chain
    end, -- function step()
    write_outputs = function(self)
      if self.s then
        sim.setInt32Signal(sensor_ping, 1)
      else
        sim.setInt32Signal(sensor_ping, 0)
      end
      if self.Z.curr~=360 then sim.setInt32Signal(servo_sensor, self.Z.curr) end
    end, -- function write_outputs()
    get_distance = function(self)
        return self.Q.curr
    end, -- function get_distance()
    get_update = function(self)
        return self.u.curr
    end, -- function get_update()
    active = function(self)
      return (self.state.curr=="ROTATE") or
             (self.state.curr=="PING") or
             (self.state.curr=="ECHO")
    end -- function active()
} -- Lidar

