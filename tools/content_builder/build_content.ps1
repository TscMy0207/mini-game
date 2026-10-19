param(
    [Alias("Godot")]
    [string]$GodotExecutable = "godot",
    [string]$Project = (Join-Path $PSScriptRoot "../.."),
    [string]$Output = (Join-Path $PSScriptRoot "../../../mini-game-artifacts/cdn")
)

$ErrorActionPreference = "Stop"
# 构建产物放到 CDN 目录；内容包仅包含业务模块和内容清单。
$Project = [System.IO.Path]::GetFullPath($Project)
$Output = [System.IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Force -Path $Output | Out-Null
$packPath = Join-Path $Output "content.pck"
if (-not (Test-Path (Join-Path $Project "export_presets.cfg"))) {
    throw "Missing export_presets.cfg at $Project"
}
& $GodotExecutable --headless --path $Project --export-pack "ContentPack" $packPath
if ($LASTEXITCODE -ne 0) { throw "Godot pack export failed: $LASTEXITCODE" }
python (Join-Path $PSScriptRoot "build_manifest.py") $Output --version "0.2.0" --framework-version "0.2.0" --output (Join-Path $Output "manifest.json")
