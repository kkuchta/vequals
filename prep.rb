require './vequals_v2'

# This is just the test file for trying out weird things with vequals.

Vequals.enable

# "yay"
#  ‖   123
# foo  ‖
#     bar
# puts foo # "yay"
# puts bar # 123

        1
        ‖
x = x = x = x = x
‖   ‖   ‖   ‖   ‖
l = x = x = x = x
‖   ‖   ‖   ‖   ‖
l = x = x = x = l
‖   ‖   ‖   ‖   ‖
l = x = x = x = l
‖               ‖
i     =___=     i
‖      ‖ ‖      ‖
z      z z      z

# [3,  4,   5]
#  ‖   ‖    ‖
#  a = b <= 6
#  ‖        ‖
#  d   =>   c
#  ‖        ‖
#  x   ==   e
#  ‖        ‖
#  f = g =  h => z

# "foo" => bar
#           ‖
#         aaaaa
#         ‖   ‖
# c   =   b   ddd
# puts b # prints "foo"
# puts c # prints "foo"
# puts ddd # prints "foo"

# "foo" => bar
#           ‖
#         aaaaa
#         ‖
# c   =   b

# puts c == "foo"
# puts b == "foo"
# puts aaaaa == "foo"

# 3 => fooooooobaaaaar
#       ‖  ‖  ‖  ‖  ‖
#       d  e  f  g  h
# puts "h=#{h}"
# puts "e=#{e}"

# 7
# ‖
# x

# puts "x = #{x}"

# 3 => foobar => y
#        ‖       ‖
#        x       z
