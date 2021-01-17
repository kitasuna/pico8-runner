pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- venusian botanist

-- map's current x-coordinate, not constant
map_x = 0

-- y coord of ground
GROUND_Y = 80

-- how many points per flower
POINTS_PER_FLOWER = 3
-- how much damage a comet causes
DAMAGE_PER_COMET = 10

scroll_speed = 1
speed_mult = 1

-- Event stream
st_game = {}

-- ... world
world = {}

#include const.lua
#include player.lua
#include state.lua

scrn = {}
points_needed = {}
distances = {}
battery_levels = {}

function _init()
  -- points needed to get a battery upgrade
  -- we can generate this later when we get things sorted
  points_needed = { (POINTS_PER_FLOWER * 5), (POINTS_PER_FLOWER * 10) }

  -- how far we want the player to be able to travel
  -- should be aggregate distances, so distances[i] <= distances[i+1]
  distances = { 400 , 1000 }

  -- distance[i] / 4
  battery_levels = { 100, 150 }
  scrn.drw = drw_title
  scrn.upd = upd_title
end

_debug = true

#include helper.lua
#include menus.lua

function _update60()
  scrn.upd()
end

function _draw()
  scrn.drw()
end


function build_world()
  local tmp = {}
  local current_max_distance = 0

  for i=1,#points_needed do
    -- subtract 42 from distances here to account for stuff that gets generated towards the end of the level
    add(tmp, add_flowers(points_needed[i], current_max_distance, (distances[i] - 42), 0))
    current_max_distance += distances[i]
  end

  -- append all those tables together
  -- TODO: Optimization: sort this so we can use it more efficiently later
  local flowers = {}
  for i=1,len(tmp) do
    for j=1,len(tmp[i]) do
      add(flowers, tmp[i][j])
    end
  end

  tmp = {}
  current_max_distance = 0
  for i=1,#points_needed do
    -- subtract 42 from distances here to account for stuff that gets generated towards the end of the level
    add(tmp, add_obstacles(0.05 / i * 2, current_max_distance, (distances[i] - 42)))
    current_max_distance += distances[i]
  end

  -- append all those tables together
  local obstacles = {}
  for i=1,len(tmp) do
    for j=1,len(tmp[i]) do
      add(obstacles, tmp[i][j])
    end
  end


  return {
    flowers=flowers,
    obstacles=obstacles
  }
end

