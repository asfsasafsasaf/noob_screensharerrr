$dest    = 'C:\noob_screensharerrr'
$myRepo  = 'asfsasafsasaf/noob_screensharerrr'
$tag     = 'v1'
$threads = 8

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::DefaultConnectionLimit = 64

Write-Host "hehehhhh" -ForegroundColor White

$items = @(
    @{ f = 'systeminformer-build-canary-setup.exe'; s = '';          u = @('https://github.com/winsiderss/si-builds/releases/download/4.0.26255.346/systeminformer-build-canary-setup.exe') }
    @{ f = 'Everything-1.5.0.1423b.x64-Setup.exe';  s = '';          u = @('https://www.voidtools.com/Everything-1.5.0.1423b.x64-Setup.exe') }
    @{ f = 'shellbag_analyzer_cleaner.exe';         s = '';          u = @('https://privazer.com/ru/shellbag_analyzer_cleaner.exe') }
    @{ f = 'Bytecode-Viewer-2.13.2.jar';            s = '';          u = @('https://github.com/Konloch/bytecode-viewer/releases/download/v2.13.2/Bytecode-Viewer-2.13.2.jar') }
    @{ f = 'MeowClientFucker.exe';                  s = '';          u = @('https://github.com/MeowTonynoh/MeowClientFucker/releases/download/V1.1/MeowClientFucker.exe') }
    @{ f = 'PathsParser.exe';                       s = '';          u = @('https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe') }
    @{ f = 'RedLotusAltChecker.exe';                s = 'alts';      u = @('https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe') }
    @{ f = 'rss-altschecker.exe';                   s = 'alts';      u = @('https://github.com/Jumarf123/RSS-AltsChecker/releases/download/1.0.0/rss-altschecker.exe') }
    @{ f = 'product.zip';                           s = '';          u = @('https://github.com/Jumarf123/JliveF_Old/releases/download/4.2/product.zip') }
    @{ f = 'pv++.exe';                              s = '';          u = @('https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.8/pv++.exe') }
    @{ f = 'PowerShellParser++.exe';                s = 'detect.ac'; u = @('https://detect.ac/tool/PowerShellParser++') }
    @{ f = 'KernelLiveDump++.exe';                  s = 'detect.ac'; u = @('https://detect.ac/tool/KernelLiveDump++') }
    @{ f = 'JournalTrace++.exe';                    s = 'detect.ac'; u = @('https://detect.ac/tool/JournalTrace++') }
    @{ f = 'BamParser++.exe';                       s = 'detect.ac'; u = @('https://detect.ac/tool/BamParser++') }
    @{ f = 'AmcacheParser++.exe';                   s = 'detect.ac'; u = @('https://detect.ac/tool/AmcacheParser++') }
    @{ f = 'USBDeview++.exe';                       s = 'detect.ac'; u = @('https://detect.ac/tool/USBDeview++') }
    @{ f = 'BrowserDownloadsView++.exe';            s = 'detect.ac'; u = @('https://detect.ac/tool/BrowserDownloadsView++') }
    @{ f = 'CrashedFileViewer++.exe';               s = 'detect.ac'; u = @('https://detect.ac/tool/CrashedFileViewer++') }
    @{ f = 'windeflogview.zip';                     s = '';          u = @('https://www.nirsoft.net/utils/windeflogview.zip') }
    @{ f = 'MRCv120.exe';                           s = '';          u = @() }
)

$queue = @()
foreach ($it in $items) {
    $urls = @()
    foreach ($u in $it.u) { $urls += $u }
    if ($myRepo) { $urls += "https://github.com/$myRepo/releases/download/$tag/$($it.f)" }
    if ($urls.Count -eq 0) {
        Write-Host ("  [×] " + $it.f + " — нет ни одной ссылки (заполни `$myRepo)") -ForegroundColor Red
        continue
    }
    $dir = if ($it.s) { Join-Path $dest $it.s } else { $dest }
    $queue += ,@{ f = $it.f; out = (Join-Path $dir $it.f); urls = $urls }
}

try {
    New-Item -ItemType Directory -Path $dest -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Host "НЕ СОЗДАЛАСЬ ПАПКА: $dest" -ForegroundColor Red
    Write-Host "Запусти CMD от имени администратора." -ForegroundColor Red
    exit 1
}
foreach ($q in $queue) {
    New-Item -ItemType Directory -Path (Split-Path $q.out) -Force -EA SilentlyContinue | Out-Null
}
Get-ChildItem $dest -Recurse -Filter '*.part' -EA SilentlyContinue | Remove-Item -Force -EA SilentlyContinue

Write-Host "=== ЗАГРУЗКА -> $dest ===" -ForegroundColor Red

$todo = @()
$have = 0
foreach ($q in $queue) {
    if ((Test-Path $q.out) -and (Get-Item $q.out).Length -gt 0) {
        $have++
        Write-Host ("  уже есть: " + $q.f) -ForegroundColor DarkGray
    } else {
        $todo += $q
    }
}
if ($todo.Count -eq 0) {
    Write-Host "Всё уже на месте." -ForegroundColor Green
    Write-Host ""
    Write-Host ("ИТОГ: скачано {0} | уже было {1} | не скачалось {2} | всего {3}" -f 0, $have, 0, $queue.Count) -ForegroundColor Green
    Write-Host "Нажмите Enter, чтобы закрыть..." -ForegroundColor Gray
    [void](Read-Host)
    exit 0
}

