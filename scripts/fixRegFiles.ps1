# Corrects line endings and encodings of all .reg files in the current folder.

Get-ChildItem -Filter *.reg | ForEach-Object {
    $path = $_.FullName
    $text = [System.IO.File]::ReadAllText($path)
    
    # Normalize Windows (\r\n), Linux (\n), and old Mac (\r) line endings all to `r`n
    $text = $text -replace '\r\n', "`n" -replace '\r', "`n" -replace '\n', "`r`n"
    
    # Write back as strict UTF-16 LE with BOM
    $enc = New-Object System.Text.UnicodeEncoding($false, $true)
    [System.IO.File]::WriteAllText($path, $text, $enc)
    Write-Host "Normalized: $($_.Name)" -ForegroundColor Cyan
}