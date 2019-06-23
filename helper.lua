function len(xs)
  local count = 0
  -- foreach(t, function(s) count += 1 end)
  for k, v in pairs(xs) do
    count += 1
  end
  return count
end

function drop_all_sprites(ss)
  foreach(ss, function(s)
      return sprite_drop(ss, s)
  end)

  return ss 
end

function compose(g, f)
  return function(x)
    return g(f(x))
  end
end

function reduce(f, acc0, xs)
  local acc

  acc = acc0
  for k, v in pairs(xs) do
    acc = f(acc, v) 
  end

  return acc
end
