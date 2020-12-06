New-Item -Path "." -Name "tmp" -ItemType "directory" -Force
Compress-Archive -Path "src/*" -DestinationPath "tmp/olympus.love" -Force
if (-Not $(Test-Path -Path "tmp/rcedit.exe" -PathType Leaf)) {
    Invoke-WebRequest -Uri "https://github.com/electron/rcedit/releases/download/v1.1.1/rcedit-x64.exe" -OutFile "tmp/rcedit.exe"
}
Copy-Item -Path "love/love.exe" -Destination "tmp/love.exe"
./tmp/rcedit.exe "tmp/love.exe" --set-icon "icon.ico"
if ($PSVersionTable.PSVersion.Major -gt 5) {
    Get-Content "tmp/love.exe","tmp/olympus.love" -Raw -AsByteStream | Set-Content "dist/main.exe" -NoNewline -AsByteStream
} else {
    Get-Content "tmp/love.exe","tmp/olympus.love" -Encoding Byte -ReadCount 512 | Set-Content "dist/main.exe" -Encoding Byte
}
Copy-Item -Path "sharp/bin/Debug/net452/*" -Destination "dist/sharp" -Recurse -Force
Compress-Archive -Path "dist/*" -DestinationPath "dist.zip" -Force
