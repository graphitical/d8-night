pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- main
g = {} -- games state
actors = {}
chars = {}
T = 0
debug = true
debug = false

function _init()
  T = 0
  pc = make_pc()
  m = make_map()
  for i=1,2 do
    make_en()
  end
  for i=1,5 do
    make_carrot()
  end

  -- mmenu_ini()
  -- exp_ini()
  -- init_ini()
  cmbt_ini()

  -- Filter actors for only 
  -- combat
  for a in all(actors) do
    if (is_char(a)) add(chars, a)
  end

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

-- make an actor
-- add it to global collection
-- i,j means center of actor
-- in map coordinates
function make_actor(sp,i,j)
  local a = {}
  a.sp=sp
  a.i=i or 0
  a.j=j or 1
  a.ox=0
  a.oy=0
  a.frame=0
  a.frames=1
  a.ini=0
  a.up=function(s) end
  a.dr=function(s) 
    spr(a.sp,a.i*8,a.j*8) 
  end
  a.reset=function(s) 
    s.frame=0
    s.ox=0
    s.oy=0
  end
  add(actors,a)
  return a
end

function make_pc()
  local a = make_actor(236,7,7)
  a.name='blue bunny'
  a.frames=4
  a.mvmt=8
  a.maxhp=40
  a.hp=a.maxhp
  a.tail={}
  a.bktrk=0
  a.car=0
  a.mv=move_pc
  a.up=upd_pc
  a.dr=draw_pc
  a.et=end_turn_pc
  a.type='pc'
  a.opts=
    {'move',
     'melee attack',
     'ranged attack',
     'end turn'}
  return a
end

function make_map()
  local m = {}
  m.i = 0
  m.j = 0
  m.ox = 0
  m.oy = 0
  m.w = 64
  m.h = 32
  m.up = 
    function(s)
      local p = actors[1]
      local newi = (p.i\16)*16
      local newj = (p.j\16)*16

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
  return m
end

function make_en()
  local s = 16
  local a = make_actor(252,flr(rnd(s)),flr(rnd(s)))
  a.name='enemy'
  a.maxhp=80
  a.hp=a.maxhp
  a.up=upd_en
  a.dr=draw_en
  a.type='en'
  return a
end

function make_carrot()
  local span = 15
  return make_actor(220,flr(rnd(span))+1,flr(rnd(span))+1)
end

function upd_en()
--placeholder
end

function draw_en(en,x,y)
  x = x or en.i*8
  y = y or en.j*8
  spr(en.sp,x,y)
end

