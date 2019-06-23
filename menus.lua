function upd_win()
  game_state = handle_level_tween(game_state)
end

function upd_lose()
  game_state = handle_menu(game_state)
end

function upd_title()
  game_state = handle_menu(game_state)
end

-- GameState -> GameState
function handle_menu(gs)
  local lvl_len = len(gs.levels)   
  if(gs.lock_input == 0) then
    if(btnp(BTN_A) or btnp(BTN_B)) then return init_game(gs) end
    if(btnp(BTN_D) and (gs.current_level_idx > 1)) then gs.current_level_idx -= 1 end
    if(btnp(BTN_U) and (gs.current_level_idx < lvl_len)) then gs.current_level_idx += 1 end
  end
  if(gs.lock_input > 0) then
    gs.lock_input -= 1
  end
  return gs
end

-- GameState -> GameState
function handle_level_tween(gs)
  local lvl_len = len(gs.levels)   
  if(gs.lock_input == 0) then
    if(btnp(BTN_A) or btnp(BTN_B)) then return next_level(gs) end
    if(btnp(BTN_D) and (gs.current_level_idx > 1)) then gs.current_level_idx -= 1 end
    if(btnp(BTN_U) and (gs.current_level_idx < lvl_len)) then gs.current_level_idx += 1 end
  end
  if(gs.lock_input > 0) then
    gs.lock_input -= 1
  end
  return gs
end

function handle_lose()
  handle_menu()
end

function handle_win()
  handle_menu()
end

function handle_title()
  handle_menu()
end

function drw_title()
  cls()
  print("VENUSIAN BOTANIST", 0, 0, CLR_YLW)
  print("PRESS x TO JUMP", 0, 6, CLR_YLW)
  print("PRESS x LONGER TO JUMP MORE", 0, 12, CLR_YLW)
  print("GET THESE", 23, 24, CLR_GRN)
  print("DON'T TOUCH THESE", 23, 36, CLR_RED)
  spr(4, 15, 22)
  spr(7, 15, 34)
  -- print("lEVEL sELECT:"..game_state.current_level_idx, 23, 30, CLR_ORN)
end
function drw_lose()
  cls()
  print("YOU LOOOOOOOOOOOOOOOOSE", 0, 0, CLR_RED)
  print("NEXT LEVEL:"..game_state.current_level_idx, 23, 30, CLR_ORN)
end

function drw_win()
  cls()
  print("VICTOLY", 0, 0, CLR_GRN)
  print("NEXT LEVEL:"..game_state.current_level_idx, 23, 30, CLR_ORN)
end

