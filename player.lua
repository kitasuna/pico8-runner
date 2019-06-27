-- Player -> Ability -> Player
-- runs some sort of callback function on the player to alter state
function identityE(x)
  return x
end

fastfall = {
    name = 'fastfall',
    msg = 'You got FASTFALL. Press down to drop to the ground.',
    enabled = false,
    immune = { 'fire' },
    fkey = BTN_D,
    state = 0,
    f = function(plr)
      if(fastfall.state == 0) then
        plr.vel_y = 0
      elseif(fastfall.state == 5) then
        plr.vel_y = 12
      elseif(fastfall.state == 20) then
        plr.vel_y = 24
      end

      fastfall.state += 1

      return plr
    end
}

jump = {
  name = 'jump',
  msg = 'It\'s JUMP. You just get this.',
  enabled = true,
  immune = { 'cookies', 'madoka' },
  fkey = BTN_A,
  state = 0,
  -- Player -> BtnState -> Player
  f = function (plr)
      local G = 0.4
      local addlG = 1
      local v0 = -4.4

      if(jump.state == 0) then jump.state = 1 end

      if(plr.y == GROUND_Y) then
        plr.vel_y = v0
      elseif(plr.vel_y >= 1.0) then
        addlG = 2.4
      elseif(btn(BTN_A) == false) then -- TODO: Can ref fkey above?
        addlG = 2.4
      end


      if(plr.y >= GROUND_Y) then
        jump.state = 0
      end

      -- Decelerate plr
      plr.vel_y += G * addlG

      return plr
  end
}

base = {
  name = 'base',
  msg = 'just for base case',
  enabled = true,
  fkey = nil,
  state = 0,
  immune = {},
  f = identityE
}

abilities = {
  base = base,
  fastfall = fastfall,
  jump = jump
}

-- TODO: Should be an event
function kill_p()
  player.alive = false
end

-- TODO: Should be an event
function add_p_score(val)
  return function()
    player.score += val
  end
end

collisions = {
  flower = add_p_score(1),
  fire = kill_p,
  comet = kill_p
}

current_player_abil = base

-- Btn -> Ability[]
function get_by_key(key)
  return reduce(function (acc, x)
    if(x.fkey == key and x.enabled == true) then
     return x
    end

    return acc
  end
  , current_player_abil, abilities)
end


function init_player()
  player = {
    frame = 0,
    x = 24,
    y = ground_y,
    vel_x = 0,
    vel_y = 0,
    w = 8,
    h = 6,
    score = 0,
    alive = true,
    base_sprite = 5,
    immune = {} -- :: String[]
  }

  return player
end



function reset_player(player)
  player.frame = 0
  player.x = 24
  player.y = ground_y
  player.vel_x = 0
  player.vel_y = 0
  player.score = 0

  return player
 end
