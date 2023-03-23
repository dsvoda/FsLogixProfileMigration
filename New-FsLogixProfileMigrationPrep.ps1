# Load the ActiveDirectory module
Import-Module ActiveDirectory

# Function to get nested group members
function Get-ADGroupMembersRecursive {
    param (
        [string]$GroupName
    )

    $groupMembers = Get-ADGroupMember -Identity $GroupName

    $users = @()
    foreach ($member in $groupMembers) {
        if ($member.objectClass -eq 'group') {
            $users += Get-ADGroupMembersRecursive -GroupName $member.DistinguishedName
        } else {
            $users += $member
        }
    }
    return $users
}

# Specify the source file share path
$srcPath = "\\<source-storage-account-name>.file.core.windows.net\<source-share-name>"

# Specify the destination file share path
$dstPath = "\\<target-storage-account-name>.file.core.windows.net\<target-share-name>"

# Get all directories in the source file share
$srcDirectories = Get-ChildItem $srcPath -Directory

# Create an array to store the output lines
$outputLines = @()

# Specify the Active Directory group
$groupName = "YourGroupName"

# Get the group members (including nested groups)
$groupMembers = Get-ADGroupMembersRecursive -GroupName $groupName

# Loop through each directory in the source file share
foreach ($srcDirectory in $srcDirectories) {

  # Get the directory path
  $directoryPath = $srcDirectory.FullName

  # Get the SAM account name from the directory name
  $samAccountName = $srcDirectory.Name.Split("_")[0]

  # Get the user's name from Active Directory using their SAM account name
  $user = Get-ADUser -Filter "samAccountName -eq '$samAccountName'"

  # Check if the user is a member of the specified group (including nested groups)
  if ($groupMembers.SamAccountName -contains $user.SamAccountName) {

    # Create the same directory in the target file share
    New-Item -ItemType Directory -Path $directoryPath.Replace($srcPath, $dstPath)

    # Build the output line for the user's name
    $userLine = "$($user.Name)"

    # Check if the source profile is a .vhd or .vhdx file
    if (Test-Path "$directoryPath\Profile_$samAccountName.vhd") {
      $srcProfileExtension = "vhd"
      $dstProfileExtension = "vhdx"
    } else {
      $srcProfileExtension = "vhdx"
      $dstProfileExtension = "vhdx"
    }

    # Get the destination directory path
    $destinationDirectoryPath = $directoryPath.Replace($srcPath, $dstPath)

    # Build the output line for the command
    $commandLine = ".\frx.exe migrate-vhd -src $directoryPath\Profile_$samAccountName.$srcProfileExtension -dest $destinationDirectoryPath\Profile_$samAccountName.$dstProfileExtension -dynamic 1"

    # Add the user's name and command lines to the array
    $outputLines += "$userLine"
    $outputLines += "$commandLine"
  }
}

# Write the output lines to a text file
$outputLines | Out-File -FilePath "c:\temp\migration_commands.txt"
