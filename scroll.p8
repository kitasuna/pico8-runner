pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- venusian botanist
map_x = 0
diff = {0, 0}
ground_y = 80
GROUND_Y = 80 -- switch to this eventually

scroll_speed = 1
speed_mult = 2

player = {}
st_game = {}
st_player = {}
st_ability = {}
--[[
  GameState :: {
    distance :: { meters :: Int, kilometers :: Int },
    dist_thresh :: Int,
    global_cooldown :: Int,
    lock_input :: Int, -- for holding menu screen
    flowers :: [],
    fires :: [],
    comets :: [],
    current_level :: Int,
    current_level_idx :: Int,
  }
]]--
#include const.lua
#include player.lua
game_state = {
  distance = { meters = 0, kilometers = 0},
  global_cooldown = 0,
  lock_input = 0,
  dist_thresh = 256,
  flowers = {},
  baddies = {},
  current_level = {},
  current_level_idx = 1,
  levels = {
    {
      num = 0,
      goal = 5
    },
    {
      num = 1,
      goal = 20
    }
  }
}


scrn = {}


_debug = true

#include helper.lua
#include init.lua
#include menus.lua

function _update()
  scrn.upd()
end

function _draw()
  scrn.drw()
end

function gen_update(gen, gs)
  if (gen.cooldown > 0) then
    gen.cooldown -= 1
  end

  if(gs.global_cooldown > 0) then
    return gen
  end

  if(gen.cooldown <= 0) then
      -- Add thing
      gen.emit(gen.target)
      
      local buff = flr(gen.sprite_width / speed_mult) + 1 -- adding one for kicks
      gs.global_cooldown = buff

      -- Reset cooldown
      local nxt = flr(rnd(gen.cooldown_max - gen.cooldown_min))

      -- Max width of fires (consecutive sprites, in this case)
      local f0 = gs.distance.kilometers > 1 and 1 or 0
      local f1 = gs.distance.kilometers > 3 and 1 or 0
      local max_width = 1 + f0 + f1

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
    gen.cooldown_max = gen.cooldown_max - (gs.distance.kilometers / 10)
    if(gen.cooldown_max < gen.cooldown_min) then
      gen.cooldown_max = gen.cooldown_min
    end
  end

  return gen
end


function shift_map(m, diff)
  m -= diff
  if(m < -127) then
    m = 0
  end

  return m
end

function calc_distance(mkm, thresh)
  mkm.meters += 1 
  if(mkm.meters > thresh) then
    mkm.kilometers += 1
    mkm.meters = 0
  end
  return mkm
end


function upd_player_pos(player)
  player.y += player.vel_y

  if(player.y >= ground_y) then
    player.y = ground_y
    player.vel_y = 0
    current_player_abil = base -- MIGHT need to remove this later...
    add(st_ability, { type = 'EXEC', payload = 'base'})
  end

  return player
end

function upd_game()
  -- Scroll map
  map_x = shift_map(map_x , scroll_speed * speed_mult)

  -- Increment distance traveled
  game_state.distance = calc_distance(game_state.distance, game_state.dist_thresh)

  -- Update sprite pos
  foreach(game_state.flowers, shift_sprite)
  foreach(game_state.baddies, shift_sprite)

  -- Remove sprite if necessary
  game_state.flowers = drop_offscreen(game_state.flowers)
  game_state.baddies = drop_offscreen(game_state.baddies)

  -- Check flower collision
  foreach(game_state.flowers, bb_coll_bad(game_state.flowers, player, collisions))

  -- Check obstacle collision
  foreach(game_state.baddies, bb_coll_bad(game_state.baddies, player, collisions))
  
  -- Update global cooldown (spaces out sprites)
  if(game_state.global_cooldown > 0) then game_state.global_cooldown -=1 end

  -- Update the generators
  fl_gen = gen_update(fl_gen, game_state)
  fire_gen = gen_update(fire_gen, game_state)
  comet_gen = gen_update(comet_gen, game_state)

  -- Kinda feel like stream-y stuff should go around here...
  local abil
  if(btnp(BTN_A)) then
    abil = get_by_key(BTN_A)
    current_player_abil = abil
    add(st_ability, { type = 'RESET_STATE', payload = abil.name})
    add(st_ability, { type = 'EXEC', payload = abil.name })
  end

  current_player_abil.f(player)
  upd_player_pos(player)

  if(btnp(BTN_D)) then
    abil = get_by_key(BTN_D)
    current_player_abil = abil
    add(st_ability, { type = 'RESET_STATE', payload = abil.name })
    add(st_ability, { type = 'EXEC', payload = abil.name })
  end

  if(btnp(BTN_B)) then
    add(st_ability, { type = 'TOGGLE', payload = 'fastfall' } )
  end

  -- update player animation
  if(game_state.distance.meters % 3 == 0) then
    if(player.frame == 0) then
      player.frame = 1
    else
      player.frame = 0
    end
  end

  -- TODO: Add event here
  if(player.score >= game_state.current_level.goal) then
    game_state.lock_input = 20
    abilities.fastfall.enabled = true
    scrn.upd = upd_win
    scrn.drw = drw_win
  end

  
  if(player.alive != true) then
    add(st_game, {type = 'DEATH', payload = {}})
  end

  proc_st_game() -- TODO: Maybe eventually this takes / returns game state... mad side-effects though
  abilities = proc_st_ability(abilities)
  player = proc_st_player(player)
end


function proc_st_game()
  for k, v in pairs(st_game) do
      if(v.type == 'DEATH') then
        -- foreach(game_state.baddies, sprite_drop(game_state.baddies))
        drop_all(game_state.baddies)
        game_state.lock_input = 20
        scrn.upd = upd_lose
        scrn.drw = drw_lose
      end
  end
  st_game = {}
