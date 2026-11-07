# ЛР 13. Розрахунок IPv6-адрес за EUI-64 (варіант 3, G = 83, N = 3)
# MAC-адреси взято з Packet Tracer (show interfaces | include Hardware,
# show ipv6 neighbors, вкладка Config робочих станцій).
import ipaddress


def eui64_iid(mac: str) -> str:
    """MAC -> 64-бітний ідентифікатор інтерфейсу EUI-64 (з інверсією 7-го біта)."""
    h = mac.replace('.', '').replace('-', '').replace(':', '').lower()
    b = bytearray.fromhex(h)
    b[0] ^= 0x02                       # інвертуємо біт U/L (7-й біт першого байта)
    full = bytes(b[:3]) + b'\xff\xfe' + bytes(b[3:])
    return ':'.join(full[i:i + 2].hex() for i in range(0, 8, 2))


DEVICES = [
    # (пристрій, інтерфейс, MAC, мережа, глобальна адреса або None для EUI-64)
    ('R-83-3-1', 'Gig0/0', '000C.8545.4C01', 'A', '2001:83:3:A::1'),
    ('R-83-3-1', 'Gig0/1', '000C.8545.4C02', 'B', '2001:83:3:B::1'),
    ('R-83-3-1', 'Gig0/2', '000C.8545.4C03', 'D', '2001:83:3:D::1'),
    ('R-83-3-1', 'Gig0/0/0', '0002.1766.8A17', 'C', None),
    ('R-83-3-2', 'Gig0/0/0', '00D0.FF1B.E96B', 'C', None),
    ('SW-83-3-1', 'Vlan1', '00D0.BCE7.A321', 'A', '2001:83:3:A::2'),
    ('SW-83-3-2', 'Vlan1', '000D.BD6B.B9EC', 'B', '2001:83:3:B::2'),
    ('SW-83-3-3', 'Vlan1', '0001.42D1.25E4', 'D', '2001:83:3:D::2'),
    ('WS-A-1', 'Fa0', '000A.F337.D476', 'A', '2001:83:3:A::3'),
    ('WS-A-2', 'Fa0', '00D0.FF62.98D9', 'A', '2001:83:3:A::4'),
    ('WS-B-1', 'Fa0', '000A.F3C4.C69A', 'B', '2001:83:3:B::3'),
    ('WS-B-2', 'Fa0', '0001.42AC.1A1B', 'B', '2001:83:3:B::4'),
    ('R-83-3-3', 'Gig0/0', '0001.42E9.0401', 'D', '2001:83:3:D::3'),
    ('R-83-3-4', 'Gig0/0', '00D0.FFE7.0501', 'D', '2001:83:3:D::4'),
]

if __name__ == '__main__':
    for dev, ifc, mac, net, glob in DEVICES:
        iid = eui64_iid(mac)
        ll = str(ipaddress.IPv6Address('fe80::' + iid)).upper()
        g = glob or str(ipaddress.IPv6Address(f'2001:83:3:{net}:' + iid)).upper()
        print(f'{dev:10} {ifc:9} {mac}  LL {ll:28} GUA {g}')
    print('Мережа E (вручну): R-83-3-1 Se0/1/0 FE80::83:1, 2001:83:3:E::1;'
          ' R-83-3-5 Se0/0/0 FE80::83:5, 2001:83:3:E::5')
