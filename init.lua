function _init()
  scrn.drw = drw_title
  scrn.upd = upd_title
end

function init_game(gs)
  gs.current_level = gs.levels[gs.current_level_idx] 

  init_player()

  gs.lock_input = 0
  gs.distance = { meters = 0, kilometers = 0 }
  gs.flowers = drop_all_sprites(game_state.flowers)
  gs.fires = drop_all_sprites(game_state.fires)
  gs.comets = drop_all_sprites(game_state.comets)
  scrn.drw = drw_game
  scrn.upd = upd_game

  return gs
end

function next_level(gs)
  gs.current_level = gs.levels[gs.current_level_idx] 

  player = reset_player(player)

  gs.lock_input = 0
  gs.distance = { meters = 0, kilometers = 0 }
  gs.flowers = drop_all_sprites(game_state.flowers)
  gs.fires = drop_all_sprites(game_state.fires)
  gs.comets = drop_all_sprites(game_state.comets)
  scrn.drw = drw_game
  scrn.upd = upd_game

  return gs
end
