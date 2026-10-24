exec(open('data.py').read().replace('print(','(lambda *a:None)('))
# canonical rows: display name (2027 name if present else latest), {year: name}
groups = [
 ("/dev/random", {2027:"/dev/random",2026:"/dev/random",2025:"Lightning Talks",2024:"Lightning talks"}, "15-min talks; was “Lightning talks” until 2025"),
 ("AI Plumbers/Local-First AI", {2027:"AI Plumbers/Local-First AI",2026:"AI Plumbers",2025:"Low-level AI Engineering and Hacking"}, ""),
 ("Audio, Video, Graphics and Podcast", {2027:"Audio, Video, Graphics and Podcast",2026:"Audio, Video & Graphics Creation"}, ""),
 ("BSD, illumos, bhyve, OpenZFS", {2027:"BSD, illumos, bhyve, OpenZFS",2026:"BSD, illumos, bhyve, OpenZFS",2025:"BSD"}, ""),
 ("Collaboration and content management", {y:n for y,n in [(2027,"Collaboration and content management"),(2026,"Collaboration and content management"),(2025,"Collaboration and Content Management"),(2024,"Collaboration and Content Management")]}, ""),
 ("Decentralised Messaging", {2027:"Decentralised Messaging",2026:"Decentralised Communication"}, "cf. Matrix, RTC (2024–25)"),
 ("Educational", {2027:"Educational",2026:"Educational",2025:"Educational",2024:"FOSS Educational Programming Languages"}, ""),
 ("Emulator Development", {2027:"Emulator Development",2024:"Emulator"}, ""),
 ("FOSS on Mobile", {2027:"FOSS on Mobile",2026:"FOSS on Mobile",2025:"FOSS on Mobile Devices",2024:"FOSS on Mobile Devices"}, ""),
 ("GCC (GNU Toolchain)", {2027:"GCC (GNU Toolchain)",2026:"GCC (GNU Toolchain)",2025:"GCC (GNU Toolchain)",2024:"GCC"}, ""),
 ("Graphics", {2027:"Graphics DevRoom",2026:"Graphics",2024:"Graphics"}, ""),
 ("HPC, Big Data, and Data Science", {2027:"HPC, Big Data, and Data Science",2026:"HPC, Big Data & Data Science",2025:"HPC, Big Data & Data Science",2024:"HPC, Big Data & Data Science"}, ""),
 ("Identity and Access Management", {2027:"Identity and Access Management Devroom",2026:"Identity and Access Management",2025:"Identity and Access Management",2024:"Identity and Access Management"}, ""),
 ("Legal & Policy", {2027:"Legal & Policy",2026:"Legal & Policy",2025:"Legal and Policy",2024:"Legal and Policy Issues"}, ""),
 ("Local-First, Sync engines, CRDTs", {2027:"Local-First, Sync engines, CRDTs",2026:"Local-First, sync engines, CRDTs"}, ""),
 ("Microkernel and Component-based OS", {2027:"Microkernel and Component-based OS",2026:"Microkernel and Component-Based OS",2025:"Microkernel and Component-Based OS",2024:"Microkernel and Component-based OS"}, ""),
 ("Monitoring and Observability", {2027:"Monitoring and Observability",2025:"Monitoring and Observability",2024:"Monitoring & Observability"}, ""),
 ("Network", {2027:"Network Devroom",2026:"Network",2025:"Network",2024:"Network"}, ""),
 ("Nix and NixOS", {2027:"Nix and NixOS Devroom",2026:"Nix and NixOS",2025:"Nix and NixOS",2024:"Nix and NixOS"}, ""),
 ("Open Media", {2027:"Open Media",2026:"Open Media devroom",2025:"Open Media",2024:"Open Media"}, ""),
 ("Open Source & EU Policy", {2027:"Open Source & EU Policy Devroom",2026:"Open Source & EU Policy",2025:"Open Source In The European Legislative Landscape and Beyond",2024:"Open Source In The European Legislative Landscape"}, ""),
 ("Open Source Design & Open User Research", {2027:"Open Source Design & Open User Research",2026:"Open Source Design",2025:"Open Source Design",2024:"Open Source Design"}, ""),
 ("Perl & Raku", {2027:"Perl & Raku",2024:"Perl and Raku"}, ""),
 ("Python", {2026:"Python",2025:"Python",2024:"Python Devroom"}, ""),
 ("RF Digital Signal Processing", {2027:"Radio-Frequency Digital Signal Processing (RF DSP)",2026:"Software Defined Radio(SDR)/Digital Signal Processing(DSP)",2025:"Radio",2024:"Software-Defined Radio and Amateur Radio"}, "Amateur Radio split into its own room in 2027"),
 ("Security", {2027:"Security Devroom",2026:"Security",2025:"Security"}, ""),
 ("Social Web", {2027:"Social Web Devroom",2026:"Social Web",2025:"Social Web"}, ""),
 ("Testing and Continuous Delivery", {2027:"Testing and Continuous Delivery",2026:"Testing and Continuous Delivery",2025:"Testing and Continuous Delivery",2024:"Testing and Continuous delivery"}, ""),
 ("Tool the Docs", {2027:"Tool the Docs",2026:"Tool the Docs",2025:"Tool the Docs",2024:"Tool the docs"}, ""),
 ("Databases", {2026:"Databases",2025:"Cloud Native Databases"}, "cf. PostgreSQL (2027)"),
 ("Energy", {2026:"Energy",2025:"Energy: Accelerating the Transition through Open Source",2024:"Energy: Reimagining this Ecosystem through Open Source"}, "cf. Green & Ethical Tech (2027)"),
 ("FPGA and VLSI", {2026:"FPGA and VLSI",2024:"Libre-SOC, FPGA and VLSI"}, ""),
 ("SBOMs and supply chains", {2026:"SBOMS and supply chains",2025:"Software Bill of Materials (SBOM)",2024:"Software Bill of Materials"}, ""),
 ("APIs & friends", {2025:"APIs: GraphQL, OpenAPI, AsyncAPI, and friends",2024:"APIs & friends"}, ""),
 ("Matrix", {2025:"Matrix.org Foundation and Community",2024:"Matrix"}, ""),
]
notes_extra = {
 "Beyond the CRA - Building Secure and Resilient Open Source":"cf. CRA in practice (2026)",
 "CRA in practice":"cf. Beyond the CRA (2027)",
 "Amateur Radio Devroom":"split from the SDR/radio room",
 "FOSS Office":"cf. LibreOffice (2025)",
 "LibreOffice":"cf. FOSS Office (2027)",
 "Accessibility":"cf. Inclusive Web (2025)",
 "Green & Ethical Tech":"cf. Energy (2024–26)",
 "PostgreSQL":"cf. Databases (2026)",
 "Python":"absent in 2027",
}
years={2027:y27,2026:y26,2025:y25,2024:y24}
used={y:set() for y in years}
rows=[]
for name,m,note in groups:
    for y,n in m.items():
        assert n in years[y], (y,n); assert n not in used[y],(y,n); used[y].add(n)
    rows.append([name,m,note])
