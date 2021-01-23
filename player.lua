player = {
  battery = 100,
  display_battery = 100,
  level = 1,
  frame = 0,
  half_frame = 0,
  x = 24,
  y = GROUND_Y,
  w = 8,
  h = 6,
  vel_x = 0,
  vel_y = 0,
  score = 0,
  base_sprite = 5,
  damage_frames = 0
}
fastfall = {
  name = 'fastfall',
  msg = 'You got FASTFALL. Press down to drop to the ground.',
  enabled = false,
  fkey = BTN_D,
  state = 0,
  f = function(plr)
    if(fastfall.state == 1) then
      plr.vel_y = 0
    elseif(fastfall.state == 5) then
      plr.vel_y = 12
    elseif(fastfall.state == 20) then
      plr.vel_y = 24
    end

    fastfall.state += 1

    if(plr.y >= GROUND_Y and fastfall.state >= 1) then
      abilities.fastfall.state = 0
      add(st_game, { type = 'PLAYER_POS_Y', payload = GROUND_Y })
      add(st_game, { type = 'PLAYER_VEL_Y', payload = 0 })
    end

    return plr
  end
}

jump = {
  name = 'jump',
  msg = 'It\'s JUMP. You just get this.',
  enabled = true,
  fkey = BTN_A,
  state = 0,
  f = function (plr)
    local G = 0.8
    local addlG = 0.3
    local v0 = -3.8

    if(jump.state == 1) then
      sfx(0)
      add(st_game, { type = 'PLAYER_VEL_Y', payload = v0})
      jump.state += 1
    elseif(jump.state >= 2 and plr.y >= GROUND_Y) then
      -- TODO if we put this into the event stream, it gets wiped out before it gets
      -- intercepted in the next frame...
      abilities.jump.state = -1
      add(st_game, { type = 'PLAYER_POS_Y', payload = GROUND_Y })
      add(st_game, { type = 'PLAYER_VEL_Y', payload = 0 })
      jump.state += 1
    else
      if(plr.vel_y >= 2.5) then
        addlG = 0.4
      elseif(btn(jump.fkey) == false) then -- TODO: Can ref fkey above?
        addlG = 0.7
      end

      add(st_game, { type = 'PLAYER_VEL_Y', payload = plr.vel_y + (G * addlG) })
      jump.state += 1
    end

    return plr
  end
}


abilities = {
  fastfall = fastfall,
  jump = jump
}

function abilities_do_things()
  for k, v in pairs(st_game) do
    if(v.type == 'ABILITY_FIRE' and abilities[v.payload].state == 0) then
      abilities[v.payload].state = 1
    end
    if(v.type == 'ABILITY_STOP_FIRE') then
      abilities[v.payload].state = 0
    end
  end
end

function player_does_things() 
  for k, v in pairs(st_game) do
    if(v.type == 'PLAYER_VEL_Y') then
      player.vel_y = v.payload
    end
    if(v.type == 'PLAYER_POS_Y') then
      player.y = v.payload
    end
    if(v.type == 'PLAYER_BATTERY_DOWN') then
      player.battery -= v.payload
      player.display_battery = player.battery
    end
    if(v.type == 'PLAYER_COLLISION') then
      if(v.payload.sprite.type == 'flower') then
        player.score += POINTS_PER_FLOWER
        sfx(1)
      end
      if(v.payload.sprite.type == 'comet') then
        player.battery -= DAMAGE_PER_COMET
        player.display_battery = player.battery
        player.damage_frames = 30
        sfx(2)
      end
    end
    if(v.type == 'LEVEL_UP') then
      player.level += 1
      if player.level <= #battery_levels then
        player.battery += battery_levels[player.level]
      end
    end
    if(v.type == 'DAY_END_DEFEAT') then
      reset_player()
    end
  end
end


function reset_player()
  player.score = 0
  player.battery = 100 
  player.display_battery = 100 
  player.frame = 0
  player.half_frame = 0
  player.x = 24
  player.y = GROUND_Y
  player.vel_x = 0
  player.vel_y = 0
  player.damage_frames = 0
end
