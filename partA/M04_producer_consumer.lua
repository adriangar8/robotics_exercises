-- PRODUCER/CONSUMER example
Producer = {
  S = {"H", "e", "l", "l", "o", ",", " ", "w", "o", "r", "l", "d"},
  M = 0,       -- storage size
  N = 4,       -- random cycles
  r = nil,     -- input request
  state = {},  -- state
  J = {},      -- data index
  C = {},      -- internal counter
  D = {},      -- output data
  a = {},      -- output acknowledgement
  init = function(self)
    self.M = #self.S
    self.state.next = "WAIT"
    self.J.next = 1
    self.D.next = nil
    self.a.next = false
    math.randomseed(os.time())
    self:forward()
  end -- function init()
  ,
  forward = function(self)
    self.state.curr = self.state.next
    self.J.curr = self.J.next
    self.C.curr = self.C.next
    self.D.curr = self.D.next
    self.a.curr = self.a.next
  end -- function init()
  ,
  read_inputs = function(self, req)
    self.r = req
  end -- function read_inputs()
  ,
  step = function(self)
    if self.state.curr=="WAIT" then
    -- TO COMPLETE
    else -- Stop state or error
    end -- if chain
  end -- function step()
  ,
  monitor = function(self)
    local C = self.C.curr or -1
    io.write(string.format("# Producer: state = %s C = %2i J = %2i\n",
        self.state.curr, C, self.J.curr))
  end -- function monitor()
  ,
  write_outputs = function(self)
    local D = self.D.curr or "nil"
    local a = "false"; if self.a.curr then a = "true" end 
    io.write(string.format("< Producer: a = %s D = %s\n", a, D))
  end -- function write_outputs()
  ,
  active = function(self)
    return self.state.curr=="WAIT" or self.state.curr=="PRODUCE"
  end, -- function active()
  get_ack = function(self) return self.a.curr end,
  get_Data = function(self) return self.D.curr end
} -- Producer

Consumer = {
  M = 16,      -- storage size (default value)
  N = 4,       -- random cycles
  a = nil,     -- input acknowledgement
  state = {},  -- state
  J = {},      -- data index
  C = {},      -- internal counter
  S = {},      -- internal storage
  r = {},      -- output request
  init = function(self, size)
    self.M = size or self.M
    self.state.next = "CONSUME"
    self.S.next = {}
    self.J.next = 1
    math.randomseed(os.time())
    self.C.next = math.random(1, self.N)
    self.r.next = false
    self:forward()
  end -- function init()
  ,
  forward = function(self)
    self.state.curr = self.state.next
    self.J.curr = self.J.next
    self.C.curr = self.C.next
    self.S.curr = self.S.next -- in this case, the table remains always the same!
    self.r.curr = self.r.next
  end -- function init()
  ,
  read_inputs = function(self, ack, data)
    self.a = ack
    self.D = data
  end -- function read_inputs()
  ,
  step = function(self)
    if self.state.curr=="CONSUME" then
    -- TO COMPLETE              
    else -- Stop state or error
    end -- if chain
  end -- function step()
  ,
  monitor = function(self)
    io.write(string.format("# Consumer: state = %s C = %2i J = %2i\n",
        self.state.curr, self.C.curr, self.J.curr))
  end -- function monitor()
  ,
  write_outputs = function(self)
    local r = "false"; if self.r.curr then r = "true" end 
    io.write(string.format("< Consumer: r = %s S = ", r))
    local i, imax = 1, #self.S.curr
    while i<imax do io.write(self.S.curr[i]); i= i + 1 end
    io.write("\n")
  end -- function write_outputs()
  ,
  active = function(self)
    return self.state.curr=="CONSUME" or self.state.curr=="WAIT"
  end -- function active()
  ,
  get_req = function(self) return self.r.curr end
} -- Consumer


--SETUP
Producer:init()
Consumer:init()

-- MAIN LOOP
cycle = 0
while Producer:active() and Consumer:active() and cycle<100 do
  io.write(string.format("Cycle = %04i:\n", cycle))
  Producer:monitor(); Consumer:monitor()
  Producer:write_outputs(); Consumer:write_outputs()
  Producer:read_inputs(Consumer:get_req());
  Consumer:read_inputs(Producer:get_ack(), Producer:get_Data())
  Producer:step(); Consumer:step()
  Producer:forward(); Consumer:forward()
  cycle = cycle + 1
end -- while
io.write( "Program exited!\n" )
