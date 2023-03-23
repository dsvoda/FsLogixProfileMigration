# Read the migration commands from the output file
$commands = Get-Content "c:\temp\migration_commands.txt"

# Loop through each line in the file
foreach ($line in $commands) {
  # If the line starts with a user name
  if ($line -match "^[A-Z]") {
    # Print the user name
    Write-Host $line
  } else {
    # If the line starts with the command
    # Run the command and wait for it to finish
    & $line
    Wait-Process -Name frx
  }
}
