param (
    [Parameter(Mandatory = $true)]
    [string]$InstanceID,

    [Parameter(Mandatory = $true)]
    [string]$BaseAMIName,

    [Parameter(Mandatory = $true)]
    [string]$Description
)

#credentials to connect aws
$accessKey = "AKIAY7SEYN2PJFJXRVLE"
$secretKey = "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"


Set-AWSCredential -AccessKey $accessKey -SecretKey $secretKey
Set-DefaultAWSRegion -Region us-east-2

# Import the AWSPowerShell module
if (-not (Get-Module -Name AWSPowerShell -ErrorAction SilentlyContinue)) {
    Install-Module -Name AWSPowerShell -Force -Verbose
}
Import-Module AWSPowerShell

# Generate a unique timestamp
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Create a unique AMI name by appending the timestamp to the base AMI name
$AMIName = "${BaseAMIName}_${Timestamp}"

# Check if an AMI with the specified name already exists
$existingAmi = Get-EC2Image -Owners self -Filters @{Name = "name"; Values = $AMIName}

if ($existingAmi) {
    Write-Output "An AMI with the name '$AMIName' already exists (AMI ID: $($existingAmi.ImageId)). Please choose a different base AMI name."
    exit 0
}

# Create an AMI from the specified EC2 instance
$AMIParams = @{
    InstanceId = $InstanceID
    Name = $AMIName
    Description = $Description
}
$AMIId = New-EC2Image @AMIParams

Write-Output "Creating AMI with ID: $AMIId and name: $AMIName"

# Wait for the AMI creation to complete
Write-Output "Waiting for the AMI creation to complete..."
$amiStatus = "pending"
while ($amiStatus -eq "pending") {
    Start-Sleep -Seconds 30  # Wait for 30 seconds before checking again
    $ami = Get-EC2Image -ImageIds $AMIId
    $amiStatus = $ami.State
}

# ... (Previous code remains unchanged)

if ($amiStatus -eq "available") {
    Write-Output "AMI creation completed. AMI ID: $AMIId"

    # Send a Slack notification using PowerShell equivalent of shell command
    $slackMessage = "AMI updated. New AMI ID: $AMIId"

    # Example using Invoke-Expression to execute a shell command
    $command = "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"$slackMessage\"}' https://slack.com/api/chat.postMessage"
    Invoke-Expression -Command $command
} else {
    Write-Output "AMI creation failed or timed out."
}



