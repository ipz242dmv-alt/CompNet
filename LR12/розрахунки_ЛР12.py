# Розрахунки до ЛР12 «Принципи організації IP-підмереж версії 4», варіант 3 (G = 83, N = 3)
# Запуск: python розрахунки_ЛР12.py
import ipaddress as ip


def bits(addr, cut=None):
    """32-розрядна двійкова сітка; '|' – межа між частиною мережі та частиною вузла."""
    s = format(int(ip.IPv4Address(addr)), '032b')
    out = ''
    for i, ch in enumerate(s, 1):
        out += ch
        if cut is not None and i == cut:
            out += '|'
        if i in (8, 16, 24):
            out += '.'
    return out


def mask(p):
    return str(ip.IPv4Network(f'0.0.0.0/{p}').netmask)


def nbits(x):
    return x.bit_length()


def cls_bits(addr):
    first = int(addr.split('.')[0])
    return 8 if first < 128 else 16 if first < 192 else 24


print('=== 1. 193.176.42.0, маска 255.255.255.248 ===')
N, P = cls_bits('193.176.42.0'), 29
S, H = P - N, 32 - P
print(f'N={N} P={P} S={S} H={H}  підмереж={2**S}  вузлів={2**H - 2}')
print(bits('193.176.42.0', P), bits('255.255.255.248', P))

print('\n=== 2. 114.0.0.0, 512 підмереж ===')
N = cls_bits('114.0.0.0'); Y = 512 - 1; S = nbits(Y); P = N + S; H = 32 - P
print(f'Y={Y}={Y:b}  S={S} P={P} маска={mask(P)} H={H} вузлів={2**H-2} усього={(2**H-2)*2**S}')

print('\n=== 3. 114.0.0.0, 133523 вузли ===')
X = 133523 + 2 - 1; H = nbits(X); P = 32 - H; S = P - N
print(f'X={X}={X:b}  H={H} S={S} P={P} маска={mask(P)} підмереж={2**S} вузлів={2**H-2} усього={2**S*(2**H-2)}')

print('\n=== 4. 80.0.0.0, CIDR 255.224.0.0, маска підмережі 255.255.0.0 ===')
C, P = 11, 16; S, H = P - C, 32 - P
print(f'C={C} P={P} S={S} H={H} підмереж={2**S} вузлів={2**H-2} усього={2**S*(2**H-2)}')

print('\n=== 5. 134.126.0.0, 3527 вузлів ===')
X = 3527 + 2 - 1; H = nbits(X); P = 32 - H
print(f'X={X}={X:b} H={H} P={P} маска={mask(P)}')
for i, s in enumerate(ip.IPv4Network('134.126.0.0/16').subnets(new_prefix=P)):
    print(f'{i:2} {s.network_address}  {s.network_address+1} – {s.broadcast_address-1}  bc {s.broadcast_address}  /{P}')

print('\n=== 6. >=22 підмережі, 1191 вузол (класова) ===')
print(f'Y=21={21:b} -> S>=5;  X=1192={1192:b} -> H={nbits(1192)}')
for N in (8, 16, 24):
    S = 32 - N - 11
    print(f'N={N}: S={S}', 'не підходить' if S < 5 else f'підмереж={2**S}')
for i, s in enumerate(ip.IPv4Network('150.83.0.0/16').subnets(new_prefix=21)):
    print(f'{i:2} {s}  {s.network_address+1} – {s.broadcast_address-1}  bc {s.broadcast_address}')

print('\n=== 7. >=8 підмереж, 1291 вузол (безкласова) ===')
S, H = nbits(7), nbits(1292); C = 32 - S - H
print(f'S={S} H={H} C={C} P={C+S}')
for i, s in enumerate(ip.IPv4Network('150.83.192.0/18').subnets(new_prefix=C + S)):
    print(f'{i} {s}  {s.network_address+1} – {s.broadcast_address-1}  bc {s.broadcast_address}')

print('\n=== 8. Агрегація ===')
nets = ['11.102.0.0/20', '11.102.32.0/20', '11.102.64.0/20', '11.102.80.0/20', '11.102.96.0/20']
for n in nets:
    print(bits(n.split('/')[0]))
ints = [int(ip.IPv4Network(n).network_address) for n in nets]
p = 0
while p < 32 and len({x >> (31 - p) for x in ints}) == 1:
    p += 1
agg = ip.IPv4Network((ints[0] >> (32 - p) << (32 - p), p))
print('Агрегована адреса:', agg, agg.netmask)

print('\n=== 9. Вузли A, B, C ===')
A, B, Cn = '124.60.104.34', '124.60.96.34', '124.60.120.34'
for p in range(16, 25):
    na, nb, nc = (ip.IPv4Network(f'{x}/{p}', strict=False) for x in (A, B, Cn))
    print(f'/{p}: A,B разом={na == nb}  C окремо={na != nc}')
