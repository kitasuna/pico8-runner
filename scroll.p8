pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- venusian botanist
map_x = 0
diff = {0, 0}
GROUND_Y = 80 -- switch to this eventually
scroll_speed = 1
speed_mult = 2

player = {}

-- Event stream
st_game = {}

#include const.lua
#include player.lua
#include state.lua

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
      player = reset_player(player)

      game_state.lock_input = 0
      game_state.distance = { meters = 0, kilometers = 0 }
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

  return
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
  map_x -= (scroll_speed * speed_mult)
  if(map_x < -127) then
    map_x = 0
  end

  -- Increment distance traveled
  game_state.distance = calc_distance(game_state.distance, game_state.dist_thresh)

  -- Update sprite pos
  foreach(game_state.entities, shift_sprite)

  -- Remove sprite if necessary
  drop_offscreen(game_state.entities)

  -- Check entity collision
  foreach(game_state.entities, run_collision(game_state.entities, player))
  
  -- Update global cooldown (spaces out sprites)
  if(game_state.global_cooldown > 0) then game_state.global_cooldown -=1 end

  -- Update the generators
  gen_update(fl_gen, game_state)
  gen_update(fire_gen, game_state)
  gen_update(comet_gen, game_state)

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
  if(game_state.distance.meters % 3 == 0) then
    if(player.frame == 0) then
      player.frame = 1
    else
      player.frame = 0
    end
  end

  -- TODO: Add event here
  if(player.score >= game_state.current_level.goal) then
    add(st_game, {type = 'LEVEL_CLEAR', payload = game_state.current_level})
  end

  
  if(player.alive != true) then
    add(st_game, {type = 'DEATH', payload = {}})
  end



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

  if(_debug) then
    -- printh("debug mode")

    -- Sprite /generator data
    -- print("flcool: "..fl_gen.cooldown, 44, 0, 11)
    -- print("flcmax: "..fl_gen.cooldown_max, 44, 6, 11)

    -- Player stats
    -- print("ab: ", 88, 6, 12)
    -- print("alive: "..tostr(player.alive), 44, 18, 11)
    -- print("p.vy: "..player.vel_y, 70, 0, CLR_RED)
    -- print("ff: "..fastfall.state, 70, 15, CLR_GRN)
    --print("gcd: "..global_cooldown, 36, 6, 11)
   
    -- Game state (score, level, etc)
    print("score: "..player.score, 36, 21, CLR_BLU)
    -- print("l: "..game_state.current_level.num.." g:"..game_state.current_level.goal, 0, 21, CLR_GRN)
    -- print("jumpst: "..jump.state, 0, 28, CLR_GRN)
    -- print("m:km "..game_state.distance.meters..":"..game_state.distance.kilometers, 44, 6, CLR_GRN)

    -- Abilities
    local nexty = 0
    local ab_msgs = {
      tostr(abilities.jump.enabled)..":j.e",
      tostr(abilities.jump.state)..":j.s",
      tostr(abilities.fastfall.state)..":f.s",
      tostr(abilities.fastfall.enabled)..":f.e",
      -- tostr(player.vel_y)..":p.vy",
      -- tostr(player.y)..":p.y",
    }
    foreach(ab_msgs, function(s) 
      print_rj(s, nexty, CLR_GRN)
      nexty += 6
      end)
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
    local s = { x = 128, y = GROUND_Y, idx = 4, w=8, buff_w = 0, h=8, v=1, type = 'flower'}
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
