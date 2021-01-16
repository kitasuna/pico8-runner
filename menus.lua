function upd_tween()
  if(game_state.lock_input > 0) then
    game_state.lock_input -= 1
  end

  if(game_state.lock_input == 0) then
    if(btnp(BTN_A) or btnp(BTN_B)) then 
      add(st_game, { type = 'DAY_NEXT', payload = nil })
    end
  end

  god_does_things()
  st_game = {}
end

function upd_title()
  if(game_state.lock_input == 0) then
    if(btnp(BTN_A) or btnp(BTN_B)) then 
      world = build_world()

      for obj in all(world) do
          printh("flower at: "..obj)
      end

      game_state.lock_input = 0
      game_state.distance = 0
      game_state.half_distance = 0
      game_state.entities = drop_all_sprites(game_state.entities)
      scrn.drw = drw_game
      scrn.upd = upd_game
    end
  end
  if(game_state.lock_input > 0) then
    game_state.lock_input -= 1
  end
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
end

function drw_lose()
  cls()
  print("YOU LOOOOOOOOOOOOOOOOSE", 0, 0, CLR_RED)
end

function drw_win()
  cls()
  print("VICTOLY", 0, 0, CLR_GRN)
end

