pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- main
g = {} -- games state
c = {} -- config
T = 0
debug = true
debug = false

function _init()
  T = 0
  c.ents = {}
  add(c.ents,make_pc())
  for i=1,2 do
    add(c.ents,make_en())
  end
  for i = 1,5 do
    add(c.ents,make_carrot())
  end
  pturn=1

  -- Map
  m = {}
  m.i = 0
  m.j = 0
  m.ox = 0
  m.oy = 0
  m.w = 64
  m.h = 32
  m.up = 
    function(s)
      local p = c.ents[1]
      local newi = flr(p.i/16)*16
      local newj = flr(p.j/16)*16

      -- Scroll map instead of jumping
      if newi - m.i > 0 then
        m.ox = 128
      elseif newi - m.i < 0 then
        m.ox = -128
      end
      if newj - m.j > 0 then
        m.oy = 128
      elseif newj - m.j < 0 then
        m.oy = -128
      end
      if m.ox > 0 then
        m.ox-=8
      elseif m.ox < 0 then
        m.ox+=8
      end
      if m.oy > 0 then
        m.oy-=8
      elseif m.oy < 0 then
        m.oy+=8
      end
      -- Update values
      m.i = newi
      m.j = newj
    end
  m.dr = 
    function(s)
      map(0,0,0,0,s.w,s.h)
      camera(m.i*8-m.ox,m.j*8-m.oy)
    end

  -- mmenu_ini()
  exp_ini()
  -- init_ini()
  -- cmbt_ini()
end

function _update()
  T+=1
  m:up()
  g.upd()
end

function _draw()
  cls()
  m:dr()
  g.drw()
end

