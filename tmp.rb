trace = TracePoint.new() do |tp|
  puts "Got line #{tp.lineno}, #{tp.event}"
end

trace.enable do
  9
  7
  x = 3
  "foo"
  y = x + 4
end
