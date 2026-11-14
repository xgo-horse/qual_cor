# Gera assets/data/citadel_paints.json (lista do easter egg) a partir de
# Arcturus5404/miniature-paints e piemasters/MiniToTheMax (MIT).
# Uso: baixe paints/Citadel_Colour.md como DIR/citadel.md e
# src/data/paints/citadel/{base,layer,shade,contrast,dry,technical}.ts como
# DIR/mt_<linha>.ts; depois: python3 tool/build_citadel.py DIR OUTDIR
# e copie OUTDIR/citadel_easter_egg.json para assets/data/citadel_paints.json.
import re, json, csv, math, sys, glob, os
D=sys.argv[1]; OUT=sys.argv[2]
def oklch(h):
    r,g,b=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    lin=lambda c: c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4
    r,g,b=map(lin,(r,g,b))
    l=0.4122214708*r+0.5363325363*g+0.0514459929*b
    m=0.2119034982*r+0.6806995451*g+0.1073969566*b
    s=0.0883024619*r+0.2817188376*g+0.6299787005*b
    l,m,s=[math.copysign(abs(x)**(1/3),x) for x in (l,m,s)]
    L=0.2104542553*l+0.7936177850*m-0.0040720468*s
    A=1.9779984951*l-2.4285922050*m+0.4505937099*s
    B=0.0259040371*l+0.7827717662*m-0.8086757660*s
    C=math.hypot(A,B); H=math.degrees(math.atan2(B,A))%360
    return round(L,4),round(C,4),round(H,1) if C>1e-4 else 0.0
def norm(n): return re.sub(r"[^a-z0-9]","",n.lower().replace("’","'"))
rows={}
for line in open(f"{D}/citadel.md"):
    p=line.strip().split("|")
    if len(p)<7 or p[1] in("Name","---"): continue
    name,rng=p[1].strip(),p[2].strip()
    hx=re.search(r"`(#[0-9A-Fa-f]{6})`",line).group(1).upper()
    disc="discontinued" in rng
    rng=rng.replace(" (discontinued)","")
    rows[(norm(name),rng)]=dict(name=name,range=rng,hex=hex if False else hx,discontinued=disc,source="arcturus")
mtmap={"base":"Base","layer":"Layer","shade":"Shade","contrast":"Contrast","dry":"Dry","technical":"Technical"}
added=0; diffs=[]; metal=set()
for f,rng in mtmap.items():
    t=open(f"{D}/mt_{f}.ts").read()
    for blk in re.findall(r"\{(.*?)\n\};",t,re.S):
        n=re.search(r"name: '((?:[^'\\]|\\.)*)'|name: \"([^\"]*)\"",blk); n=(n.group(1) or n.group(2)).replace("\\'","'")
        h=re.search(r"hex: '(#[0-9A-Fa-f]{6})'",blk)
        if not h: continue
        h=h.group(1).upper(); disc="discontinued" in blk
        k=(norm(n),rng)
        if 'metallic' in blk: metal.add(norm(n))
        if k in rows:
            rows[k]["hex_alt"]=h
        else:
            rows[k]=dict(name=n,range=rng,hex=h,discontinued=disc,source="minitothemax"); added+=1
out=[]
for r in rows.values():
    if r["range"].startswith("Foundation"): continue  # linha 2010-2012, descontinuada
    r["metallic"]=("drab" not in r["name"].lower()) and (norm(r["name"]) in metal or any(w in r["name"].lower() for w in ("gold","silver","steel","bronze","brass","copper","leadbelcher","iron warriors","ironbreaker","alloy","armour gold","sigmarite","necron compound","retributor","screaming bell","warplock","gunmetal","runelord")))
    L,C,H=oklch(r["hex"])
    r.update(oklch_l=L,oklch_c=C,oklch_h=H)
    out.append(r)
order=["Base","Layer","Shade","Contrast","Dry","Technical","Glaze","Air","Spray"]
out.sort(key=lambda r:(order.index(r["range"]) if r["range"] in order else 99,r["name"].lower()))
# disagreement stats
def dE(a,b):
    import itertools
    la=oklch(a);lb=oklch(b)
    ax=(la[0],la[1]*math.cos(math.radians(la[2])),la[1]*math.sin(math.radians(la[2])))
    bx=(lb[0],lb[1]*math.cos(math.radians(lb[2])),lb[1]*math.sin(math.radians(lb[2])))
    return math.dist(ax,bx)
for r in out:
    if "hex_alt" in r:
        r["sources_delta_e_ok"]=round(dE(r["hex"],r["hex_alt"]),3)
        if r["hex_alt"]==r["hex"]: del r["hex_alt"]
# easter-egg list: one per name
pref={k:i for i,k in enumerate(["Base","Layer","Shade","Contrast","Dry","Technical","Glaze","Spray","Air"])}
egg={}
for r in out:
    if r["discontinued"] or r["range"] in ("Technical",): continue
    k=norm(r["name"])
    if k not in egg or pref[r["range"]]<pref[egg[k]["range"]]: egg[k]=r
egg=sorted(egg.values(),key=lambda r:r["name"].lower())
meta={"description":"Citadel Colour (Games Workshop) - mapa aproximado de cores. Valores hex sao aproximacoes da comunidade, NAO oficiais (GW nao publica hex). Shade/Contrast representam a cor aplicada sobre primer branco/claro.",
 "sources":["https://github.com/Arcturus5404/miniature-paints (MIT) - fonte primaria","https://github.com/piemasters/MiniToTheMax (MIT) - complemento (Contrast/Shade novas) e hex_alt"],
 "generated":"2026-11-13","oklch":"calculado a partir do hex (sRGB D65, Ottosson 2020); L 0-1, C ~0-0.37, H graus",
 "trademark":"Citadel e os nomes das tintas sao marcas da Games Workshop; uso apenas referencial."}
json.dump(dict(meta=meta,paints=out),open(f"{OUT}/citadel_paints.json","w"),ensure_ascii=False,indent=1)
def eggrow(r):
    h=r.get("hex_alt") if r["range"]=="Shade" and r.get("hex_alt") else r["hex"]
    L,C,H=oklch(h)
    return dict(name=r["name"],range=r["range"],hex=h,oklch_l=L,oklch_c=C,oklch_h=H,metallic=r["metallic"])
egg=[r for r in egg if not r["metallic"]]
json.dump(dict(meta=dict(meta,egg_notes="1 entrada por nome (prefere Base>Layer>Shade>Contrast>Dry>Glaze>Spray>Air); sem descontinuadas, Technical e metalicas; Shade usa a cor do pote (escura) quando disponivel."),paints=[eggrow(r) for r in egg]),open(f"{OUT}/citadel_easter_egg.json","w"),ensure_ascii=False,indent=1)
cols=["name","range","hex","metallic","oklch_l","oklch_c","oklch_h","discontinued","source","hex_alt","sources_delta_e_ok"]
w=csv.DictWriter(open(f"{OUT}/citadel_paints.csv","w",newline=""),fieldnames=cols); w.writeheader()
for r in out: w.writerow({c:r.get(c,"") for c in cols})
from collections import Counter
print("total",len(out),"egg",len(egg),"added",added,Counter(r["range"] for r in out))
ds=[r for r in out if r.get("sources_delta_e_ok",0)>0.08]
print("big disagreements",len(ds)); [print(r["name"],r["range"],r["hex"],r.get("hex_alt"),r["sources_delta_e_ok"]) for r in sorted(ds,key=lambda r:-r["sources_delta_e_ok"])[:15]]
