import re, os, glob, math
LIB="elite-source-code-library/library"
# prefer common, then enhanced, then advanced, then 6502sp
DIRS=["common","enhanced","advanced","6502sp"]
files={}
for d in DIRS:
    for p in glob.glob(f"{LIB}/{d}/main/variable/ship_*.asm"):
        base=os.path.basename(p)[5:-4]  # strip 'ship_' and '.asm'
        if base not in files:
            files[base]=p
# normalize some names to our keys
# stats from newkind research: role, speed, energy, laser, missiles, bounty
STATS={
 "missile":("missile",44,2,0,0,0),
 "coriolis":("station",0,240,6,0,0),
 "escape_pod":("cargo",8,17,0,0,0),
 "alloy":("cargo",16,16,0,0,0),
 "cargo":("cargo",17,15,0,0,0),
 "canister":("cargo",17,15,0,0,0),
 "boulder":("rock",20,30,0,0,1),
 "asteroid":("rock",60,30,0,0,5),
 "splinter":("rock",20,10,0,0,0),
 "shuttle":("trader",32,8,0,0,0),
 "transporter":("trader",32,10,12,0,0),
 "cobra_mk_3":("trader",150,28,21,3,0),
 "python":("trader",250,20,0,3,0),
 "boa":("trader",250,24,0,4,0),
 "anaconda":("trader",252,14,12,7,0),
 "rock_hermit":("station",180,30,0,2,0),
 "viper":("police",140,32,0,1,0),
 "sidewinder":("pirate",70,37,0,0,50),
 "mamba":("pirate",90,30,0,2,150),
 "krait":("pirate",80,30,0,0,100),
 "adder":("pirate",85,24,0,0,40),
 "gecko":("pirate",70,30,0,0,55),
 "cobra_mk_1":("pirate",90,26,10,2,75),
 "worm":("pirate",30,23,0,0,0),
 "asp_mk_2":("pirate",150,40,8,1,200),
 "fer_de_lance":("pirate",160,30,0,2,0),
 "moray":("pirate",100,25,0,0,50),
 "thargoid":("thargoid",240,39,15,6,500),
 "thargon":("thargoid",20,30,0,0,50),
 "constrictor":("pirate",252,36,0,4,0),
 "cougar":("pirate",252,40,0,4,0),
 "dodo":("station",240,360,0,0,0),
}
def parse(path):
    verts=[]; edges=[]
    for line in open(path):
        s=line.split('\\')[0]
        m=re.match(r'\s*VERTEX\s+(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)',s)
        if m: verts.append(tuple(int(x) for x in m.groups()))
        m=re.match(r'\s*EDGE\s+(\d+)\s*,\s*(\d+)',s)
        if m: edges.append((int(m.group(1)),int(m.group(2))))
    return verts,edges
# map blueprint basename -> our short key
KEYMAP={"cobra_mk_3":"cobra","cobra_mk_1":"cobramk1","asp_mk_2":"asp","fer_de_lance":"ferdelance",
        "escape_pod":"escape","rock_hermit":"hermit"}
out=["-- Elite ship blueprints, extracted from the bbcelite source library",
     "-- (library/{common,enhanced,advanced}/main/variable/ship_*.asm).",
     "-- Vertices + edges in Elite's native coords (Y up, Z fwd, X right).",
     "-- Stats (role/speed/energy/laser/missiles/bounty) ported from newkind.",
     "-- GENERATED - do not hand-edit; rerun tools/gen_ships.py.","","Ships = {}",""]
roster=[]
for base in sorted(files):
    v,e=parse(files[base])
    if not v or not e: continue
    key=KEYMAP.get(base, base)
    r=max(1,int(math.ceil(max(math.sqrt(x*x+y*y+z*z) for x,y,z in v))))
    st=STATS.get(base,("pirate",80,20,0,0,30))
    role,sp,en,las,mis,bty=st
    vflat=", ".join(str(c) for vert in v for c in vert)
    eflat=", ".join(f"{a+1},{b+1}" for a,b in e)
    out.append(f"Ships.{key} = {{ r={r}, role=\"{role}\", speed={sp}, energy={en}, laser={las}, missiles={mis}, bounty={bty},")
    out.append(f"    verts = {{ {vflat} }},")
    out.append(f"    edges = {{ {eflat} }} }}")
    out.append("")
    roster.append((key,base,len(v),len(e),role,en,bty))
open("games/elite/ships.lua","w").write("\n".join(out))
print(f"wrote {len(roster)} ships")
for k,b,nv,ne,role,en,bty in roster:
    print(f"  {k:14s} {role:8s} v{nv:2d} e{ne:2d} en{en} bty{bty}")