# exact same-name matches for the rest (case-insensitive)
rest={}
for y,l in years.items():
    for n in l:
        if n in used[y]: continue
        k=n.lower().replace(" devroom","")
        rest.setdefault(k,[None,{},""])
        if rest[k][0] is None or y==2027: rest[k][0]=n
        assert y not in rest[k][1]; rest[k][1][y]=n
for k,r in rest.items(): rows.append(r)
for r in rows:
    if not r[2]: r[2]=notes_extra.get(r[0],"")
def status(m):
    if 2027 in m:
        if 2026 in m: return "confirmed"
        if 2025 in m or 2024 in m: return "back"
        return "new"
    return "gone"
import json,collections
out=[]
for name,m,note in rows:
    alias=sorted({v for v in m.values() if v.lower().replace(' devroom','')!=name.lower().replace(' devroom','')})
    out.append(dict(name=name.replace(" Devroom","").replace(" DevRoom",""),y=sorted(m),s=status(m),note=note,aka=alias))
out.sort(key=lambda r:r['name'].lower().lstrip('/'))
c=collections.Counter(r['s'] for r in out); print(c, len(out))
for s in ["new","back","gone"]:
    print(s, [r['name'] for r in out if r['s']==s])
# integrity: each year count
for y in years: print(y, sum(y in r['y'] for r in out), len(years[y]))
json.dump(out,open('rows.json','w'),ensure_ascii=False)
