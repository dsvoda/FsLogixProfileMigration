# Read the migration commands from the output file
$commands = Get-Content "c:\temp\migration_commands.txt"

# Initialize log file
$logFile = "c:\temp\migration_log.txt"
"Migration Log" | Set-Content $logFile

# Loop through each line in the file
for ($i = 0; $i -lt $commands.Count; $i += 2) {
    $username = $commands[$i]
    $commandLine = $commands[$i + 1]

    # If the line starts with a user name (uppercase letters followed by lowercase letters, digits, or underscores)
    if ($username -match "^[A-Z][a-zA-Z0-9_]*") {
        # Print the user name
        Write-Host "User name: " $username
    }
    # If the line starts with the command (.\frx.exe)
    if ($commandLine.StartsWith(".\frx.exe")) {
        try {
            # Split the command and its arguments
            $command, $arguments = $commandLine -split ' ', 2

            # Run the command, capture the output, and wait for it to finish
            $startTime = Get-Date
            $output = Start-Process -FilePath $command -ArgumentList $arguments -Wait -PassThru -RedirectStandardOutput "output.txt" -RedirectStandardError "error.txt"
            $endTime = Get-Date

            # Combine standard output and error output
            $output = Get-Content "output.txt" -Raw
            $errorOutput = Get-Content "error.txt" -Raw
            $output += "`n" + $errorOutput

            # Log the username, start time, stop time, and output from the frx command
            $logEntry = @"
User name: $username
Start time: $startTime
End time: $endTime
Output:
$output

"@
            Add-Content -Path $logFile -Value $logEntry
            Write-Host $logEntry
        }
        catch {
            Write-Host "Error: Could not find the process named 'frx'."
        }
    }
    else {
        Write-Host "Warning: Unrecognized command format -" $commandLine
    }
}
