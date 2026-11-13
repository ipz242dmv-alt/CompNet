# ЛР 14. Розрахунок схеми адресації (варіант 3, G = 83, N = 3)
# Табл. 6: мережа A – 13 станцій, 2 сервери, 2 принтери, 3 комутатори, 1 точка доступу;
#          мережа B – 50 станцій, 2 сервери, 5 принтерів, 3 комутатори, 2 точки доступу.
# Табл. 7 (рядок 3): A – 193.G.N.0, B – 194.G.N.0, C – 195.G.N.N/30.
import ipaddress
import math

NETS = {
    'A': dict(base='193.83.3.0', dyn=13, static={'R-83-3-1': 1, 'комутатори': 3, 'точки доступу': 1,
                                                  'сервери': 2, 'принтери': 2}),
    'B': dict(base='194.83.3.0', dyn=50, static={'R-83-3-1': 1, 'комутатори': 3, 'точки доступу': 2,
                                                  'сервери': 2, 'принтери': 5}),
    'C': dict(base='195.83.3.0', dyn=1, static={'R-83-3-1': 1}),
}

for name, d in NETS.items():
    need = d['dyn'] + sum(d['static'].values())
    h = max(2, math.ceil(math.log2(need + 2)))
    net = ipaddress.ip_network(f"{d['base']}/{32 - h}")
    print(f'Мережа {name}: потрібно {need} адрес ({d["dyn"]} динамічних + '
          f'{sum(d["static"].values())} статичних) -> H = {h}, {net} '
          f'(маска {net.netmask}, {net.num_addresses - 2} адрес вузлів)')
    hosts = list(net.hosts())
    print(f'   діапазон вузлів {hosts[0]} – {hosts[-1]}, широкомовна {net.broadcast_address}')
    dyn = hosts[1:1 + d['dyn']]
    print(f'   динамічні: {dyn[0]} – {dyn[-1]}')
