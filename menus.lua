function upd_win()
  handle_menu()
end

function upd_lose()
  handle_menu()
end

function upd_title()
  handle_menu()
end

function handle_menu()
  local lvls = len(levels)   
  if(btnp(BTN_A) or btnp(BTN_B)) then init_game() end
  if(btnp(BTN_D) and (current_level_idx > 1)) then current_level_idx -= 1 end
  if(btnp(BTN_U) and (current_level_idx < lvls)) then current_level_idx += 1 end
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
  print("NEXT LEVEL:"..current_level_idx, 23, 30, CLR_ORN)
end
function drw_lose()
  cls()
  print("YOU LOOOOOOOOOOOOOOOOSE", 0, 0, CLR_RED)
  print("NEXT LEVEL:"..current_level_idx, 23, 30, CLR_ORN)
end

function drw_win()
  cls()
  print("VICTOLY", 0, 0, CLR_GRN)
  print("NEXT LEVEL:"..current_level_idx, 23, 30, CLR_ORN)
end

