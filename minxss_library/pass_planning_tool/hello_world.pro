function hello_world
  value = 2
  print, 'hello world', value
  times_two = func_test(value)
  print, times_two
  return, times_two
end

function func_test, input
  data_out = input*3
  return, data_out
end