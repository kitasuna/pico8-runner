function _init()
  scrn.drw = drw_title
  scrn.upd = upd_title
end

function init_game()
  current_level = levels[current_level_idx] 
  player = { frame = 0, x = 24, y = ground_y, vel_x = 0, vel_y = 0, acc_x = 0, acc_y = 0, w = 8, h = 8, score = 0, alive = true, btn_length = 0}
  game_state.distance = { meters = 0, kilometers = 0 }
  drop_all(game_state.flowers)
  drop_all(game_state.obstacles)
  scrn.drw = drw_game
  scrn.upd = upd_game
end
