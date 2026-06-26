$signalFile = "E:\whatsapp-mcp\whatsapp-bridge\incoming.jsonl"
$processedFile = "E:\whatsapp-mcp\whatsapp-bridge\incoming.processed"

# Get current line count (or 0 if file doesn't exist)
if (Test-Path $processedFile) {
    $lastLine = [int](Get-Content $processedFile)
} else {
    if (Test-Path $signalFile) {
        $lastLine = (Get-Content $signalFile | Measure-Object -Line).Lines
    } else {
        $lastLine = 0
    }
    Set-Content $processedFile $lastLine -Encoding utf8
}

# Poll every 3 seconds for new messages
while ($true) {
    Start-Sleep -Seconds 3

    if (-not (Test-Path $signalFile)) { continue }

    $lines = Get-Content $signalFile -Encoding utf8
    $currentCount = $lines.Count

    if ($currentCount -gt $lastLine) {
        # New messages found
        $newMessages = $lines[$lastLine..($currentCount - 1)]
        $lastLine = $currentCount
        Set-Content $processedFile $lastLine -Encoding utf8

        # Output for Claude hook - systemMessage + exit code 2 to wake Claude
        $msgList = ($newMessages | ForEach-Object {
            try {
                $obj = $_ | ConvertFrom-Json
                "[$($obj.ts)] $($obj.name) ($($obj.sender)): $($obj.text)"
            } catch {
                $_
            }
        }) -join "`n"

        $output = @{
            hookSpecificOutput = @{
                hookEventName = "SessionStart"
                additionalContext = "INCOMING WHATSAPP MESSAGES:`n$msgList"
            }
        } | ConvertTo-Json -Depth 3 -Compress

        Write-Output $output
        exit 2
    }
}
