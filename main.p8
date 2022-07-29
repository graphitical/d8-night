pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- main
g = {} -- games state
c = {} -- config
T = 0
debug = false
-- debug = true

function _init()
  T = 0
  c.ents = {}
  add(c.ents,make_pc())
  for i=1,4 do
    add(c.ents,make_en())
  end

  -- mmenu_ini()
  exp_ini()
  -- init_ini()
  -- cmbt_ini()
end

function _update()
 T+=1
 g.upd()
end

function _draw()
 g.drw()
end

function make_pc()
  return {
    name='blue bunny',
    i=0,
    j=0,
    ox=0, -- offsets for anim.
    oy=0,
    mvmt=8,
    ini=0,
    tail={},
    bktrk=0,
    sp=236,
    mv=move_pc,
    up=upd_pc,
    dr=draw_pc,
    ani={236,237,238,239},
    cani=236,
    type='pc'
  }
end

function make_en()
  local span = 16
  return {
    name='En1',
    i = flr(rnd(span)),
    j = flr(rnd(span)),
    ini=0,
    sp=252,
    up=upd_en,
    dr=draw_en,
    type='en'
  }
end

function upd_en()
--placeholder
end

function draw_en(en,x,y)
  local x = x or en.i*8
  local y = y or en.j*8
  palt()
  -- palt(0,false)
  spr(en.sp,x,y)
  -- palt()
end

-- returns true if first flag is
-- on for sprite in location 
-- (i,j)
function coll_pc(pc,i,j)
  return fget(mget(i,j),0)
end

-- moves pc by (di,dj) if no
-- collision
function move_pc(pc,di,dj)
  local nxt = {pc.i+di,
               pc.j+dj}
  if not coll_pc(pc,nxt[1],nxt[2]) then
    pc.i = nxt[1]
    pc.j = nxt[2]
    pc.ox = -di*8
    pc.oy = -dj*8
  end
end

function upd_pc(pc)
  if pc.ox==0 and pc.oy==0 then
    pc.cani=pc.ani[1]
    return
  end
  local m = 0
  if (pc.ox > 0) then
    pc.ox-=2
    m = -1
  end
  if (pc.ox < 0) then
    pc.ox+=2
    m = 1
  end
  if (pc.oy > 0) then
    pc.oy-=2
    m = -1
  end
  if (pc.oy < 0) then
    pc.oy+=2
    m = 1
  end
  pc.cani = (pc.cani + m)%4 + pc.ani[1]
end

