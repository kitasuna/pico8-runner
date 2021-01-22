function len(xs)
  local count = 0
  for k, v in pairs(xs) do
    count += 1
  end
  return count
end

--[[
-- seq - the sequence to slice
-- s - the starting index (inclusive)
-- e - the ending index (exclusive)
--]]
function slice(seq, s, e)
  if e > s then
    return {}
  end

  local tmp = {}
  for i = s,e do
    add(tmp, seq[i])
  end

  return tmp
end


function concat(seq1, seq2)
  for v in all(seq2) do
    add(seq1, v)
  end

  return seq1
end

function qsort(seq)
  if #seq == 0 or #seq == 1 then
    return seq
  end

  local pivot = seq[flr(len(seq) / 2)]
  local left = {}
  local right = {}
  del(seq, pivot)

  for v in all(seq) do
    if v <= pivot then
      add(left, v)
    else
      add(right, v)
    end
  end

  local left_sorted = qsort(left)
  -- add pivot
  add(left_sorted, pivot)

  local right_sorted = qsort(right)

  local combined = concat(left_sorted, right_sorted)
  return combined
end

function val_in_seq(seq, val, buffer)
  for s in all(seq) do
    if val >= (s - buffer) and val <= (s + buffer) then
      return true
    end
  end
  return false
end

function drop_all_sprites(ss)
  foreach(ss, function(s)
      return del(ss, s)
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

function print_rj(str, y, clr)
  local strlen = #str
  print(str, 128 - (4 * strlen), y, clr)
end