function add_obstacles(freq, min_distance, max_distance)
  local range = max_distance - min_distance
  local base = flr(range * freq)
  local high_end = flr(base * 1.5)
  local low_end = flr(base * 0.5)
  printh("base: "..base)
  printh("low_end: "..low_end)
  printh("high_end: "..high_end)
  local obstacles = {}
  local current_distance = min_distance
  -- while #obstacles < 8 do
  while current_distance < max_distance do
    printh("current_distance: "..current_distance)
    local interval = low_end + flr(rnd(high_end - low_end))
    local next_obstacle = interval + current_distance
    local heights = {76, 76, 76, 62, 48}
    local velocities = {2, 2, 4, 4, 8}
    local height_idx = flr(rnd(#heights)) + 1
    add(obstacles, { x = next_obstacle, y = heights[height_idx], v = 2})
    current_distance += interval
  end

  return obstacles
end

function add_flowers(how_many_points, minimum_distance, maximum_distance, buffer)
  local flowers = {}
  local points_so_far = 0
  printh("hmp: "..how_many_points)
  printh("min dist: "..minimum_distance)
  printh("max dist: "..maximum_distance)
  while points_so_far <= how_many_points do
     -- randomly pick an x position
     local my_x = flr(rnd(maximum_distance + buffer - minimum_distance)) + minimum_distance
     -- check to make sure it's not already in the sequence
     if (val_in_seq(flowers, my_x, 4) == false) then
       points_so_far += POINTS_PER_FLOWER
       add(flowers, my_x)
     end
  end

  return flowers
end

function debugger_does_things()
  for k, v in pairs(st_game) do
    printh("GOT EVENT: "..v.type)
  end
end

function god_does_things()
  for k, v in pairs(st_game) do
    if(v.type == "PLAYER_COLLISION") then
      -- TODO handle game logic based on entity type
      del(game_state.entities, v.payload.sprite)
    end
    if(v.type == 'DEATH') then
      drop_all(game_state.entities)
      game_state.lock_input = 20
      scrn.upd = upd_tween
      scrn.drw = drw_lose
    end
    if(v.type == 'DAY_END_VICTORY') then
      drop_all(game_state.entities)
      game_state.lock_input = 20
      game_state.half_distance = 0
      scrn.upd = upd_tween
      scrn.drw = drw_win
    end
    if(v.type == 'DAY_END_DEFEAT') then
      drop_all(game_state.entities)
      game_state.lock_input = 20
      game_state.distance = 0
      game_state.half_distance = 0
      scrn.upd = upd_tween
      scrn.drw = drw_lose
    end
    if(v.type == 'DAY_NEXT') then
      game_state.current_day += 1
      scrn.drw = drw_game
      scrn.upd = upd_game
    end
    if(v.type == 'GAME_CLEAR') then
      scrn.drw = drw_clear
      scrn.upd = upd_clear
    end
  end
end

function upd_game()
  -- Scroll map
  map_x -= (scroll_speed * speed_mult)
  if(map_x < -127) then
    map_x = 0
  end

  -- Increment distance traveled
  game_state.half_distance += 1
  if(game_state.half_distance >= 3) then
    game_state.distance += 1
    game_state.half_distance = 0

    if(game_state.distance % 4 == 0) then
      add(st_game, { type = 'PLAYER_BATTERY_DOWN', payload = 1})
    end
  end

  -- Update sprite pos
  foreach(game_state.entities, shift_sprite)

  -- Remove sprite if necessary
  drop_offscreen(game_state.entities)

  -- Check entity collision
  foreach(game_state.entities, run_collision(game_state.entities, player))
  
  -- check current level to see if we need to fire a flower off
  for f in all(world.flowers) do
    if game_state.distance == f and game_state.half_distance == 0 then
      printh("flower in main game loop at: "..f)
      fl_gen.emit(game_state.entities)
    end
  end

  -- check current level to see if we need to add an obstacle
  for f in all(world.obstacles) do
    if game_state.distance == f.x and game_state.half_distance == 0 then
      printh("obstacle in main game loop at: x:"..f.x..", y:"..f.y)
      comet_gen.emit(game_state.entities, f.v, f.y)
    end
  end

  local abil
  if(btnp(BTN_A) and abilities.jump.enabled == true) then
    add(st_game, { type = 'ABILITY_FIRE', payload = abilities.jump.name})
  end


  if(btnp(BTN_D) and abilities.fastfall.enabled == true) then
    -- Fastfalling turns off jump updates
    add(st_game, { type = 'ABILITY_STOP_FIRE', payload = abilities.jump.name })
    add(st_game, { type = 'ABILITY_FIRE', payload = abilities.fastfall.name })
  end

  -- update player animation
  if(game_state.distance % 3 == 0) then
    if(player.frame == 0) then
      player.frame = 1
    else
      player.frame = 0
    end
  end

  if(player.battery <= 0) then
    if player.level + 1 <= #points_needed and player.score >= points_needed[player.level] then
      add(st_game, { type = 'DAY_END_VICTORY', payload = nil })
    elseif player.score >= points_needed[player.level] then
      add(st_game, { type = 'GAME_CLEAR', payload = nil })
    else
      add(st_game, { type = 'DAY_END_DEFEAT', payload = nil })
    end
  end

  -- TODO: Also make this an event?
  player.y += player.vel_y

  -- Process events
  god_does_things()
  abilities_do_things()
  for k, v in pairs(abilities) do
    if(abilities[k].state > 0) then
      abilities[k].f(player)
    end
  end
  player_does_things()
  debugger_does_things()

  -- Reset message queue
  st_game = {}

end

function proc_st_game()
  for k, v in pairs(st_game) do
      if(v.type == 'DEATH') then
        drop_all(game_state.entities)
        game_state.lock_input = 20
        scrn.upd = upd_lose
        scrn.drw = drw_lose
      end
  end
end

function drw_game()
  cls(0)
  map(0,0,map_x,0,16,16)
  map(0,0,map_x+128,0,16,16)

  print("score: "..player.score, 0, 0, CLR_BLU)
  print("day: "..game_state.current_day, 64, 0, CLR_BLU)
  print("distance: "..game_state.distance, 0, 8, CLR_GRY)
  print("battery: "..player.battery, 0, 16, CLR_YLW)

  if(_debug) then
    -- use this for printing debug stuff to screen
  end

  foreach(game_state.entities, sprite_draw)

  player_draw(player)
end


function shift_sprite(s)
  s.x -= s.v * speed_mult 
  if s.dv != nil then
    s.v += s.dv
  end
end

function drop_offscreen(ss)
  foreach(ss, function(s)
    if(s.x < -16) then
      return del(ss, s)
    end
  end)
end

function drop_all(ss)
  foreach(ss, function(s)
    return del(ss, s)
  end)

  return ss 
end

function run_collision(ss, playerS)
  return function (s1)
    if (
          playerS.x < (s1.x + s1.buff_w) + (s1.w - s1.buff_w)
      and playerS.x + playerS.w > (s1.x + s1.buff_w)
      and playerS.y + playerS.h > s1.y
      and playerS.y < s1.y + s1.h
      ) then
      add(st_game, { type = 'PLAYER_COLLISION', payload = { player = player, sprite = s1 } })
    end
  end
end

function sprite_draw(s)
  spr(s.idx, s.x, s.y)
end

fl_gen = {
  cooldown = 120,
  cooldown_min = 60,
  cooldown_max = 120,
  sprite_width = 8 + 4, -- extra wide buffer
  last_width = 0,
  emit = function (ss)
    local sp_num = 17 -- 17 is current lowest sprite index
    local s = { x = 128, y = GROUND_Y, idx = sp_num, w=8, buff_w = 0, h=8, v=1, type = 'flower'}
    add(ss, s)
    return ss
  end
}

fire_gen = {
  cooldown = 90,
  cooldown_min = 30,
  cooldown_max = 90,
  sprite_width = 8,
  last_width = 0,
  emit = function (ss)
    local s = { x = 128, y = GROUND_Y, idx = 7, w=8, buff_w = 0, h=6, v=1, type = 'fire'}
    add(ss, s)
    return ss
  end
}

comet_gen = {
  sprite_width = 8,
  last_width = 0,
  emit = function(ss, v, y)
    local s = { x = 128, y = y, idx = 8, w=6, buff_w=0, h=6, v=v, dv=0.05, type = 'comet'}
    add(ss, s)
    return ss
  end
}

function player_draw(p)
  spr((p.base_sprite + p.frame), p.x, (p.y > GROUND_Y) and GROUND_Y or p.y)
end

__gfx__
00000000aaaaaaaa4444444440444044800000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaa4aaaa4044404444440444880000880056600000566000088880000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaaaaaaaaaa008008800666660006666600888888000bb0000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaaaaaaaaaaaaa4aa00088800665585866655858688898800babbb00000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa4aaaaaaaaaaaaaaa00088000066666600666666088999800aaabbbbb00000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaaaaaaaaaa00808880050000505050050589999800aaabbbb000000000000000000000000000000000000000000000000000000000
00000000a4aaaa4aaaaaaa4aaaaa4aaa08800080565005650600006009aa9000babbb00000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaa88000088050000505050050500aa00000bb0000000000000000000000000000000000000000000000000000000000000
0000000000000000ccccc00000000e99000000000007dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002220000cc8c0000990e0990000000000ddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000022a220000c8c000099e00000000a00007ddd7dd00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000222000000b0030000e0990000aa0000dd7ddd700000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000080000000bb3300000e99000aaaaa00000770000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000888880000000b000990e000baaa33ab0000770000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000088800000003300099e00000ba333b00007777000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000008000000bb3b000000e00000b33b000007dd7000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000404006040080400b0400d0400f040100401204013040150401604018040190401a0401c0401d0401f04021040230402404026040280402b0402d0302f030310303302035020380203a0203d0103e010
000100000c5500e55010550125501355014550155501655016550175501755017550175501655012550105500c5500b5500a5500a5500a5500a5500a5500a5500b5500c5500d5500f5501355016550185501a550
000200002d6502b650296502665023650206501d6501a650186401664014640136401264011630106300d6300c6300b6300a63009620086200762006620056100461003610026000260001600006000060001600
