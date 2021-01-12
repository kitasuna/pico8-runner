pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- venusian botanist
map_x = 0
diff = {0, 0}
GROUND_Y = 80 -- switch to this eventually
scroll_speed = 1
speed_mult = 1

player = {}

-- Event stream
st_game = {}

-- ... world
world = {}

#include const.lua
#include player.lua
#include state.lua
scrn = {}

_debug = true

#include helper.lua
#include init.lua
#include menus.lua

function _update60()
  scrn.upd()
end

function _draw()
  scrn.drw()
end

flower_points = 3
-- points needed to get a battery upgrade
points_needed = { (flower_points * 5), (flower_points * 10) }
-- we can generate this later when we get things sorted
total_score = flower_points * 15
-- how far we want the player to be able to travel
distances = { 400 , 600 }
-- distance[i] / 4
battery_levels = { 100, 150 }

function build_world()
  local levels = {}
  local current_max_distance = 0

  for i=1,#points_needed do
    -- subtract 16 here to account for stuff that gets generated towards the end of the level
    add(levels, build_day(points_needed[i], (distances[i] - 42), current_max_distance, 0))
    current_max_distance += distances[i]
  end
  return levels
end

function build_day(how_many_points, maximum_distance, offset, buffer)
  local flowers = {}
  local points_so_far = 0

  while points_so_far <= how_many_points do
     -- randomly pick an x position
     local my_x = flr(rnd(maximum_distance + buffer - offset)) + offset
     -- check to make sure it's not already in the sequence
     if (val_in_seq(flowers, my_x, 4) == false) then
       points_so_far += flower_points
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
      scrn.upd = upd_lose
      scrn.drw = drw_lose
    end
    if(v.type == 'LEVEL_CLEAR') then
      drop_all(game_state.entities)
      game_state.lock_input = 20
      abilities[v.payload.enable_on_clear].enabled = true
      scrn.upd = upd_win
      scrn.drw = drw_win
    end
    if(v.type == 'LEVEL_NEXT') then
      game_state.current_level = game_state.levels[v.payload] 

      -- TODO maybe do this with an event...
      init_player()

      game_state.lock_input = 0
      game_state.distance = 0
      game_state.half_distance = 0
      game_state.entities = drop_all_sprites(game_state.entities)
      scrn.drw = drw_game
      scrn.upd = upd_game
    end
  end
end

function gen_update(gen, gs)
  if (gen.cooldown > 0) then
    gen.cooldown -= 1
  end

  if(gs.global_cooldown > 0) then
    return 
  end

  if(gen.cooldown <= 0) then
      -- Add thing
      gen.emit(gen.target)
      
      local buff = flr(gen.sprite_width / speed_mult) + 1 -- adding one for kicks
      gs.global_cooldown = buff

      -- Reset cooldown
      local nxt = flr(rnd(gen.cooldown_max - gen.cooldown_min))

      -- Max width of fires (consecutive sprites, in this case)
      local max_width = 1

      -- If this generator stacks
      -- _and_
      -- If we haven't hit max width yet
      -- _and_
      -- the RNG gave us a multiple of 3 (random factor)
      if(gen.stacks == true and gen.last_width < (max_width - 1) and nxt % 3 == 0) then
        gen.cooldown = buff -- sprite width / speed_mult
        gen.last_width += 1
      else
        gen.last_width = 0
        gen.cooldown = nxt + gen.cooldown_min
      end
  end

  -- Adjusts cooldown boundaries based on level distance
  if(gen.cooldown_max > gen.cooldown_min) then
    gen.cooldown_max = gen.cooldown_max - (gs.distance / 10)
    if(gen.cooldown_max < gen.cooldown_min) then
      gen.cooldown_max = gen.cooldown_min
    end
  end

  return
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
  
  -- Update global cooldown (spaces out sprites)
  if(game_state.global_cooldown > 0) then game_state.global_cooldown -=1 end

  -- check current level to see if we need to fire a flower off
  for f in all(world[game_state.current_level_idx]) do
    if game_state.distance == f and game_state.half_distance == 0 then
      printh("flower in main game loop at: "..f)
      fl_gen.emit(game_state.entities)
    end
  end
  -- Update the generators
  -- gen_update(fl_gen, game_state)
  -- gen_update(fire_gen, game_state)
  -- gen_update(comet_gen, game_state)

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
    add(st_game, {type = 'LEVEL_CLEAR', payload = game_state.current_level})
  end

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

  -- TODO: Also make this an event?
  player.y += player.vel_y
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

  print("score: "..player.score, 36, 21, CLR_BLU)
  print("distance: "..game_state.distance, 36, 28, CLR_GRY)
  print("battery: "..player.battery, 36, 38, CLR_YLW)

  if(_debug) then
    -- use this for printing debug stuff to screen
  end

  foreach(game_state.entities, sprite_draw)

  player_draw(player)
end


function shift_sprite(s)
  s.x -= s.v * speed_mult 
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
  target = game_state.entities,
  stacks = false,
  emit = function (ss)
    local sp_num = flr(rnd(5)) + 17 -- 17 is current lowest sprite index
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
  target = game_state.entities,
  stacks = true,
  emit = function (ss)
    local s = { x = 128, y = GROUND_Y, idx = 7, w=8, buff_w = 0, h=6, v=1, type = 'fire'}
    add(ss, s)
    return ss
  end
}

comet_gen = {
  cooldown = 150,
  cooldown_min = 120,
  cooldown_max = 210,
  sprite_width = 8,
  last_width = 0,
  target = game_state.entities,
  stacks = false,
  emit = function(ss)
    local s = { x = 128, y = 58, idx = 8, w=6, buff_w=0, h=6, v=2, type = 'comet'}
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
