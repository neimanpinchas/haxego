# haxego

Haxe to Go Compiler

## Why GoLang
* Great Performance vs GC Balance
* Great Solid Tooling
* Faster compilation then CPP
* Truly cross platform (win, lin, bsd, wasm, avr, ++)
* Bunch of backend libraries
* Together with go2hx, we could work with both together.

## Idea

Based on ideas (and code) from luaxe https://github.com/bradparks/LuaXe/tree/master/luaxe/boot

OOP concepts in golang (https://github.com/luciotato/golang-notes/blob/master/OOP.md)

hx2go (https://github.com/pxshadow/go2hx)

Almost like Javascript, Plus some static typing/structs for simple objects to speed it up forther https://github.com/owenthereal/godzilla

Using vendor folder, as a hack to bypass folangs per pc software repos

## discussion links

https://community.haxe.org/t/go2hx-work-in-progress/2821

https://community.haxe.org/t/how-to-make-the-haxe-compiler-emit-a-separate-type-for-each-generic/3889

## Roadmap

### OOP
- [x] ClassMaker class (could be modified later for other languages , nim, pascal)
- [ ] inheritance
### stdlib
- [x] boot.go increment and decrement.
- [ ] boot.go for basic functions (trace)
[ ] implement sys
- [ ] Dynamic
- [ ] Json
### Language elements
- [ ] try/catch
### Compiler
- [ ] change to https://github.com/RobertBorghese/reflaxe
- [ ] gettype function support generics
- [ ] clean up GoPrinter.hx





## Support

Currently I am working on it only early morning, and late nights (usualy after going over the manual process of converting a project from rich haxe to poor golang), I wish I could work on it more time, if you wish too you may consider a pull request  (link?) or sponsor some time. https://www.paypal.com/donate/?hosted_button_id=LXPXVLSBCSVEG
