-- Counter

-- AUXILIARY FUNCTIONS

init = function()
  state = {}; state.next = "WAIT"
  B = {}; B.next = nil
  C = {}; C.next = nil
end -- init()

forward = function()
  state.curr = state.next
  B.curr = B.next; C.curr = C.next
  if state.curr=="COUNT" then rdy = false
  else rdy = true
  end -- if
end -- forward()

write_outputs = function()
  io.write("< Counter: rdy = ")
  if rdy then io.write("1\n") else io.write("0\n") end 
end -- write_outputs()

read_inputs = function()
  io.write( "> Counter: begin(0/1), M(integer) [whitespace=keep] = ")
  local line = io.read()
  local c = -1
  c = string.find(line, ",")
  if c~=nil then
    local new_begin = tonumber(string.sub(line, 1, (c-1)))
    if new_begin~=nil then
      if new_begin==0 then
        begin = false
      elseif new_begin==1 then
        begin = true
      else -- user wants to stop simulation
        begin = nil
      end -- if
    end -- if
    local new_M = tonumber(string.sub(line, (c + 1)))
    if new_M~=nil then M = new_M end
  else
    begin = nil
  end -- if
end -- read_inputs()

step = function() -- computes next values
  if begin==nil then state.next = "STOP"; state.curr = "STOP" end -- simulation only
  if state.curr=="WAIT" then
    C.next = 0; B.next = M - 1
    if begin then state.next = "COUNT" end
  elseif state.curr=="COUNT" then
    C.next = C.curr + 1
    if C.curr==B.curr then state.next = "WAIT" end
  else -- STOP state or error
    state.next = "STOP"
  end -- if..elseif
end -- step()

-- SETUP
init()

-- LOOP
cycle = 0
while state.curr~="STOP" do
  io.write(string.format( "Cycle = %04i:\n", cycle))
  forward()
  write_outputs()
  read_inputs()
  step()
  cycle = cycle + 1
end -- while
io.write( "Program exited!\n" )