function can_move(p,di,dj)
  local newi = p.i+di
  local newj = p.j+dj
  -- Is tile a "wall"?
  local test = not is_tile(0,newi,newj)
  -- Are we trying to move out
  -- of bound?
  test = test and (newi >= 0 and newi < m.w)
  test = test and (newj >= 0 and newj < m.h)
  -- Do we have movement left?
  -- Only relevant for combat
  test = test and (p.mvmt - #p.tail) > 0
  -- Edge case, need to check if
  -- backtracking our path
  if not test then
    for p in all(p.tail) do
      test = p[1] == newi
      test = test and (p[2] == newj)
      if (test) break
    end
  end

  return test
end

function move_pc(s,di,dj)
  -- Check for solid and we also
  -- wait for the map to stop
  -- animating
  if can_move(s,di,dj) and
      m.ox == 0 and
      m.oy == 0 then
    -- We only track the tail
    -- during combat
    if (g.upd == cmbt_upd) then
      track_tail(s,di,dj)
    end
    s.i+=di
    s.j+=dj
    s.ox = -di*8
    s.oy = -dj*8
  else -- Bounce
    s.ox = di*4
    s.oy = dj*4
  end

  -- Slow collision/interaction
  -- detection
  for e in all(actors) do
    if e != s then
      interact(s,e,s.i,s.j)
    end
  end
end

function upd_pc(p)
  if p.ox==0 and p.oy==0 then
    p.frame=0
    return
  end
  local m = 0
  if (p.ox > 0) then
    p.ox-=2
    m = -1
  end
  if (p.ox < 0) then
    p.ox+=2
    m = 1
  end
  if (p.oy > 0) then
    p.oy-=2
    m = -1
  end
  if (p.oy < 0) then
    p.oy+=2
    m = 1
  end
  p.frame = p.frame + m
  p.frame = p.frame%p.frames
end

function track_tail(c,di,dj)
  local newx,newy=c.i+di,c.j+dj
  local nw_tail = {}
  for p in all(c.tail) do
    if newx==p[1] and
       newy==p[2] and
       c.bktrk == 0 then
      break
    end
    add(nw_tail,p)
  end

  if #nw_tail >= #c.tail then
    add(nw_tail, {c.i, c.j})
  end

  c.tail = nw_tail

end

-- Draws pc to screen
-- If x,y,f are provided then
-- drawn image will be static
function draw_pc(p,x,y,f)
  x = x or (p.i*8+p.ox)
  y = y or (p.j*8+p.oy)
  f = f or p.frame
  if debug then
    pal(12,7)
    spr(p.sp+f,p.i*8,p.j*8)
    pal()
  end
  spr(p.sp+f,x,y)
  render_path(p)
  -- -- HUD
  -- -- Draw Carrots collected
  -- for i=1,p.car do
  --   spr(220,128+m.i*8-m.ox-i*8,m.j*8-m.oy)
  -- end
  -- for i=p.car+1,5 do
  --   spr(219,128+m.i*8-m.ox-i*8,m.j*8-m.oy)
  -- end
  -- -- HP
  -- rect(1,1,p.maxhp,6,0)
  -- rectfill(2,2,p.hp-1,5,8)
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
  for i=0,3 do
    if (btnp(i)) pc:mv(getdx(i),getdy(i))
  end

  foreach(actors, function(s) s:up() end)

  -- Dummy way to enter combat
  if pc.i==1 and pc.j==1 and
     pc.ox==0 and pc.oy==0 then
    init_ini()
  end
end

function exp_drw()
  foreach(actors, function(s) s:dr() end)
  -- Portal to enter combat
  rect(7,8,15,16,9)
end

-->8
-- combat
function cmbt_ini()
  g.upd = cmbt_upd
  g.drw = cmbt_drw
  pturn = 1
  cmenu = {
    dr=menu_draw,
    up=menu_upd,
    s=0, -- selected option
    p=false -- option selected?
  }
  if (debug) pc.ini=21
  -- Order by initiative
  order_initiative(chars)
end


function cmbt_upd()
  foreach(actors, function(s) s:up() end)
  cmenu:up()
end

function cmbt_drw()
  foreach(actors, function(s) s:dr() end)
  cmenu:dr()
  -- draw roster
  for i,c in ipairs(chars) do
    c:dr((i-1)*10,0,0)
    local dx = 0
    if (c.ini < 10) dx=2
    ?c.ini,(i-1)*10+dx,10,8
  end
end

function menu_draw(self)
  local x,y=0,112
  local w,h=64,128-y
  text_box("what will "..chars[pturn].name.." do?",
          x,y,w,h,6,5)

  -- action menu bgnd
  draw_box(x+w,y,w,h,7,0)
  -- draw action selection box
  draw_box(x+w+2+self.s*16,y+2,12,12,7,9)

  -- draw sprites for actions
  -- The line below will allow
  -- us to only draw the action
  -- that we selected.
  -- ??? IDK if we want this for
  -- some reason
  -- for i=(self.p and self.s or 0),(self.p and self.s or 3) do
  for i=0,3 do
    spr(12+i,x+w+4+i*16,y+4)
  end

  -- display movement left
  if (self.p and self.s==0) then
    ?5*(chars[pturn].mvmt-#chars[pturn].tail),x+w+4,y-6,8
  end


end

function menu_upd(self)
  -- If we've made a pick
  if self.p then
    if (btnp(❎)) self.p = false
    -- Movement
    if cmenu.s == 0 then
      for i=0,3 do
        if (btnp(i)) pc:mv(getdx(i),getdy(i))
      end
    -- Attacks
    elseif cmenu.s==1 or 
           cmenu.s==2 then

    elseif cmenu.s==3 then
      pc:et()
      pturn=pturn%#chars + 1
      self.p = false
      self.s=0
    end
  else
    -- Menu interaction
    if (btnp(0)) self.s-=1
    if (btnp(1)) self.s+=1
    self.s = self.s%#pc.opts
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
  for e in all(actors) do
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
  rval = 20
  p = 0
  dflash=0
  foreach(actors, function(s) s:reset() end)
end

function init_drw()
  cls()
  pcenter("press ❎ to roll",40)
  -- draw roster
  for i,c in ipairs(chars) do
    c:dr(64+(i-1)*10,64)
    local dx = 0
    if (c.ini < 10) dx=2
    ?c.ini,64+(i-1)*10+dx,73,8
  end
  -- draw d20
  if rval==20 and dflash>0 then
    pal(7,dflash)
    dflash-=1
  end
  spr(192,16,56,2,4)
  spr(192,31,56,2,4,true)
  pal()
  -- show number on d20
  local rx = 28
  if (rval<10) rx+=2
  local rcolor = 10
  if (not roll) rcolor=8
  ?rval,rx,73,rcolor
  if (roll and debug) ?"ROLLING",0,0
end

function init_upd()
  if btnp(❎) then
    rtime=1
    roll=true
    p+=1
    g.upd = rollad20
  end
  -- +1 here helps us not change
  -- screens immediately once
  -- we roll the last char
  if (p==#chars+1) cmbt_ini()
end

-- Exponentially slow dice rolling
function rollad20()
  if (T%rtime==0) rval = flr(rnd(20)) + 1

  if (T%10==0) rtime*=2 

  if (rtime > 127) then
    g.upd = init_upd
    if (rval == 20) dflash=30
    chars[p].ini = rval
    roll = false
  end
end

-->8
-- credits

-->8
--tools

function draw_box(x,y,w,h,ic,bc)
  ic = ic or 5
  bc = bc or 0
  rect(x, y+1,(x+w)-1, y+h-2, bc)
  rect(x+1,y,(x+w)-2,y+h-1,bc)
  rectfill(x+1,y+2,(x+w)-2,(y+h)-3,ic)
  rectfill(x+2,y+1,(x+w)-3,(y+h)-2,ic)
end

function text_box(s,x,y,w,h,ic,bc)
  s = s or "TEST"
  x = x or 32
  y = y or 32
  w = w or 64
  h = h or 64
  ic = ic or 5
  bc = bc or 0
  draw_box(x,y,w,h,ic,bc)
  fit_string(s,x+3,y+h\2-6,w)
end

function ants_box(x,y,w,h,c)
  c = c or 0x8 -- red
  fillp(0x936c.936c>><(t()<<5&12) | 0x.8)
  rect(x,y,x+w,y+h,c)
  fillp()
end

-- Fits a string s into a
-- width w at position (x,y)
-- split by delim. d
function fit_string(s,x,y,w,d)
  d = d or " "
  local strs = split(s,d,false)
  local cw = 0
  local line = 0
  for str in all(strs) do
    if (cw+4*#str > w) then
      line+=1
      cw = 0
    end
    ?str,x+cw,y+6*line,0
    cw+=5*#str
  end
end

function rollad(num)
  return flr(rnd(num))+1
end

function order_initiative(a)
  for i=1,#a do
    local j = i
    while (j > 1) and (a[j-1].ini < a[j].ini) do
      a[j],a[j-1] = a[j-1],a[j]
      j = j - 1
    end
  end
end

-- print string s to approx. 
-- center of screen with y
-- height and color c
function pcenter(s,y,c)
  y = y or 64
  c = c or 7
  ?s,64-4*(#s\2),y,c
end

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

function is_char(a)
  return a.type=='pc' or 
         a.type=='en'
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
000000000000000088e8800088e8800008e8880008e8880c00888e80c0888e800000000000000000000000000000000008e888000088000008e8880000880000
000000000000000008ee880c08ee880008ee880c08ee8804c088ee804088ee800000000000000000000000000000000008ee880c08e8880008ee880c08e88800
007007000000000008f0f00408f0f0c00f0f0f040f0f0f0440f888f040f888f0000000000000000000000000000000000f0f0f0408ee88c00f0f0f0408ee88c0
00077000000000000effff040effff40ffffff040fffffff40ff88fffff88ff0000000000000000000000000000000000fffff040f0f0f400fffff040f0f0f40
00077000000000008888888f08888840088888fff8888800ff8888800088888f00000000000000000000000000000000888888ffffffff40888888ffffffff40
0070070000000000f8ee88000fee88f008ee880008ee88000088ee800088ee8000000000000000000000000000000000f8ee880008ee88f0f8ee880008ee88f0
00000000000000000888880008888800088888808888880008888880008888880000000000000000000000000000000008888800088888000888880008888800
00000000000000008888880088888880888800000000888000008888088800000000000000000000000000000000000088888880888888808888888088888880
000000000000000033bb30e0033b300003bb300f03bb3000f0033b3000033b300000000000000000000000000000000000000000000000000511556005115506
000000000000000003bbb30f33bbb3f003bbb30f03bbb30ff033bb30f033bb300000000000000000000000000000000000000000000000000510506005105006
00000000000000000340400f034040f00404040f0404040ff0433340f04333400000000000000000000000000000000000000000000000000550506005505006
00000000000000000144440f014444f0044444340444440f43443340f04334400000000000000000000000000000000000000000000000000555556005555506
000000000000000033bbb33403bbb34033bbb30e33bbb334e03bbb33433bbb330000000000000000000000000000000000000000000000000444155044411555
00000000000000004555650e045565e04555650e0555650ee0565554e05655500000000000000000000000000000000000000000000000000404526040455206
00000000000000000333330e033333e00323330e0333230ee0333230e03233300000000000000000000000000000000000000000000000000444550044455500
0000000000000000002020e002000200000020000020000e00020000e00002000000000000000000000000000000000000000000000000000200020000202000
00000000000000000677665006776605067766050677660550667760506677600000000000000000000000000000000000000000000000000000000000000000
00000000000000000670605006706005060606050606060550666660506666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000660605006606005060606050606060550666660506666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000666665006666605555666050666666650666665666666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000555766055577666515676665556760566677665506776650000000000000000000000000000000000000000000000000000000000000000
000000000000000005156d5051566d05555dd605515dd600506d6665006d66650000000000000000000000000000000000000000000000000000000000000000
000000000000000005556600555666000066d6005556660000666600006666550000000000000000000000000000000000000000000000000000000000000000
00000000000000000d000d0000d0d00000d000000000d00000000d00000d00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444440444944444444444044444440000000000000000000000000000000000000000000000000000000000000000044444444444904444444444444490444
49994440999444444999444049994440000000000000000000000000000000000000000000000000000000000000000049994449999404494999444999940449
44499440444449944449944044499440000000000000000000000000000000000000000000000000000000000000000044499444444409994449944444440999
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444404444444444444444000000000000000000000000000000000000000000000000000000000000000044440444444444444444044444444444
99944444499944409994444499944444000000000000000000000000000000000000000000000000000000000000000099940449499944499994044949994449
44494994444444404449499444494994000000000000000000000000000000000000000000000000000000000000000044490999444444444449099944444444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444440444944444444444044444440000000000000000000000000000000000000000000000000000000000000000044444444444904444444444444490444
44494440999444444449444044494440000000000000000000000000000000000000000000000000000000000000000044494449999404494449444999940449
44994440444449944499444044994440000000000000000000000000000000000000000000000000000000000000000044994444444409994499444444440999
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99944444444994409994444499944444000000000000000000000000000000000000000000000000000000000000000099944444444994409994444444499440
44949994444444404494999444949994000000000000000000000000000000000000000000000000000000000000000044949999444444404494999944444440
44449444444444404444944444449444000000000000000000000000000000000000000000000000000000000000000044449444444444404444944444444440
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444440444944444444444044444440000000000000000000000000000000000000000000000000000000000000000044444444444904444444444444490444
49994440999444444999444049994440000000000000000000000000000000000000000000000000000000000000000049994449999404494999444999940449
44499440444449944449944044499440000000000000000000000000000000000000000000000000000000000000000044499444444409994449944444440999
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444404444444444444444000000000000000000000000000000000000000000000000000000000000000044440444444444444444044444444444
99944444499944409994444499944444000000000000000000000000000000000000000000000000000000000000000099940449499944499994044949994449
44494994444444404449499444494994000000000000000000000000000000000000000000000000000000000000000044490999444444444449099944444444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444440444944444444444044444440000000000000000000000000000000000000000000000000000000000000000044444444444904444444444444490444
44494440999444444449444044494440000000000000000000000000000000000000000000000000000000000000000044494449999404494449444999940449
44994440444449944499444044994440000000000000000000000000000000000000000000000000000000000000000044994444444409994499444444440999
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99944444444994409994444499944444000000000000000000000000000000000000000000000000000000000000000099944444444994409994444444499440
44949994444444404494999444949994000000000000000000000000000000000000000000000000000000000000000044949999444444404494999944444440
44449444444444404444944444449444000000000000000000000000000000000000000000000000000000000000000044449444444444404444944444444440
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