function make_pc()
  return {
    name='blue bunny',
    i=0,
    j=1,
    ox=0, -- offsets for anim.
    oy=0,
    mvmt=8,
    hp=40,
    maxhp=40,
    ini=0,
    tail={},
    bktrk=0,
    sp=236,
    car=0,
    mv=move_pc,
    cmv=cmbt_move,
    up=upd_pc,
    dr=draw_pc,
    et=end_turn_pc,
    ani={236,237,238,239},
    cani=236,
    type='pc',
    opts= {
      'move',
      'melee attack',
      'ranged attack',
      'end'
    }
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

function make_carrot()
  local c = {}
  local span = 15
  c.i=flr(rnd(span)) + 1
  c.j=flr(rnd(span)) + 1
  c.sp=220
  c.dr=
    function(s)
      spr(s.sp,s.i*8,s.j*8)
    end
  c.up=function() end
  return c
end
function upd_en()
--placeholder
end

function draw_en(en,x,y)
  x = x or en.i*8
  y = y or en.j*8
  spr(en.sp,x,y)
end

function can_move(pc,di,dj)
  local newi = pc.i+di
  local newj = pc.j+dj
  -- Is tile a "wall"?
  local t1 = not is_tile(0,newi,newj)
  -- Are we trying to move 
  local t2 = (newi >= 0 and newi < m.w)
  local t3 = (newj >= 0 and newj < m.h)
  return t1 and t2 and t3
end

function move_pc(s,di,dj)
  -- Check for solid and we also
  -- wait for the map to stop
  -- animating
  if can_move(s,di,dj) and
      m.ox == 0 and
      m.oy == 0 then
    s.i+=di
    s.j+=dj
    s.ox = -di*8
    s.oy = -dj*8
  else -- Bounce
    s.ox = di*4
    s.oy = dj*4
  end

  for e in all(c.ents) do
    if e != s then
      interact(s,e,s.i,s.j)
    end
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
 -- TODO: Broken because can_move now takes di,dj, not i,j
if can_move(pc,nxt[1],nxt[2]) and
    (pc.mvmt-#nw_tail) >= 0 then
  pc:mv(di,dj)
  pc.tail = nw_tail
 end
end

function draw_pc(pc,x,y)
  x = x or pc.i*8
  y = y or pc.j*8
  if debug then
    pal({[12]=7})
    spr(pc.cani,x,y)
  end
  spr(pc.cani,x+pc.ox,y+pc.oy)
  render_path(pc)
  -- HUD
  -- Draw Carrots collected
  for i=1,pc.car do
    spr(220,128+m.i*8-m.ox-i*8,m.j*8-m.oy)
  end
  for i=pc.car+1,5 do
    spr(219,128+m.i*8-m.ox-i*8,m.j*8-m.oy)
  end
  -- HP
  rect(1,1,pc.maxhp,6,0)
  rectfill(2,2,pc.hp-1,5,8)
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
      for i=0,3 do
        if (btnp(i)) c.ents[pturn]:mv(getdx(i),getdy(i))
      end
      -- dummy way to enter combat
      if e.i == 1 and e.j == 1 
      and e.ox == 0 and e.oy == 0
      then
        init_ini()
      end
    end
    e:up()
  end
end

function exp_drw()
  for e in all(c.ents) do
    e:dr()
  end
  -- Portal to enter combat
  rect(7,8,15,16,9)
end

-->8
-- combat
function cmbt_ini()
  g.upd = cmbt_upd
  g.drw = cmbt_drw
  rval = 21
  rtime = 2
  rcount = 0
  pturn = 1
  cmenu = {
    dr=menu_draw,
    up=menu_upd,
    s=0,
    p=false
  }
end


function cmbt_upd()
  if cmenu.p then
    local pc = c.ents[pturn]
    -- Movement
    if cmenu.s == 0 then
      for i=0,3 do
        if (btnp(i)) pc:cmv(getdx(i),getdy(i))
      end
    -- Attack
    elseif cmenu.s==1 and cmenu.s==2 then
      -- Placeholder
    -- End Turn
    elseif cmenu.s == 3 then
      pc:et()
      pturn = (pturn+1)%#c.ents + 1
    end
  end

  for e in all(c.ents) do
    e:up()
  end
  cmenu:up()
end

function cmbt_drw()
  for e in all(c.ents) do
    e:dr()
  end
  -- draw menu
  cmenu:dr()
  if debug then
    print('pturn-'..pturn,90,120,9)
    -- print(cmenu.s)
  end
end

function menu_draw(self)
  local scrn_sz = 128;
  rect(0, 86, scrn_sz-1, scrn_sz-1, 6)
  rectfill(1, 87, 126, 126, 0)
  local line_start = 90;
  local line_delta = 10;

  local act = c.ents[pturn]
  print(act.name, 10, 80, 6)

  local opts = act.opts
  opts[1] = "move ("..5*(act.mvmt-#act.tail).."/"..5*act.mvmt..")"
  for i=1,#act.opts do
    print(opts[i], 10, line_start+(i-1)*line_delta, 6)
  end

  if self.p then
    rectfill(3, line_start+line_delta*self.s, 7, line_start+self.s*line_delta+4, 6)
  else
    rect(3, line_start+line_delta*self.s, 7, line_start+self.s*line_delta+4, 6)
  end
end

function menu_upd(self)
  if self.p then
    if (btnp(❎)) self.p = false
  else
    if (btnp(⬆️)) self.s-=1
    if (btnp(⬇️)) self.s+=1
    self.s = self.s%4
    if (btnp(❎)) self.p=true
  end
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

function end_turn_pc(pc)
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


function old_cmbt_upd()
  for e in all(c.ents) do
    if e.type=='pc' then
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
          if #e.tail > 0 then
            e.bktrk = #e.tail
          end
          if (btnp(❎)) cmbt_state = cmbt_states.menu
        elseif cmbt_state == cmbt_states.end_turn then
          end_turn(e)
          cmbt_state = cmbt_states.menu
          s = 0
        else
          -- if (btnp(4)) cmbt_state = cmbt_states.menu
        end
      end
  end
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
    cmbt_ini()
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
-->8
--tools
--[[ 
  getdx and getdy are used to 
  simplify the button tracking
  process for dpad input
]]
function getdx(i)
  if i == 0 then
    return -1
  elseif i==1 then
    return 1
  end
  return 0
end

function getdy(i)
  if i == 2 then
    return -1
  elseif i==3 then
    return 1
  end
  return 0
end

function is_tile(tile_type,i,j)
  return fget(mget(i,j),tile_type)
end

function swap_tile(i,j)
  mset(i,j,mget(i,j)+1)
end

function interact(e1,e2,i,j)
  -- Player collects carrots
  if (e1.type=="pc" and e2.sp==220) 
      and (i==e2.i and j==e2.j) then
    e2.sp+=1
    e1.car+=1
    return true
  end

  if (e1.type=="pc" and e2.type=="en")
      and (i==e2.i and j==e2.j) then
    e1.hp-=5
    return true
  end

  return false
end

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
000000003333aaa90000000000000000000000000000000065566666000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb33399a0000000000000000000000000000000066666556000000000000000000000000000000000000000000000000000000000000000000000000
000000003bb33aaa0000000000000000000000000000000065566666000000000000000000000000000000000000000000000000000000000000000000000000
00000000333baaaa0000000000000000000000000000000066666556000000000000000000000000000000000000000000000000000000000000000000000000
000000003333a9aa0000000000000000000000000000000065566666000000000000000000000000000000000000000000000000000000000000000000000000
00000000333aaaa90000000000000000000000000000000066666556000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb3a9aaa0000000000000000000000000000000065566666000000000000000000000000000000000000000000000000000000000000000000000000
000000003333aaa90000000000000000000000000000000066666556000000000000000000000000000000000000000000000000000000000000000000000000
333333333aaaaa9aa9aaaaa3333333baab333333aaaa9aaacccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
33333333bb3a9aaaaaa9a3bbbb333b3aa3b333bb9aaaa9aaccccccccccc1cccc0000000000000000000000000000000000000000000000000000000000000000
333333333bb3aaaaaaaa3bb3333333a99a333333aaaaaa9acccccccc111c11cc0000000000000000000000000000000000000000000000000000000000000000
33333333333b3a9aa9a3b33333333aaaaaa33333aa9aaaaacccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
3333333333333aaaaaa33333333b3a9aa9a3b333aaaaaaaacccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
33333333333333a99a3333333bb3aaaaaaaa3bb3aaaaaa9accccccccccc11ccc0000000000000000000000000000000000000000000000000000000000000000
33333333bb333b3aa3b333bbbb3a9aaaaaa9a3bbaaaaaaaaccccccccc11cc1110000000000000000000000000000000000000000000000000000000000000000
33333333333333baab3333333aaaaa9aa9aaaaa3a9aaa9aacccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
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
0077000000000077000000000000000000000000000000000000000000000000000000000000000000000000000060000000b0000000b0000000000000000000
0077000000000070000000000000000000000000000000000000000000000000000000000000000000000000000066000000bb000000bb000000000000000000
0077000000000770000000000000000000000000000000000000000000000000000000000000000000000000006606600099bbb00009bbb00000000000000000
00777000000007000000000000000000000000000000000000000000000000000000000000000000000000000060600000999000000990000000000000000000
00707000000077000000000000000000000000000000000000000000000000000000000000000000000000000600600009994000000000000000000000000000
00707000000770000000000000000000000000000000000000000000000000000000000000000000000000000606000009940000000000000000000000000000
00707000000700000000000000000000000000000000000000000000000000000000000000000000000000006660000099400000000000000000000000000000
007077000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0000c000c000000000
0070070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00cec0cec00cec0cec00c000c0
007007000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000cec0cec0cec0cec00cec0cec0cec0cec
007007700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000cec0cec0ccccccc00ccccccc0cec0cec
007000707700000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0c1ccc1c00c1ccc1c0ccccccc
007000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c1ccc1c0ccccccc00ccccccc0c1ccc1c
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
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000000101010100000000000000000000000001010101
__map__
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303636363600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030363637363700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303636363637363600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303636363636363600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303036363636373636303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303636363736363030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030363636363637363636303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303636373636363636363636363630303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303636363636363636363636363637363636303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303636363637363636373636373637363636363630303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030363636363736363636363636363636373636363030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030302626262630303030303030303030303030303036363636363636363636363636363630303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030302626262630303030363636363636363636363636363636363637363636373030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303026263636363636363636363736363636373637363636363636363630303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030363626263636373637363636363030303030363636363030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030363637363626263030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303036363637363626263030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3636363636363636373636363726263030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3636363737363636363030302626262626303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3637363636363030303030302626262626303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3636363636303030303030303030262626303030303030303030303030303030303030303030303030303030303030303335353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030302626303030303030303030303030303030303030303030303030303030303033353535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303035353535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030213534303030303030303030303030303030303035353535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303033353535343030303030303030303030303030303031353535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030302135353535353030303030303030303030303030303030353535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030302135353535353030303030303030303030303030303030313535353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030213535323030303030303030303030303030303030303135353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303033353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303033353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030353535353535353535353535353500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
