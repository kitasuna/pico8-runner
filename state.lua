game_state = {
  distance = { meters = 0, kilometers = 0},
  global_cooldown = 0,
  lock_input = 0,
  dist_thresh = 256,
  entities = {},
  current_level = {},
  current_level_idx = 1,
  levels = {
    {
      num = 0,
      goal = 1,
      enable_on_clear = 'fastfall'
    },
    {
      num = 1,
      goal = 20,
      enable_on_clear = 'fastfall'
    }
  }
}
