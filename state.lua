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