-- wrapper on move_pc that 
-- restricts motion for combat
function cmbt_move(pc,di,dj)
 local nxt = {pc.i+di,
        pc.j+dj}
 
 local nw_tail = {}
 -- Rebuilding tail every time 
 -- means we allow backtracking
 for p in all(pc.tail) do
  if nxt[1]==p[1] and
     nxt[2]==p[2] and
     pc.bktrk == 0 then
   break
  end
  add(nw_tail, p)
 end
 -- if the tail is growing
 -- then add our current pos
 -- as the end of the tail
 if #nw_tail >= #pc.tail then
  add(nw_tail, {pc.i, pc.j})
 end

 -- if open and we have 
 -- movement we can move there
 -- TODO:
 -- https://www.lexaloffle.com/bbs/?tid=46181 
 if not coll_pc(pc,nxt[1],nxt[2]) and
    (pc.mvmt-#nw_tail) >= 0 then
  pc:mv(di,dj)
  pc.tail = nw_tail
 end
end

function draw_pc(pc,x,y)
  local x = x or pc.i*8
  local y = y or pc.j*8
  if debug then
    -- Show target sprite position after animation
    palt(0,false) -- keeps black eyes as black
    pal({[12]=7})
    spr(pc.cani,x,y)
    pal()
  end
  palt(0,false) -- keeps black eyes as black
  spr(pc.cani,x+pc.ox,y+pc.oy)
  palt()
  render_path(pc)
end
-- Get next frame in animation
-- frame queue
function getframe(ani)
  return ani[flr(T/8)%#ani+1]
end
-->8
-- main menu

function mmenu_ini()
 g.upd = mmenu_upd
 g.drw = mmenu_drw
end

function mmenu_upd()
 if btn(🅾️) or btn(❎) then
  ctscn_ini()
 end
end

function mmenu_drw()
 cls()
 print("press 🅾️/❎ to start")
end
-->8
-- cutscene/dialogue
ctscn = {start=0}

function ctscn_ini()
 ctscn.start = time()
 g.upd = ctscn_upd
 g.drw = ctscn_drw
end

function ctscn_upd()
 if time()-ctscn.start < 1 then
  return
 end
 if time()-ctscn.start > 8 or
    btn(❎) or btn(🅾️) then
  cmbt_ini()
 end
end

function ctscn_drw()
 cls()
 local t = time() - ctscn.start
 local s = "hello"
 if t > 1 then
  s = s..sub("...",1,t-1)
 end
 if t > 5 then
  s = s.." this is the end of the\nscene"
 end
 print(s)
end
-->8
-- non-combat exploration
function exp_ini()
  g.upd = exp_upd
  g.drw = exp_drw
end

function exp_upd()
  for e in all(c.ents) do
    if e.type=='pc' then
      if (btnp(⬅️)) e:mv(-1, 0)
      if (btnp(➡️)) e:mv( 1, 0)
      if (btnp(⬆️)) e:mv( 0,-1)
      if (btnp(⬇️)) e:mv( 0, 1)
      -- dummy way to enter combat
      if e.i == 1 and e.j == 1 then
        init_ini()
      end
    end
    e:up()
  end

end

function exp_drw()
  cls()
  map()
  for e in all(c.ents) do
    e:dr()
  end
  rect(7,8,15,16,9)
end

-->8
-- combat
function cmbt_ini()
  g.upd = cmbt_upd
  g.drw = cmbt_drw
  cmbt_states={init=0,menu=1,move=2,mattack=3,rattack=4,end_turn=5}
  --  cmbt_state = cmbt_states.menu
  cmbt_state = cmbt_states.init
  s=0
  rval = 21
  rtime = 2
  rcount = 0

  c.num_turns = #c.players
  c.player_turn = 1
end

function render_path(pc)  
 if #pc.tail == 0 then
  return
 end
 for n=pc.bktrk+1,#pc.tail do
  local x0 = pc.tail[n][1]*8
  local y0 = pc.tail[n][2]*8
  rect(x0,y0,x0+7,y0+7,8)
 end
end

function end_turn(pc)
 c.player_turn = c.player_turn % 2 + 1
 pc.tail = {}
 pc.bktrk = 0
end


function cmbt_menu(pc, s, cmbt_state)
  local scrn_sz = 128;
  rect(0, 86, scrn_sz-1, scrn_sz-1, 6)
  rectfill(1, 87, 126, 126, 0)

  local line_start = 90;
  local line_delta = 10;

  print(pc.name, 10, 80, 6)

  local cmds = {"move ("..5*(pc.mvmt-#pc.tail).."/"..5*pc.mvmt..")", "melee attack",
    "ranged attack", "end turn"}
  for i=1,4 do
    print(cmds[i], 10, line_start+(i-1)*line_delta, 6)
  end

  if (cmbt_state != cmbt_states.menu) then
    rectfill(3, line_start+line_delta*s, 7, line_start+s*line_delta+4, 6)
  else
    rect(3, line_start+line_delta*s, 7, line_start+s*line_delta+4, 6)
  end
end

function cmbt_upd()
 local pc = c.players[c.player_turn]
 -- Menu select state
  if cmbt_state == cmbt_states.menu then
    if (btnp(⬆️)) s = (s - 1) % 4 -- 4 is the number of commands we cycle though
    if (btnp(⬇️)) s = (s + 1) % 4
    if (btnp(❎)) cmbt_state = s + 2
  -- Movement State
  elseif cmbt_state == cmbt_states.move then
    if (btnp(⬅️)) e:move(-1, 0)
    if (btnp(➡️)) e:move( 1, 0)
    if (btnp(⬆️)) e:move( 0,-1)
    if (btnp(⬇️)) e:move( 0, 1)
    if (btnp(❎)) cmbt_state = cmbt_states.menu
  -- TODO: Attack states. Items?
  elseif cmbt_state == cmbt_states.mattack or cmbt_state == cmbt_states.rattack then
    -- Prevent backtracking if we've
    -- already moved
    if #pc.tail > 0 then
      pc.bktrk = #pc.tail
    end
    if (btnp(❎)) cmbt_state = cmbt_states.menu
  elseif cmbt_state == cmbt_states.end_turn then
    end_turn(pc)
    cmbt_state = cmbt_states.menu
    s = 0
  else
    -- if (btnp(4)) cmbt_state = cmbt_states.menu
  end
end


function upd_roll()

end

function cmbt_drw()
 cls()
 map()
 -- Draw all PCs & NPCs
 for pc in all(c.players) do
  pc:draw()
 end
 -- Focus on current PC
 local pc = c.players[c.player_turn]
 -- Draw combat menu
 if cmbt_state == cmbt_states.init then
  -- roll_init()
  draw_roll()
 else
  cmbt_menu(pc,s,cmbt_state)
 end
 color(8)
end

-- rolling initiative
function init_ini()
  g.drw = init_drw
  g.upd = init_upd
  roll = false
  rtime = 1
  rval = 21
  p = 0
  for e in all(c.ents) do
    e.ox = 0
    e.oy = 0
  end
end

function init_drw()
  cls()
  draw_roll()
end

function init_upd()
  if btnp(❎) and (not roll) then
    roll=true
    rtime=1
    p+=1
  end

  if roll then
    rollad(20)
  end

  -- done rolling init
  if p == #c.ents and
           not roll then
    g.upd = cmbt_upd
    g.drw = cmbt_drw
  end
end

function rollad(num)
  if T%rtime == 0 then
    rval = flr(rnd(num)) + 1
  end 

  if T%10 == 0 then
    rtime*=2
  end

  if rtime > 127 then
    roll = false
    c.ents[p].ini = rval
  end
end

function draw_roll()
  local scrn_sz = 128;
  rect(0, 86, scrn_sz-1, scrn_sz-1, 6)
  rectfill(1, 87, 126, 126, 0)
  -- Draw Roster
  for i=0,#c.ents-1 do
    local e = c.ents[i+1]
    e:dr(64+i*10,92)
    local dx = 0
    if (e.ini < 10) dx=2
    print(e.ini,64+i*10+dx,100,8)
  end
  -- Draw D20
  spr(192,0,92,2,4)
  spr(192,16,92,2,4,true)
  -- Shifting print value for single digit values
  if rval < 10 then
    rx = 15
  else
    rx = 13
  end
  local rcolor = 10
  if not roll then rcolor=8 end
  print(rval,rx,109,rcolor)
  -- print(rtime)
  -- print(roll)
end
-->8
-- credits
__gfx__
0000000000000000111011101cccccc1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000c1111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000000000010111010c1111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000000000000c1111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000001000011101110c1111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000000000000000000c1111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000010111010c1111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007770000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007077000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0000c000c000000000
0070070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00cec0cec00cec0cec00c000c0
007007000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000cec0cec0cec0cec00cec0cec0cec0cec
007007700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000cec0cec0ccccccc00ccccccc0cec0cec
007000707700000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0c0ccc0c00c0ccc0c0ccccccc
007000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0ccc0c0ccccccc00ccccccc0c0ccc0c
007000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc00ccecc0000ccecc00ccccccc
0077777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000ccecc00000000000000000000ccecc0
00077007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000777077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700070004000400050005000c000c00
0000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000007e707e704e404e405e505e50cec0cec0
0000000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000007e707e704e404e405e505e50cec0cec0
000000000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000777777704444444055555550ccccccc0
000000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000787778704044404050555050c0ccc0c0
000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000777777704444444055555550ccccccc0
000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000077e7700044e4400055e55000ccecc00
__gff__
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000001010101
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
