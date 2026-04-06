import os
import subprocess

FILES = [f for f in os.listdir(".") if f.endswith(".v")]

def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.stdout + p.stderr

for f in FILES:
    print(f"\n>>> ANALİZ EDİLİYOR: {f} <<<")
    
    # -q parametresini kaldırdık!
    yosys_out = run([
        "yosys",
        "-p",
        f"read_verilog {f}; hierarchy -check; stat;"
    ])
    
    # Eğer Verilog kodunda bir syntax hatası varsa direkt onu yazdır
    if "ERROR:" in yosys_out:
        print("  [!] Yosys Sentez Hatası: Kodunda bir sorun var.")
        for line in yosys_out.splitlines():
            if "ERROR:" in line:
                print("  ->", line.strip())
        print("-" * 40)
        continue
    
    relevant_keywords = [
        "wires", "cells", "submodules", "public wires", 
        "ports", "bits", "number of cells", "number of wires", "$"
    ]
    
    lines = yosys_out.splitlines()
    for line in lines:
        # Satırda '===' varsa veya belirlediğimiz kelimelerden biri varsa
        if "===" in line or any(kw in line.lower() for kw in relevant_keywords):
            # Yosys'in tablo çizgilerini ve gereksiz metinleri eleyelim
            if "+---" not in line and "|" not in line and "local count" not in line.lower() and "yosys" not in line.lower():
                print(line.strip())
                
    print("-" * 40)