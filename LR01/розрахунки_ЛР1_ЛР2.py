import ipaddress, math
def b(ip): return '.'.join(f'{int(o):08b}' for o in str(ip).split('.'))
def info(addr, prefix):
    net=ipaddress.ip_network(f'{addr}/{prefix}',strict=False)
    a=ipaddress.ip_address(addr); m=net.netmask; inv=net.hostmask
    host=ipaddress.ip_address(int(a)&int(inv))
    return dict(addr=str(a),prefix=prefix,mask=str(m),inv=str(inv),net=str(net.network_address),host=str(host),
        first=str(net.network_address+1) if prefix<31 else '-',last=str(net.broadcast_address-1) if prefix<31 else '-',
        bc=str(net.broadcast_address),hosts=2**(32-prefix)-2,
        bin_addr=b(a),bin_mask=b(m),bin_inv=b(inv),bin_net=b(net.network_address),bin_host=b(host),
        bin_first=b(net.network_address+1),bin_last=b(net.broadcast_address-1),bin_bc=b(net.broadcast_address))
def cls(ip):
    f=int(ip.split('.')[0]); return 'A' if f<128 else 'B' if f<192 else 'C' if f<224 else 'D/E'
print('LR1 MAC')
for m in ['FFFFFFFFFFFF','4C80937895AA','0180C2000003']:
    fb=int(m[:2],16); print(m, f'{fb:08b}', 'I/G=',fb&1,'U/L=',(fb>>1)&1)
print('LR1 IP classful')
for ip in ['208.74.183.175','138.68.177.181','65.65.55.66']:
    c=cls(ip); p={'A':8,'B':16,'C':24}[c]; d=info(ip,p); print(c,{k:v for k,v in d.items() if not k.startswith('bin')})
for n in [78,2047]:
    X=n+1
    c='C' if n<=254 else 'B' if n<=65534 else 'A'; p={'A':8,'B':16,'C':24}[c]; K=2**(32-p)-2
    print(n,'X',X,c,p,K,f'{n/K*100:.2f}% used, free {K-n}')
print('LR2')
for ip,p in [('30.255.255.1',27),('208.74.183.175',14)]:
    d=info(ip,p); print(d)
for n in [126,20471]:
    X=n+1; H=X.bit_length(); P=32-H; K=2**H-2
    print(n,'X',X,bin(X),'H',H,'P',P,'mask',ipaddress.ip_network(f'0.0.0.0/{P}').netmask,'K',K,f'used {n/K*100:.2f}% free {(K-n)/K*100:.2f}% freeN {K-n}')
