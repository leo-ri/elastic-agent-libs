$ErrorActionPreference = "Stop" # set -e
# Forcing to checkout again all the files with a correct autocrlf.
# Doing this here because we cannot set git clone options before.
function fixCRLF {
    Write-Host "-- Fixing CRLF in git checkout --"
    git config core.autocrlf input
    git rm --quiet --cached -r .
    git reset --quiet --hard
}

function withGolang($version) {
    Write-Host "-- Install golang --"
    choco install -y golang --version $version
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    refreshenv
    go version
    go env
}

function withGoJUnitReport {
    Write-Host "-- Install go-junit-report --"
    go install github.com/jstemmer/go-junit-report/v2@latest
}

Write-Host "--- Prepare enviroment"
fixCRLF
withGolang $env:GO_VERSION
withGoJUnitReport

Write-Host "--- Run test"
$ErrorActionPreference = "Continue" # set +e
mkdir -p build
$OUT_FILE="output-report.out"
go test "./..." -v > $OUT_FILE
$EXITCODE=$LASTEXITCODE
$ErrorActionPreference = "Stop"
Get-Content $OUT_FILE

Get-Content $OUT_FILE | go-junit-report > "uni-junit-win.xml"
Get-Content "uni-junit-win.xml" -Encoding Unicode | Set-Content -Encoding UTF8 "junit-win.xml"
Remove-Item "uni-junit-win", "$OUT_FILE"

Exit $EXITCODE
