function _init()
  scrn.drw = drw_title
  scrn.upd = upd_title
end

function init_game(gs)
  gs.current_level = gs.levels[gs.current_level_idx] 

  init_player()

  world = build_world()

  for lvl in all(world) do
    for f in all(lvl) do
      printh("flower at: "..f)
    end
  end

  gs.lock_input = 0
  gs.distance = 0
  gs.half_distance = 0
  gs.entities = drop_all_sprites(game_state.entities)
  scrn.drw = drw_game
  scrn.upd = upd_game

  return gs
end

function next_level(gs)
  gs.current_level = gs.levels[gs.current_level_idx] 

  init_player()

  gs.lock_input = 0
  gs.distance = 0
  gs.half_distance = 0
  gs.entities = drop_all_sprites(game_state.entities)
  scrn.drw = drw_game
  scrn.upd = upd_game

  return gs
end
