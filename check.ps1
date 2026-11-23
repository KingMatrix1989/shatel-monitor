# Checks Shatel Mobile internet remaining; toasts if below threshold or if the call fails.
# Kept ASCII-only on purpose: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
param([int]$ThresholdMB = 500, [switch]$SelfTest)

function Toast($title, $body) {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $t = $xml.GetElementsByTagName('text')
    $t.Item(0).AppendChild($xml.CreateTextNode($title)) > $null
    $t.Item(1).AppendChild($xml.CreateTextNode($body)) > $null
    $app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
}
function Emoji([int]$cp) { [char]::ConvertFromUtf32($cp) }

$GB = -join [char[]](0x6AF, 0x6CC, 0x6AF)        # "gig" in Persian
$KB = -join [char[]](0x6A9, 0x6CC, 0x644, 0x648) # "kilo" in Persian

# "10,240 MB" / "1.5 GB" / "300 KB" (units in Persian) -> MB
function ToMB([string]$s) {
    $n = [double]($s -replace '[^\d.]', '')
    if ($s.Contains($GB)) { return $n * 1024 }
    if ($s.Contains($KB)) { return $n / 1024 }
    $n
}

if ($SelfTest) {
    $MBu = -join [char[]](0x645, 0x6AF, 0x627, 0x628, 0x627, 0x6CC, 0x62A)
    if ((ToMB "10,240 $MBu") -ne 10240) { throw 'MB parse' }
    if ((ToMB "1.5 $GB$($MBu.Substring(2))") -ne 1536) { throw 'GB parse' }
    if ((ToMB "512 $KB$($MBu.Substring(2))") -ne 0.5) { throw 'KB parse' }
    'self-test ok'; exit 0
}

$dir = $PSScriptRoot
$session = (Get-Content "$dir\session.txt" -Raw).Trim()
$msisdn = (Get-Content "$dir\msisdn.txt" -Raw).Trim()
$out = "$env:TEMP\shatel-remained.json"
$body = "$env:TEMP\shatel-body.json"   # body via file: PS 5.1 strips inner quotes from native args
[IO.File]::WriteAllText($body, "{`"msisdn`":`"$msisdn`"}")
$code = & curl.exe -s --noproxy '*' --max-time 60 -X POST https://my.shatelmobile.ir/remained `
    -H 'X-Requested-With: XMLHttpRequest' -H 'Content-Type: application/json' `
    -H "Cookie: session=$session" --data-binary "@$body" -o $out -w '%{http_code}'

try { if ($code -ne '200') { throw "HTTP $code" }; $data = Get-Content $out -Raw -Encoding UTF8 | ConvertFrom-Json }
catch {
    $hint = if ($code -eq '000') { 'no connection to the server' } else { "session may have expired; update $dir\session.txt" }
    Toast "$(Emoji 0x274C) Shatel check failed" "$_ - $hint"
    "$(Get-Date -f s) FAIL $_" | Add-Content "$dir\log.txt"
    exit 1
}

$mb = 0; foreach ($p in $data.internet_packages) { $mb += ToMB $p.remained }
$mb = [math]::Round($mb)
"$(Get-Date -f s) OK $mb MB" | Add-Content "$dir\log.txt"
if ($mb -lt $ThresholdMB) { Toast "$(Emoji 0x1F6A8) Shatel internet low" "$mb MB left (below $ThresholdMB MB)" }
