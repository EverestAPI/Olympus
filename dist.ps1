New-Item -Path "." -Name "tmp" -ItemType "directory" -Force
Compress-Archive -Path "src/*" -DestinationPath "tmp/olympus.love" -Force
if ($PSVersionTable.PSVersion.Major -gt 5) {
    Get-Content "love/love.exe","tmp/olympus.love" -Raw -AsByteStream | Set-Content "dist/main.exe" -NoNewline -AsByteStream
} else {
    Get-Content "love/love.exe","tmp/olympus.love" -Encoding Byte -ReadCount 512 | Set-Content "dist/main.exe" -Encoding Byte
}
Copy-Item -Path "sharp/bin/Debug/net452/*" -Destination "dist/sharp" -Recurse -Force
Compress-Archive -Path "dist/*" -DestinationPath "dist.zip" -Force
