from math import sqrt, pow, ceil
from random import rand
from streams import newFileStream, write, close
import strformat
import os

type Vector = object
    x: float64
    y: float64
    z: float64

proc sum(l: Vector, r: Vector): Vector {.inline.} = 
    Vector(x: l.x + r.x, y: l.y + r.y, z: l.z + r.z)

proc prod(l: Vector, r: float64): Vector {.inline.} = 
    Vector(x: l.x * r, y: l.y * r, z: l.z * r)

proc sprod(l: Vector, r: Vector): float64 {.inline.} = 
    l.x * r.x + l.y * r.y + l.z * r.z

proc vprod(l: Vector, r: Vector): Vector {.inline.} = 
    Vector(x: l.y * r.z - l.z * r.y, y: l.z * r.x - l.x * r.z, z: l.x * r.y - l.y * r.x)

proc norm(l: Vector): Vector {.inline.} =
    let fix = 1 / math.sqrt(l.x * l.x + l.y * l.y + l.z * l.z)
    Vector(x: l.x * fix, y: l.y * fix, z: l.z * fix)

let G = [0x0003C712,
    0x00044814,
    0x00044818,
    0x0003CF94,
    0x00004892,
    0x00004891,
    0x00038710,
    0x00000010,
    0x00000010]

proc tracer(o: Vector, d: Vector, n: var Vector, t: var float): int =
    t = 1e9
    var m = 0
    var p = -o.z / d.z
    if 0.01 < p:
        t = p
        n = Vector(x: 0, y: 0, z: 1)
        m = 1
    
    for k in countdown(18, 0):
        for j in countdown(8, 0):
            if 0 != (G[j.uint] and (1 shl k.uint)):
                var p = o.sum(Vector(x: float64(-k), y: 0, z: float64(-k - 4)))
                var b = p.sprod(d)
                var c = p.sprod(d) - 1
                var q = b * b - c
                if q > 0:
                    var s: float64 = -b - math.sqrt(q)
                    if (s < t) and (s > 0.01):
                        t = s.float64
                        n = (p.sum(d.prod(t))).norm()
                        m = 2
    return m

proc sampler(o: Vector, d: Vector): Vector =
    var n = Vector(x: 0, y: 0, z: 0)
    var t = 0.0
    var m = tracer(o, d, n, t)

    if m == 0:
        return Vector(x: 0.7, y: 0.6, z: 1.0).prod(math.pow(1 - d.z, 4.0))
    
    var h = o.sum(d.prod(t))
    var l = Vector(x: 9.0 + float64(rand(1.0)), y: 9.0 + float64(rand(1.0)), z: 16).sum(h.prod(-1)).norm()
    var r = d.sum(n.prod(n.sprod(d) * -2))

    var b = l.sprod(n)

    if b < 0 or tracer(h, l, n, t) != 0:
        b = 0
    
    if m == 1:
        h = h.prod(0.2)
        if 1.uint == (1.uint and uint(math.ceil(h.x) + math.ceil(h.y))):
            return Vector(x: 3.0, y: 1.0, z: 1.0).prod(b * 0.2 + 0.1)
        return Vector(x: 3, y: 3, z: 3).prod(b * 0.2 + 0.1)
    
    var p = 0.1

    if b > 0:
        p = math.pow(l.sprod(r), 99)
        return Vector(x: p, y: p, z: p).sum(sampler(h, r).prod(0.5))
    
    return Vector(x: 0, y: 0, z: 0).sum(sampler(h, r).prod(0.5))

when isMainModule:
    doAssert(paramCount() > 0, "Specify name of output file!")

    var g = Vector(x: -6, y: -16, z: 0).norm()
    var a = Vector(x: 0, y: 0, z: 1).vprod(g).norm().prod(0.002)
    var b = g.vprod(a).norm().prod(0.002)
    var c = a.sum(b).prod(-256).sum(g)

    var outFile = newFileStream(paramStr(1), fmWrite)
    defer: outFile.close()

    outFile.write("P6 512 512 255 ")
    for y in countdown(511, 0):
        for x in countdown(511, 0):
            var p = Vector(x: 13, y: 13, z: 13)
            for r in countdown(63, 0):
                var t = a.prod((float64(rand(1.0)) - 0.5) * 99).sum(b.prod((float64(rand(1.0)) - 0.5) * 99))
                p = sampler(Vector(x: 17, y: 16, z: 8).sum(t), t.prod(-1).sum(a.prod(float64(rand(1.0)) + float64(x)).sum(b.prod(float64(rand(1.0)) + float64(y))).sum(c).prod(16)).norm()).prod(3.5).sum(p)
            outFile.write(fmt"{chr(uint(p.x))}{chr(uint(p.y))}{chr(uint(p.z))}")