# Deployt die Spotpreis-PWA als öffentliches GitHub-Repo + GitHub Pages.
# Aufruf (im Ordner spotpreis-pwa):   powershell -ExecutionPolicy Bypass -File .\deploy.ps1
param(
    [string]$Owner = "ClaudeFummel",
    [string]$Repo  = "spotpreis-at"
)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
function Fail($msg) { Write-Host "FEHLER: $msg" -ForegroundColor Red; exit 1 }

# Firmen-Token nur für diesen Prozess ausblenden; eigener gh-Login-Speicher, bestehende Logins bleiben unberührt
Remove-Item Env:GH_TOKEN, Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
$env:GH_CONFIG_DIR = Join-Path $env:LOCALAPPDATA "spotpreis-gh"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    $gh = Get-ChildItem "$env:LOCALAPPDATA\copilot-desktop-gh-*\gh.exe", "$env:ProgramFiles\GitHub CLI\gh.exe" -ErrorAction SilentlyContinue |
          Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $gh) { Fail "GitHub CLI (gh) nicht gefunden. Installieren: winget install GitHub.cli" }
    $env:PATH = "$($gh.DirectoryName);$env:PATH"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "git nicht gefunden." }

$login = (gh api user --jq .login 2>$null)
if ($login -ne $Owner) {
    Write-Host "`nBitte als '$Owner' bei GitHub anmelden. Code unten kopieren, Enter druecken, im Browser einloggen.`n" -ForegroundColor Yellow
    gh auth login --hostname github.com --git-protocol https --web --scopes "repo,workflow"
    $login = (gh api user --jq .login 2>$null)
    if ($login -ne $Owner) { Fail "Angemeldet als '$login', erwartet '$Owner'." }
}
Write-Host "Angemeldet als $login" -ForegroundColor Green
$id = gh api user --jq .id

# git nutzt gh als Credential-Helper - nur für diese Aufrufe, nicht global
function G { git -c credential.helper= -c "credential.helper=!gh auth git-credential" @args }

if (-not (Test-Path .git)) { G init -b main | Out-Null }
G config user.name  $Owner
G config user.email "$id+$Owner@users.noreply.github.com"
G add -A
G commit -q -m "Spotpreis AT PWA" 2>&1 | Out-Null

gh repo view "$Owner/$Repo" --json name 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Lege Repo $Owner/$Repo an..." -ForegroundColor Cyan
    gh repo create "$Owner/$Repo" --public --description "Spotpreis Oesterreich - EPEX 15-min Day-Ahead (PWA)"
    if ($LASTEXITCODE -ne 0) { Fail "Repo konnte nicht angelegt werden." }
}
G remote remove origin 2>&1 | Out-Null
G remote add origin "https://github.com/$Owner/$Repo.git"
G push -u origin main 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) { Fail "Push fehlgeschlagen." }

Write-Host "Aktiviere GitHub Pages..." -ForegroundColor Cyan
gh api -X POST "repos/$Owner/$Repo/pages" -f build_type=workflow 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { gh api -X PUT "repos/$Owner/$Repo/pages" -f build_type=workflow 2>&1 | Out-Null }

# Der Push-Lauf scheitert evtl., weil Pages da noch nicht aktiv war -> frisch starten
Start-Sleep 5
gh workflow run pages.yml -R "$Owner/$Repo"
Write-Host "Warte auf Deploy (1-2 Minuten)..." -ForegroundColor Cyan
Start-Sleep 10
$run = gh run list -R "$Owner/$Repo" --workflow pages.yml --event workflow_dispatch --limit 1 --json databaseId --jq ".[0].databaseId"
gh run watch $run -R "$Owner/$Repo" --exit-status
if ($LASTEXITCODE -ne 0) { Fail "Deploy fehlgeschlagen - siehe https://github.com/$Owner/$Repo/actions" }

$url = "https://$($Owner.ToLower()).github.io/$Repo/"
Write-Host "`nFertig! App-URL: $url" -ForegroundColor Green
Write-Host "Auf dem iPhone in Safari oeffnen -> Teilen -> 'Zum Home-Bildschirm'."
