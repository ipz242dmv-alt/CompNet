# ЛР 15. Дослідження служби DNS та аналіз трафіку у Wireshark
# Варіант 3: домени knu.ua, mozilla.org, un.org; DNS 1 = 9.9.9.9 (Quad9), DNS 2 = 86.54.11.1 (DNS4EU, захищений);
# типи записів A, AAAA, SOA; фільтр захоплення "port 53 or port 853".
# Запуск: powershell -ExecutionPolicy Bypass -File "E:\univ\CompNet\LR15\команди_ЛР15.ps1"

$ErrorActionPreference = 'Continue'
$base   = Split-Path -Parent $MyInvocation.MyCommand.Path
$out    = Join-Path $base 'результати'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$domains = @('knu.ua', 'mozilla.org', 'un.org')
$dns1 = '9.9.9.9'; $dns2 = '86.54.11.1'
$utf8 = New-Object System.Text.UTF8Encoding($true)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Save($name, [scriptblock]$block) {
    Write-Host "=== $name ===" -ForegroundColor Cyan
    $text = (& $block 2>&1 | Out-String -Width 200)
    Write-Host $text
    [System.IO.File]::WriteAllText((Join-Path $out "$name.txt"), $text, $utf8)
}
function Cmd($line) { "PS> $line"; Invoke-Expression $line 2>&1 | Out-String -Width 200; '' }

# ---------------- Етап 1 (Wireshark: port 53 or port 853) ----------------
Save '01_параметри' {
    Cmd 'hostname'
    Cmd 'ipconfig /all'
    Cmd 'Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table -AutoSize'
    Cmd 'Get-DnsClientDohServerAddress | Format-Table -AutoSize'
    Cmd 'Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Format-List InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer'
}

Save '02_кеш' {
    $c = Get-DnsClientCache
    "Кількість записів у кеші до очищення: $($c.Count)"
    ''
    Cmd 'ipconfig /displaydns | Select-Object -First 60'
    Cmd 'Get-DnsClientCache | Select-Object Entry, RecordType, TimeToLive -First 20 | Format-Table -AutoSize'
    Cmd 'Clear-DnsClientCache'
    Cmd 'ipconfig /flushdns'
    "Кількість записів у кеші після очищення: $((Get-DnsClientCache).Count)"
}

Start-Sleep -Seconds 2
Save '03_розвязання' {
    foreach ($d in $domains) {
        Cmd "ping -4 -n 2 $d"
        Cmd "ping -6 -n 2 $d"
        foreach ($s in @($dns1, $dns2)) {
            Cmd "nslookup $d $s"
            foreach ($t in @('A', 'AAAA')) {
                $sw = [Diagnostics.Stopwatch]::StartNew()
                $r = Resolve-DnsName -Name $d -Type $t -Server $s -DnsOnly -NoHostsFile -ErrorAction SilentlyContinue
                $sw.Stop()
                "PS> Resolve-DnsName -Name $d -Type $t -Server $s   (час: $($sw.ElapsedMilliseconds) мс)"
                $r | Format-Table Name, Type, TTL, IPAddress, NameHost -AutoSize | Out-String -Width 200
            }
        }
    }
}

Save '04_записи' {
    foreach ($d in $domains) {
        foreach ($s in @($dns1, $dns2)) {
            "PS> nslookup (інтерактивно): server $s / set type=SOA / $d"
            ("server $s`nset type=SOA`n$d`nexit`n" | nslookup 2>&1 | Out-String -Width 200)
            foreach ($t in @('A', 'AAAA', 'SOA')) {
                "PS> Resolve-DnsName -Name $d -Type $t -Server $s"
                Resolve-DnsName -Name $d -Type $t -Server $s -DnsOnly -ErrorAction SilentlyContinue |
                    Format-List | Out-String -Width 200
            }
        }
    }
}

