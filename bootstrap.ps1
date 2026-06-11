param(
    [switch]$SkipUpdateExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$repositories = @(
    @{ Owner = "TomPhongphath"; Repo = "STS-ADM" },
    @{ Owner = "TomPhongphath"; Repo = "STS-ALERT" },
    @{ Owner = "TomPhongphath"; Repo = "STS-Common" },
    @{ Owner = "TomPhongphath"; Repo = "STS-DASHBOARD" },
    @{ Owner = "TomPhongphath"; Repo = "STS-INSTALL" },
    @{ Owner = "TomPhongphath"; Repo = "STS-INVENTORY-CONTROL" },
    @{ Owner = "TomPhongphath"; Repo = "STS-MASTER" },
    @{ Owner = "TomPhongphath"; Repo = "STS-NOC" },
    @{ Owner = "TomPhongphath"; Repo = "SCS-TELEPORT" },
    @{ Owner = "TomPhongphath"; Repo = "sts-portal" }
)

$persistentDirectories = @(
    "data"
)

function Ensure-Repository {
    param(
        [Parameter(Mandatory = $true)][string]$Owner,
        [Parameter(Mandatory = $true)][string]$Repo
    )

    $targetPath = Join-Path (Get-Location) $Repo
    $gitPath = Join-Path $targetPath ".git"

    if (Test-Path $targetPath) {
        if (Test-Path $gitPath) {
            cmd /c "git -C `"$targetPath`" rev-parse --verify HEAD >NUL 2>NUL"
            if ($LASTEXITCODE -eq 0) {
                if (-not $SkipUpdateExisting) {
                    Write-Host "Updating $Repo ..."
                    git -C $targetPath fetch --all --prune | Out-Host
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to update repository '$Repo'."
                    }
                }
                else {
                    Write-Host "Skipping update for existing repo $Repo"
                }
                return
            }

            Write-Host "Repository $Repo has no valid HEAD, re-cloning ..."
            Remove-Item -Path $targetPath -Recurse -Force
        }

        if (Test-Path $targetPath) {
            $existingItems = Get-ChildItem -Force -Path $targetPath
            if ($existingItems.Count -gt 0) {
                throw "Path '$targetPath' exists but is not a git repository. Move or delete it, then re-run bootstrap."
            }

            Remove-Item -Path $targetPath -Force
        }
    }

    $remoteUrl = "https://github.com/$Owner/$Repo.git"
    Write-Host "Cloning $Repo ..."
    git clone --depth 1 $remoteUrl $targetPath | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone repository '$Repo' from '$remoteUrl'."
    }
}

Write-Host "Ensuring STS source repositories ..."
foreach ($repository in $repositories) {
    Ensure-Repository -Owner $repository.Owner -Repo $repository.Repo
}

Write-Host "Ensuring persistent data directories ..."
foreach ($relativePath in $persistentDirectories) {
    $fullPath = Join-Path (Get-Location) $relativePath
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath | Out-Null
    }
}

$envFile = Join-Path (Get-Location) ".env"
$envExampleFile = Join-Path (Get-Location) ".env.example"
if (-not (Test-Path $envFile) -and (Test-Path $envExampleFile)) {
    Copy-Item -Path $envExampleFile -Destination $envFile
    Write-Host "Created .env from .env.example"
}

Write-Host "Bootstrap completed."
