function upd_win()
  handle_level_tween()
end

function upd_lose()
  handle_menu()
end

function upd_title()
  handle_menu()
end

function handle_menu()
  local lvl_len = len(game_state.levels)   
  if(game_state.lock_input == 0) then
    if(btnp(BTN_A) or btnp(BTN_B)) then return init_game(game_state) end
    if(btnp(BTN_D) and (game_state.current_level_idx > 1)) then game_state.current_level_idx -= 1 end
    if(btnp(BTN_U) and (game_state.current_level_idx < lvl_len)) then game_state.current_level_idx += 1 end
  end
  if(game_state.lock_input > 0) then
    game_state.lock_input -= 1
  end
end

function handle_level_tween()
  local lvl_len = len(game_state.levels)   
  if(game_state.lock_input == 0) then
    -- TODO
    --  change this next_level call to an event
    --  make this  "current level" thing a local? can we persist it somehow? just
    --    get it out of the game_state
    --  Try to make sure only god function modifies game state so things don't get weird
    if(btnp(BTN_A) or btnp(BTN_B)) then return next_level(game_state) end
    if(btnp(BTN_D) and (game_state.current_level_idx > 1)) then game_state.current_level_idx -= 1 end
    if(btnp(BTN_U) and (game_state.current_level_idx < lvl_len)) then game_state.current_level_idx += 1 end
  end
  if(game_state.lock_input > 0) then
    game_state.lock_input -= 1
  end
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

