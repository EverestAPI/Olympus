New-Item -Path "." -Name "tmp" -ItemType "directory" -Force
Compress-Archive -Path "src/*" -DestinationPath "tmp/main.zip" -Force
if ($PSVersionTable.PSVersion.Major -gt 5) {
    Get-Content "love/love.exe","tmp/main.zip" -Raw -AsByteStream | Set-Content "dist/main.exe" -NoNewline -AsByteStream
} else {
    Get-Content "love/love.exe","tmp/main.zip" -Encoding Byte -ReadCount 512 | Set-Content "dist/main.exe" -Encoding Byte
}
Copy-Item -Path "sharp/bin/Debug/net452/*" -Destination "dist/sharp" -Recurse -Force
Compress-Archive -Path "dist/*" -DestinationPath "dist.zip" -Force