Save '05_порівняння' {
    foreach ($s in @($dns1, $dns2)) {
        foreach ($d in $domains) {
            $times = foreach ($i in 1..5) {
                $sw = [Diagnostics.Stopwatch]::StartNew()
                Resolve-DnsName -Name $d -Type A -Server $s -DnsOnly -QuickTimeout -ErrorAction SilentlyContinue | Out-Null
                $sw.Stop(); $sw.ElapsedMilliseconds
            }
            "$s  $d  час, мс: $($times -join ', ')  середній: $([math]::Round(($times | Measure-Object -Average).Average, 1))"
        }
        foreach ($d in $domains) {
            "PS> Resolve-DnsName -Name $d -Type A -Server $s -DnssecOk"
            Resolve-DnsName -Name $d -Type A -Server $s -DnssecOk -DnsOnly -ErrorAction SilentlyContinue |
                Format-Table Name, Type, TTL, Section, IPAddress, TypeCovered, Signer -AutoSize | Out-String -Width 200
        }
    }
    "PS> nslookup -debug un.org $dns1"
    (nslookup -debug un.org $dns1 2>&1 | Out-String -Width 200)
    "PS> nslookup -debug un.org $dns2"
    (nslookup -debug un.org $dns2 2>&1 | Out-String -Width 200)
    # запит до неіснуючого імені – відповідь з RCODE != 0 (для фільтра dns.flags.rcode != 0)
    "PS> Resolve-DnsName -Name lr15-nonexistent-83-3.knu.ua -Server $dns1"
    (Resolve-DnsName -Name 'lr15-nonexistent-83-3.knu.ua' -Server $dns1 -DnsOnly 2>&1 | Out-String -Width 200)
    "PS> Resolve-DnsName -Name lr15-nonexistent-83-3.knu.ua -Server $dns2"
    (Resolve-DnsName -Name 'lr15-nonexistent-83-3.knu.ua' -Server $dns2 -DnsOnly 2>&1 | Out-String -Width 200)
}

Save '10_PTR' {
    $ip = (Resolve-DnsName -Name 'mozilla.org' -Type A -Server $dns1 -DnsOnly -ErrorAction SilentlyContinue |
           Where-Object { $_.IPAddress } | Select-Object -First 1).IPAddress
    "Адреса для зворотного перетворення: $ip"
    Cmd "nslookup -type=PTR $ip $dns1"
    Cmd "Resolve-DnsName -Name $ip -Type PTR -Server $dns1"
    $ip2 = (Resolve-DnsName -Name 'un.org' -Type A -Server $dns1 -DnsOnly -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress } | Select-Object -First 1).IPAddress
    Cmd "Resolve-DnsName -Name $ip2 -Type PTR -Server $dns1"
}

Save '09a_DoT_853' {
    $ossl = 'C:\Program Files\Git\usr\bin\openssl.exe'
    if (Test-Path $ossl) {
        "PS> openssl s_client -connect 9.9.9.9:853 -servername dns.quad9.net -brief"
        ('Q' | & $ossl s_client -connect 9.9.9.9:853 -servername dns.quad9.net -brief 2>&1 | Out-String -Width 200)
    } else { 'openssl не знайдено – перевірку DoT (порт 853) не виконано' }
}

# сигнал для перемикання захоплення у Wireshark
Set-Content -Path (Join-Path $base '_phase1_done.flag') -Value (Get-Date)
Write-Host 'Етап 1 завершено. Очікування перемикання захоплення у Wireshark...' -ForegroundColor Yellow
$go = Join-Path $base '_go2.flag'
for ($i = 0; $i -lt 300 -and -not (Test-Path $go); $i++) { Start-Sleep -Seconds 2 }

# ---------------- Етап 2 (Wireshark: ICMP, mDNS/LLMNR, DoH) ----------------
Save '07_ping_локальний_зовнішній' {
    $gw = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4DefaultGateway.NextHop
    "Основний шлюз: $gw"
    Cmd "ping -n 3 $gw"
    Cmd 'ping -n 3 9.9.9.9'
    Cmd 'arp -a'
}

Save '08_mDNS_LLMNR' {
    Cmd 'Resolve-DnsName -Name lr15-test-83-3.local -ErrorAction SilentlyContinue'
    Cmd 'Resolve-DnsName -Name lr15host833 -LlmnrNetbiosOnly -ErrorAction SilentlyContinue'
    Cmd 'ping -n 1 lr15host833'
}

Save '09b_DoH' {
    "PS> curl.exe -s -o NUL -w ""HTTP %{http_code}, %{time_total} s"" --doh-url https://dns.quad9.net/dns-query https://www.mozilla.org/"
    (curl.exe -s -o NUL -w "HTTP %{http_code}, %{time_total} s" --doh-url https://dns.quad9.net/dns-query https://www.mozilla.org/ 2>&1 | Out-String)
    "PS> curl.exe -s -o NUL -w ""HTTP %{http_code}, %{time_total} s"" --doh-url https://dns.quad9.net/dns-query https://www.un.org/"
    (curl.exe -s -o NUL -w "HTTP %{http_code}, %{time_total} s" --doh-url https://dns.quad9.net/dns-query https://www.un.org/ 2>&1 | Out-String)
}

Remove-Item (Join-Path $base '_phase1_done.flag'), $go -ErrorAction SilentlyContinue
Set-Content -Path (Join-Path $base '_done.flag') -Value (Get-Date)
Write-Host 'Готово. Результати у папці результати.' -ForegroundColor Green
