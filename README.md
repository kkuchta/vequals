# Vequals: the operator no one asked for.

Ruby has leftward assignment (`x = 3`) and rightward assignment (`3 => x`). Now I give you, vertical assignment:

```
3
‖
x
```

That's right, this library provides a functioning vertical assignment operator. Yes it works, no it's not a good idea. It was built as an exploration of metaprogramming with Tracepoint and Ripper. This repo contains Bad Ideas™ and Ridiculous Code®. I've answered the question "can it be done?" but only you can answer the question "should it be done?" But as a hint: no. No it should not be done.

If you want a runthrough on how it works, check out my companion talk at RubyConf2021. I'll update this readme with a link to that talk on youtube when it's up. If you're reading this in, like, 2023, and there's still no link, I probably forgot.

## Getting Started

You probably _shouldn't_ get started. Getting started only ever leads to bad things; here more than ever.

But if you really must, you can `require 'vequals'`, then call `Vequals.enable`, after which point the `‖` operator will "work"... if you can call it that.

## Files

- `vequals.rb` contains everything needed to use the vequals operator.
- `minimized_vequals.rb` is a stripped-down version of the same thing I made for the talk - no logging, no comments, etc.
- `prep.rb` is a file for manual testing. Go there and run that file if you want to play around with vequals.

## Prior Art

There was a great version of vertical assignment created by one of the ruby core contributors. I can't find it right now because I'm on a plane with no wifi, but it was implemented in C as part of the core language and it was very nifty. You should go check that out.

Update: it's here, and of course is was by mame (Yusuke Endoh) https://bugs.ruby-lang.org/issues/17768