$worker = {
    param($urls, $out, $fn, $myRepo, $log)
    Add-Type -AssemblyName System.Net.Http
    $tmp = $out + '.part'

    $srcOf = {
        param($u, $idx)
        if ($myRepo -and $u -like "https://github.com/$myRepo/*") { return 'моя копия' }
        if ($idx -eq 0) { return 'основной источник' }
        return 'запасной источник'
    }

    for ($i = 0; $i -lt $urls.Count; $i++) {
        $u   = $urls[$i]
        $src = & $srcOf $u $i
        $got = $false

        try {
            $h = New-Object System.Net.Http.HttpClient
            $h.Timeout = [TimeSpan]::FromSeconds(180)
            $r = $h.GetAsync($u, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
            if ($r.IsSuccessStatusCode) {
                $fs = [IO.File]::Create($tmp)
                try { $r.Content.CopyToAsync($fs).GetAwaiter().GetResult() }
                finally { $fs.Close(); $r.Dispose(); $h.Dispose() }
                if ((Get-Item $tmp).Length -gt 0) {
                    if (Test-Path $out) { [IO.File]::Delete($out) }
                    [IO.File]::Move($tmp, $out)
                    $got = $true
                } else {
                    [IO.File]::Delete($tmp)
                }
            } else {
                $code = [int]$r.StatusCode
                $r.Dispose(); $h.Dispose()
                $log.Enqueue("FAIL|$fn|не скачалось с источника: $src (HTTP $code)")
            }
        } catch {
            [IO.File]::Delete($tmp)
            $log.Enqueue("FAIL|$fn|не скачалось с источника: $src")
        }

        if ($got) { return }

        if ($i -lt $urls.Count - 1) {
            $nextSrc = & $srcOf $urls[$i + 1] ($i + 1)
            $log.Enqueue("NEXT|$fn|качаю напрямую: $nextSrc")
        }
    }
}

function Read-WorkerLog {
    param($log)
    $m = $null
    while ($log.TryDequeue([ref]$m)) {
        $p = $m.Split('|')
        if ($p[0] -eq 'FAIL') {
            Write-Host ("  [×] {0} — {1}" -f $p[1], $p[2]) -ForegroundColor Red
        } elseif ($p[0] -eq 'NEXT') {
            Write-Host ("  [→] {0} — {1}" -f $p[1], $p[2]) -ForegroundColor Yellow
        }
    }
}

$pool = [runspacefactory]::CreateRunspacePool(1, [Math]::Min($threads, $todo.Count))
$pool.Open()
$log = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$jobs = @()
$n = 0
foreach ($q in $todo) {
    $n++
    Write-Host ("  [{0}/{1}] качаю: {2}" -f $n, $todo.Count, $q.f) -ForegroundColor Yellow
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($worker).AddArgument($q.urls).AddArgument($q.out).AddArgument($q.f).AddArgument($myRepo).AddArgument($log)
    $jobs += [pscustomobject]@{ ps = $ps; h = $ps.BeginInvoke(); f = $q.f; out = $q.out; done = $false }
}

$pending = $jobs.Count
$ok = 0
$bad = 0
while ($pending -gt 0) {
    Read-WorkerLog $log
    foreach ($j in $jobs) {
        if (-not $j.done -and $j.h.IsCompleted) {
            $j.done = $true
            $pending--
            try { $j.ps.EndInvoke($j.h) | Out-Null } catch {}
            $j.ps.Dispose()
            if ((Test-Path $j.out) -and (Get-Item $j.out).Length -gt 0) {
                $ok++
                $mb = [math]::Round((Get-Item $j.out).Length / 1MB, 1)
                Write-Host ("  [OK]   {0} ({1} MB)" -f $j.f, $mb) -ForegroundColor Green
            } else {
                $bad++
                if (Test-Path $j.out) { Remove-Item $j.out -Force -EA SilentlyContinue }
                Write-Host ("  [FAIL] {0}" -f $j.f) -ForegroundColor Red
            }
        }
    }
    if ($pending -gt 0) { Start-Sleep -Milliseconds 150 }
}
Read-WorkerLog $log
$pool.Close()

Write-Host ""
$sumColor = if ($bad -gt 0) { 'Red' } else { 'Green' }
Write-Host ("ИТОГ: скачано {0} | уже было {1} | не скачалось {2} | всего {3}" -f $ok, $have, $bad, $queue.Count) -ForegroundColor $sumColor
if ($bad -gt 0) {
    Write-Host "Часть файлов не скачалась — проверь интернет или зеркала." -ForegroundColor Red
}
Write-Host "Нажмите Enter, чтобы закрыть..." -ForegroundColor Gray
[void](Read-Host)
if ($bad -gt 0) { exit 1 }
exit 0
