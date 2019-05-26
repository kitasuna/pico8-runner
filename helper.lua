function len(t)
  local count = 0
  foreach(t, function(s) count += 1 end)
  return count
end
