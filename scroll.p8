pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- venusian botanist
map_x = 0
diff = {0, 0}
ground_y = 48

player_base_sprite = 5

sprite_speed = 1
scroll_speed = 1
speed_mult = 2

player = {}
game_state = {
  distance = { meters = 0, kilometers = 0},
  dist_thresh = 256,
  flowers = {},
  obstacles = {}
}

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

scrn = {}

current_level = {}
current_level_idx = 1

global_cooldown = 0

_debug = true

#include const.lua
#include helper.lua
#include init.lua

function _update()
  scrn.upd()
end

function _draw()
  scrn.drw()
end

#include menus.lua

function gen_update(gen, gs)
  if (gen.cooldown > 0) then
    gen.cooldown -= 1
  end

  if(global_cooldown > 0) then
    return gen
  end

  if(gen.cooldown <= 0) then
      -- Add thing
      gen.emit(gen.target)
      
      local buff = flr(gen.sprite_width / speed_mult) + 1 -- adding one for kicks
      global_cooldown = buff

      -- Reset cooldown
      local nxt = flr(rnd(gen.cooldown_max - gen.cooldown_min))


      -- Max width of obstacles (consecutive sprites, in this case)
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

function add_p_score(p)
  return function (val) 
    p.score += val
  end
end

function kill_p(p)
  return function()
    p.alive = false
  end
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

function upd_game()
  -- Scroll map
  map_x = shift_map(map_x , scroll_speed * speed_mult)

  -- Increment distance traveled
  game_state.distance = calc_distance(game_state.distance, game_state.dist_thresh)

  -- Update sprite pos
  foreach(game_state.flowers, shift_sprite)
  foreach(game_state.obstacles, shift_sprite)

  -- Remove sprite if necessary
  game_state.flowers = drop_offscreen(game_state.flowers)
  game_state.obstacles = drop_offscreen(game_state.obstacles)

  -- Check flower collision
  foreach(game_state.flowers, bb_coll(game_state.flowers, player, add_p_score(player)))

  -- Check obstacle collision
  foreach(game_state.obstacles, bb_coll(game_state.obstacles, player, kill_p(player)))
  
  -- Update global cooldown (spaces out sprites)
  if(global_cooldown > 0) then global_cooldown -=1 end

  -- Update the generators
  fl_gen = gen_update(fl_gen, game_state)
  obs_gen = gen_update(obs_gen, game_state)

  local G = 0.4
  local v0 = -4.0

  if(player.y == ground_y and btnp(BTN_A)) then -- initial press
    player.btn_length = 0
    player.btn_freeze = false
    player.vel_y = v0
    player.y += player.vel_y
  elseif(player.y != ground_y and player.btn_freeze == false and btn(BTN_A)) then -- holding
    player.btn_length += 1
    player.y += player.vel_y
    player.vel_y += G
  elseif(player.y != ground_y and player.btn_freeze == false) then -- release
    player.btn_freeze = true
    player.y += player.vel_y
    player.vel_y += G
  elseif(player.y != ground_y) then -- released
    player.y += player.vel_y
    player.vel_y += G * 3
  end

  if(player.y >= ground_y) then
    player.y = ground_y
    player.vel_y = 0
  end

  -- update player animation
  if(game_state.distance.meters % 3 == 0) then
    if(player.frame == 0) then
      player.frame = 1
    else
      player.frame = 0
    end
  end

  if(player.score >= current_level.goal) then
    scrn.upd = upd_win
    scrn.drw = drw_win
  end

  
  if(player.alive != true) then
    scrn.upd = upd_lose
    scrn.drw = drw_lose
  end
end

function drw_game()
  cls(0)
  map(0,0,map_x,0,16,16)
  map(0,0,map_x+128,0,16,16)

  if(_debug) then
    print("debug mode", 0, 0, 11)

    local flower_len = 0
    local obs_len = 0
    -- foreach(game_state.flowers, function(s) flower_len += 1 end)
    -- foreach(game_state.obstacles, function(s) obs_len += 1 end)
    print("dudes: "..len(game_state.flowers) + len(game_state.obstacles), 0, 6, CLR_GRN)
    -- print("m:km "..game_state.distance.meters..":"..game_state.distance.kilometers, 44, 6, CLR_GRN)
    print("l: "..current_level.num.." g:"..current_level.goal, 0, 14, CLR_GRN)
    -- print("flcool: "..fl_gen.cooldown, 44, 0, 11)
    -- print("flcmax: "..fl_gen.cooldown_max, 44, 6, 11)
    -- print("alive: "..tostr(player.alive), 44, 18, 11)
    -- print("p.vy: "..player.vel_y, 88, 6)
    print("p.BL: "..player.btn_length, 88, 12)
    --print("gcd: "..global_cooldown, 36, 6, 11)
    print("score: "..player.score, 36, 14, CLR_BLU)
  end

  foreach(game_state.flowers, sprite_draw)
  foreach(game_state.obstacles, sprite_draw)

  player_draw(player)
end


function shift_sprite(s)
  s.x -= sprite_speed * speed_mult 
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
          playerS.x < s1.x + s1.w 
      and playerS.x + playerS.w > s1.x
      and playerS.y + playerS.h > s1.y
      and playerS.y < s1.y + s1.h
      ) then
      sprite_drop(ss, s1)
      cb(1)
    end
  end
end

function sprite_draw(s)
  spr(s.idx, s.x, s.y)
end

function flower_gen(ss)
  local s = { x = 128, y = ground_y, idx = 4, w=8, h=8}
  add(ss, s)
  return ss
end

function obstacle_gen(ss)
  local s = { x = 128, y = ground_y, idx = 7, w=8, h=8}
  add(ss, s)
  return ss
end
  
fl_gen = {
  cooldown = 120,
  cooldown_min = 60,
  cooldown_max = 120,
  sprite_width = 8 + 4, -- extra wide buffer
  last_width = 0,
  target = game_state.flowers,
  stacks = false,
  emit = flower_gen
}

obs_gen = {
  cooldown = 90,
  cooldown_min = 30,
  cooldown_max = 90,
  sprite_width = 8,
  last_width = 0,
  target = game_state.obstacles,
  stacks = true,
  emit = obstacle_gen
}

function sprite_drop(ss, s)
  del(ss, s)
end

function player_draw(p)
  spr((player_base_sprite + p.frame), p.x, p.y)
end

__gfx__
00000000aaaaaaaa4444444440444044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaa4aaaa4044404444440444002220000056600000566000008888000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaaaaaaaaaa022a22000666660006666600088888800000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaaaaaaaaaaaaa4aa002220006655858666558586088899800000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa4aaaaaaaaaaaaaaa000800000666666006666660088999800000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaaaaaaaaaa088888000500005050500505889999880000000000000000000000000000000000000000000000000000000000000000
00000000a4aaaa4aaaaaaa4aaaaa4aaa008880005650056506000060899aa9880000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaa000800000500005050500505899aa9880000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0203020302030203020203020302030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
