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
      add(st_game, { type = 'FIRE', payload = coll_void })
    elseif(fastfall.state == 20) then
      plr.vel_y = 24
    end

    add(st_ability, { type = 'NEXT_STATE', payload = 'fastfall' })

    -- TODO: This should be done in the player stream...
    -- if y > GROUND_Y then do all this stuff
    if(plr.y >= GROUND_Y and fastfall.state >= 1) then
      add(st_ability, { type = 'RESET_STATE', payload = 'fastfall' })
      add(st_player, { type = 'POS_Y', payload = GROUND_Y })
      add(st_player, { type = 'VEL_Y', payload = 0 })
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
    local G = 0.4
    local addlG = 1
    local v0 = -4.2

    if(jump.state == 1) then
      add(st_player, { type = 'VEL_Y', payload = v0})
      add(st_ability, { type = 'NEXT_STATE', payload = 'jump' })
    elseif(jump.state >= 2 and plr.y >= GROUND_Y) then
      add(st_ability, { type = 'RESET_STATE', payload = 'jump' })
      add(st_player, { type = 'POS_Y', payload = GROUND_Y })
      add(st_player, { type = 'VEL_Y', payload = 0 })
    else
      if(plr.vel_y >= 1.0) then
        addlG = 2.8
      elseif(btn(BTN_A) == false) then -- TODO: Can ref fkey above?
        addlG = 2.8
      end

      add(st_player, { type = 'VEL_Y', payload = plr.vel_y + (G * addlG) })
    end

    return plr
  end
}


abilities = {
  fastfall = fastfall,
  jump = jump
}

-- TODO: Should be an event
coll_kill_p = function () player.alive = false end
inc_score = function () add(st_player, { type = 'INC_SCORE', payload = 1 }) end
coll_void = function () end

collisions = {
  flower = inc_score,
  fire = coll_kill_p,
  comet = coll_kill_p
}

-- Btn -> Ability[]
function get_by_key(key)
  return reduce(function (acc, x)
    if(x.fkey == key and x.state == 0 and x.enabled == true) then
     return x
    end

    return acc
  end
  , nil, abilities)
end

function proc_events_player() 
  for k, v in pairs(st_game) do
      if(v.type == 'DEATH') then
        drop_all(game_state.entities)
        game_state.lock_input = 20
        scrn.upd = upd_lose
        scrn.drw = drw_lose
      end
  end
  st_game = {}
end


function init_player()
  player = {
    frame = 0,
    x = 24,
    y = GROUND_Y,
    vel_x = 0,
    vel_y = 0,
    w = 8,
    h = 6,
    score = 0,
    alive = true,
    base_sprite = 5,
  }

  return player
end



function reset_player(player)
  player.frame = 0
  player.x = 24
  player.y = GROUND_Y
  player.vel_x = 0
  player.vel_y = 0
  player.score = 0

  return player
 end