end

-- Ability[] -> Ability[]
function proc_st_ability(abilities)
  for k, v in pairs(st_ability) do
    if(v.type == 'TOGGLE') then
      abilities[v.payload].enabled = not abilities[v.payload].enabled
    end
    if(v.type == 'EXEC') then
      add(st_player, { type = 'EXEC', payload = abilities[v.payload] })
      -- update collision here
    end
    if(v.type == 'NEXT_STATE') then
      abilities[v.payload].state += 1
    end
    if(v.type == 'RESET_STATE') then
      abilities[v.payload].state = 0
      -- update collision here
    end
  end
  st_ability = {}
  return abilities
end

function proc_st_player(player)
  for k, v in pairs(st_player) do
    if(v.type == 'EXEC') then
      player.immune = v.payload.immune -- TODO: Concat is more sensible here...
    end
  end

  return player
end

function drw_game()
  cls(0)
  map(0,0,map_x,0,16,16)
  map(0,0,map_x+128,0,16,16)

  if(_debug) then
    print("debug mode", 0, 0, 11)

    -- Sprite /generator data
    -- print("flcool: "..fl_gen.cooldown, 44, 0, 11)
    -- print("flcmax: "..fl_gen.cooldown_max, 44, 6, 11)
    -- print("dudes: "..len(game_state.baddies), 64, 6, CLR_GRN)

    -- Player stats
    -- print("ab: ", 88, 6, 12)
    -- print("FF", 112, 6, abilities.fastfall.enabled and CLR_GRN or CLR_RED)
    -- print("alive: "..tostr(player.alive), 44, 18, 11)
    -- print("p.vy: "..player.vel_y, 70, 0, CLR_RED)
    -- print("ff: "..fastfall.state, 70, 15, CLR_GRN)
    --print("gcd: "..global_cooldown, 36, 6, 11)
   
    -- Game state (score, level, etc)
    print("score: "..player.score, 36, 21, CLR_BLU)
    print("l: "..game_state.current_level.num.." g:"..game_state.current_level.goal, 0, 21, CLR_GRN)
    -- print("jumpst: "..jump.state, 0, 28, CLR_GRN)
    -- print("flwrs: "..len(game_state.flowers), 0, 28, CLR_GRN)
    -- print("m:km "..game_state.distance.meters..":"..game_state.distance.kilometers, 44, 6, CLR_GRN)

    -- Abilities
    local nexty = 0
    local ab_msgs = {
      current_player_abil.name..":a0",
      tostr(abilities.fastfall.enabled)..":f.e",
      tostr(abilities.fastfall.state)..":f.s",
      tostr(abilities.jump.enabled)..":j.e",
      tostr(abilities.jump.state)..":j.s"
    }
    foreach(ab_msgs, function(s) 
      print_rj(s, nexty, CLR_GRN)
      nexty += 6
      end)
  end

  foreach(game_state.flowers, sprite_draw)
  foreach(game_state.baddies, sprite_draw)

  player_draw(player)
end


function shift_sprite(s)
  s.x -= s.v * speed_mult 
end

function drop_offscreen(ss)
  foreach(ss, function(s)
    if(s.x < -16) then
      return sprite_drop(ss, s)
    end
  end)

  return ss 
end

function drop_all(ss)
  foreach(ss, function(s)
    return sprite_drop(ss, s)
  end)

  return ss 
end

function bb_coll(ss, playerS, cb)
  return function (s1)
    if (
          playerS.x < (s1.x + s1.buff_w) + (s1.w - s1.buff_w)
      and playerS.x + playerS.w > (s1.x + s1.buff_w)
      and playerS.y + playerS.h > s1.y
      and playerS.y < s1.y + s1.h
      ) then
      sprite_drop(ss, s1)
      cb(1)
    end
  end
end

function bb_coll_bad(ss, playerS, coll_map)
  return function (s1)
    if (
          playerS.x < (s1.x + s1.buff_w) + (s1.w - s1.buff_w)
      and playerS.x + playerS.w > (s1.x + s1.buff_w)
      and playerS.y + playerS.h > s1.y
      and playerS.y < s1.y + s1.h
      ) then
      sprite_drop(ss, s1)
      coll_map[s1.type]()
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
  target = game_state.flowers,
  stacks = false,
  emit = function (ss)
    local s = { x = 128, y = ground_y, idx = 4, w=8, buff_w = 0, h=8, v=1, type = 'flower'}
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
  target = game_state.baddies,
  stacks = true,
  emit = function (ss)
    local s = { x = 128, y = GROUND_Y, idx = 7, w=6, buff_w = 0, h=5, v=1, type = 'fire'}
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
  target = game_state.baddies,
  stacks = false,
  emit = function(ss)
    local s = { x = 128, y = 58, idx = 8, w=6, buff_w=0, h=6, v=2, type = 'comet'}
    add(ss, s)
    return ss
  end
}

function sprite_drop(ss, s)
  del(ss, s)
end

function player_draw(p)
  spr((p.base_sprite + p.frame), p.x, p.y)
end

__gfx__
00000000aaaaaaaa4444444440444044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaa4aaaa4044404444440444002220000056600000566000088880000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaaaaaaaaaa022a22000666660006666600888888000bb0000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaaaaaaaaaaaaa4aa00222000665585866655858688898800babbb00000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa4aaaaaaaaaaaaaaa00080000066666600666666088999800aaabbbbb00000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaaaaaaaaaa08888800050000505050050589999800aaabbbb000000000000000000000000000000000000000000000000000000000
00000000a4aaaa4aaaaaaa4aaaaa4aaa00888000565005650600006009aa9000babbb00000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaa00080000050000505050050500aa00000bb0000000000000000000000000000000000000000000000000000000000000
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
