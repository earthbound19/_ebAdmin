Get-ChildItem -Filter *.reg -Recurse | ForEach-Object {
    $path = $_.FullName
    try {
        # Read file regardless of its current messy encoding
        $text = [System.IO.File]::ReadAllText($path)
        
        # Normalize all line endings (Windows, Linux, old Mac) to CRLF
        $text = $text -replace '\r\n', "`n" -replace '\r', "`n" -replace '\n', "`r`n"
        
        # Write back out with a pristine UTF-16 LE BOM encoder
        $enc = New-Object System.Text.UnicodeEncoding($false, $true)
        [System.IO.File]::WriteAllText($path, $text, $enc)
        
        Write-Host "Cleaned: $($_.FullName)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to process $($_.FullName): $_" -ForegroundColor Red
    }
}