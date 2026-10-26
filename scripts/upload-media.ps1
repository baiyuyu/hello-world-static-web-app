<#
.SYNOPSIS
  Uploads media files to Azure Blob Storage without redeploying the website.

.EXAMPLE
  .\scripts\upload-media.ps1                          # upload everything in media\
  .\scripts\upload-media.ps1 media\hello-world.svg    # upload specific file(s), separated by spaces
#>
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Path,
    [string]$AccountName = "helloworldmediabaiyuyu",
    [string]$Container = "media",
    [string]$CacheControl = "public, max-age=3600"
)

$ErrorActionPreference = "Stop"
$mediaRoot = Join-Path $PSScriptRoot "..\media" | Resolve-Path

$contentTypes = @{
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".webp" = "image/webp"
    ".mp4"  = "video/mp4"
    ".webm" = "video/webm"
    ".mp3"  = "audio/mpeg"
    ".pdf"  = "application/pdf"
}

if ($Path) {
    $files = $Path | ForEach-Object { Get-Item -LiteralPath $_ }
} else {
    $files = Get-ChildItem -LiteralPath $mediaRoot -File -Recurse
}

foreach ($file in $files) {
    if (-not $file.FullName.StartsWith($mediaRoot.Path, [StringComparison]::OrdinalIgnoreCase)) {
        throw "File must be inside the media folder: $($file.FullName)"
    }
    $blobName = $file.FullName.Substring($mediaRoot.Path.Length).TrimStart("\", "/").Replace("\", "/")
    $contentType = $contentTypes[$file.Extension.ToLowerInvariant()]
    if (-not $contentType) { $contentType = "application/octet-stream" }

    Write-Host "Uploading $blobName ($contentType)..."
    az storage blob upload `
        --account-name $AccountName `
        --container-name $Container `
        --file $file.FullName `
        --name $blobName `
        --content-type $contentType `
        --content-cache-control $CacheControl `
        --overwrite `
        --no-progress `
        --auth-mode login `
        --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Upload failed: $blobName" }

    Write-Host "  https://$AccountName.blob.core.windows.net/$Container/$blobName"
}
