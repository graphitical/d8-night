pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- main
g = {}
g.upd = mmenu_upd
g.drw = mmenu_drw

function _init()
 mmenu_ini()
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
 for p in all(pc.tail) do
  x0 = p[1]*8-1
  y0 = p[2]*8
  rect(x0,y0,x0+8,y0+8,8)
 end
end

function end_turn(pc)
 player_turn = player_turn % 2 + 1
 pc.tail = {}
 pc.mvmt = 30
end

function move_pc(pc,di,dj)
 nxt = {pc.i+di,
        pc.j+dj}
 
 nw_tail = {}
 for p in all(pc.tail) do
  if nxt[1]==p[1] and
     nxt[2]==p[2] then
   break
  end
  nw_tail[#nw_tail+1] = p
 end
 -- if the tail is growing
 -- then add our current pos
 -- as the end of the tail
 if #nw_tail >= #pc.tail then
  nw_tail[#nw_tail+1] = {pc.i,
                         pc.j}
 end

 nw_mvmt = 30 - 5*#nw_tail
 
 -- if open and we have 
 -- movement we can move there 
 if mget(nxt[1],nxt[2]) == 2 and
    nw_mvmt >= 0 then
  pc.i = nxt[1]
  pc.j = nxt[2]
  pc.tail = nw_tail
  pc.mvmt = nw_mvmt
 end

end

function cmbt_ini()
 cls()
 players = {}
 pc = { i=4, j=4, mvmt=30, tail={}, sp=1}
 add(players,pc)
 pc = { i = 8, j = 4, mvmt=30, tail={}, sp=6}
 add(players,pc)
 num_turns = #players
 player_turn = 1
 g.upd = cmbt_upd
 g.drw = cmbt_drw
end

function cmbt_upd()
 pc = players[player_turn]
 if (btnp(⬅️)) move_pc(pc,-1, 0)
 if (btnp(➡️)) move_pc(pc, 1, 0)
 if (btnp(⬆️)) move_pc(pc, 0,-1)
 if (btnp(⬇️)) move_pc(pc, 0, 1)
 if (btnp(4))  end_turn(pc)
end

function cmbt_drw()
 cls()
 map()
 for pc in all(players) do
  spr(pc.sp,pc.i*8,pc.j*8)
 end
 color(8)
 print(player_turn)
 render_path(players[player_turn])
 print(pc.mvmt)
end
-->8
-- credits
__gfx__
00000000000000006666666688888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c000c001111111600000008050005000400040007000700000000000000000000000000000000000000000000000000000000000000000000000000
00700700cec0cec011111116000000085e505e504e404e407e707e70000000000000000000000000000000000000000000000000000000000000000000000000
00077000cec0cec011111116000000085e505e504e404e407e707e70000000000000000000000000000000000000000000000000000000000000000000000000
00077000ccccccc01111111600000008555555504444444077777770000000000000000000000000000000000000000000000000000000000000000000000000
00700700c0ccc0c01111111600000008505550504044404070777070000000000000000000000000000000000000000000000000000000000000000000000000
00000000ccccccc01111111600000008555555504444444077777770000000000000000000000000000000000000000000000000000000000000000000000000
000000000ccecc001111111600000008055e5500044e4400077e7700000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
