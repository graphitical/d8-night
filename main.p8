pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- main
g = {} -- games state
c = {} -- config

function _init()
 -- mmenu_ini()
 cmbt_ini()
end

function _update()
 g.upd()
end

function _draw()
 g.drw()
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
-->8
-- combat
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

function move_pc(pc,di,dj)
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
 if not fget(mget(nxt[1],nxt[2]),0) and
    (pc.mvmt-#nw_tail) >= 0 then
  pc.i = nxt[1]
  pc.j = nxt[2]
  pc.tail = nw_tail
 end
end

function cmbt_ini()
 g.upd = cmbt_upd
 g.drw = cmbt_drw
 cmbt_states={init=0,menu=1,move=2,mattack=3,rattack=4,end_turn=5}
--  cmbt_state = cmbt_states.menu
 cmbt_state = cmbt_states.init
 s=0

 c.players = {}
 local pc = {
  name="blue bunny",
  i=4, 
  j=4, 
  mvmt=8, 
  tail={}, 
  bktrk = 0,
  sp=255}
 add(c.players,pc)
 local pc = { 
  name = "brown bunny",
  i = 8, 
  j = 4, 
  mvmt=6, 
  tail={}, 
  bktrk = 0,
  sp=254}
 add(c.players,pc)
 c.num_turns = #c.players
 c.player_turn = 1
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
    if (btnp(4)) cmbt_state = s + 2
  -- Movement State
  elseif cmbt_state == cmbt_states.move then
    if (btnp(⬅️)) move_pc(pc,-1, 0)
    if (btnp(➡️)) move_pc(pc, 1, 0)
    if (btnp(⬆️)) move_pc(pc, 0,-1)
    if (btnp(⬇️)) move_pc(pc, 0, 1)
    if (btnp(4)) cmbt_state = cmbt_states.menu
  -- TODO: Attack states. Items?
  elseif cmbt_state == cmbt_states.mattack or cmbt_state == cmbt_states.rattack then
    -- Prevent backtracking if we've
    -- already moved
    if #pc.tail > 0 then
      pc.bktrk = #pc.tail
    end
    if (btnp(4)) cmbt_state = cmbt_states.menu
  elseif cmbt_state == cmbt_states.end_turn then
    end_turn(pc)
    cmbt_state = cmbt_states.menu
    s = 0
  else
    -- if (btnp(4)) cmbt_state = cmbt_states.menu
  end
end

function roll_init()
  local scrn_sz = 128;
  rect(0, 86, scrn_sz-1, scrn_sz-1, 6)
  rectfill(1, 87, 126, 126, 0)
  spr(192,0,92,2,4)
  spr(192,16,92,2,4,true)
  print("21",13,109,8)
end

function cmbt_drw()
 cls()
 map()
 -- Draw all PCs & NPCs
 for pc in all(c.players) do
  palt(0,false) -- keeps black eyes as black
  spr(pc.sp,pc.i*8,pc.j*8)
  palt()
  render_path(pc)
 end
 -- Focus on current PC
 local pc = c.players[c.player_turn]
 -- Draw combat menu
 if cmbt_state == cmbt_states.init then
  roll_init()
 else
  cmbt_menu(pc,s,cmbt_state)
 end
 color(8)
--  print(s)
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
00000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000070000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007700000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700070770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000770007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000700070004000400050005000c000c00
0000007700770000000000000000000000000000000000000000000000000000000000000000000000000000000000007e707e704e404e405e505e50cec0cec0
0000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000007e707e704e404e405e505e50cec0cec0
000000000770070000000000000000000000000000000000000000000000000000000000000000000000000000000000777777704444444055555550ccccccc0
000000000007707000000000000000000000000000000000000000000000000000000000000000000000000000000000707770704044404050555050c0ccc0c0
000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000777777704444444055555550ccccccc0
000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000077e7700044e4400055e55000ccecc00
__gff__
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101
__map__
0101010101010101010101010101010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010101010101010102010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010101010101010102010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010101010101010102010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010101010101010102010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010101010101010102010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020202020202020202010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010102020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
