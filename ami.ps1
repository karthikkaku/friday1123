# Check if AWS CLI is installed
if (-not (Test-Path (Join-Path $env:ProgramFiles 'Amazon\AWSCLI\aws.exe'))){
    # AWS CLI not found, installing AWS CLI
    Write-Output "AWS CLI not found. Installing AWS CLI..."
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "$env:TEMP\AWSCLIV2.msi"
    Start-Process -Wait -FilePath msiexec -ArgumentList "/i $env:TEMP\AWSCLIV2.msi /qn" -NoNewWindow
}

# Check AWS CLI version
$awsVersion = aws --version

Write-Output "AWS CLI installed. Version: $awsVersion"

# Parameters - Instance ID, Base AMI Name, and Description
$InstanceID = $args[0]
$BaseAMIName = $args[1]
$Description = $args[2]

Write-Output "Instance ID: $InstanceID"
Write-Output "BaseAMIName: $BaseAMIName"
Write-Output "Description: $Description"

# Set your Slack API token here
$SLACK_API_TOKEN = "xoxb-6304431362048-6320659208197-YqD4S8FA2leoPaceMnKOEM2m"

# Generate a unique timestamp
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Create a unique AMI name by appending the timestamp to the base AMI name
$AMIName = "${BaseAMIName}_${Timestamp}"
# Check if an AMI with the specified name already exists
$existingAmi = aws ec2 describe-images --owners self --filters "Name=name,Values=$AMIName" --query 'Images[*].ImageId' --output text

if ($existingAmi) {
    Write-Output "An AMI with the name '$AMIName' already exists (AMI ID: $existingAmi). Please choose a different base AMI name."
    exit 0
}

# Create an AMI from the specified EC2 instance
$AMIId = aws ec2 create-image --instance-id $InstanceID --name $AMIName --description $Description --output text

Write-Output "Creating AMI with ID: $AMIId and name: $AMIName"

# Wait for the AMI creation to complete
$amiStatus = "pending"
while ($amiStatus -eq "pending") {
    Start-Sleep -Seconds 30  # Wait for 30 seconds before checking again
    $ami = aws ec2 describe-images --image-ids $AMIId --query 'Images[*].State' --output text
    $amiStatus = $ami
}

if ($amiStatus -eq "available") {
    Write-Output "AMI creation completed. AMI ID: $AMIId"
    $text = "$AMIId AMI Created Successfully"
    Invoke-RestMethod -Uri "https://hooks.slack.com/services/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" -Method Post -Body (@{text = $text} | ConvertTo-Json) -ContentType "application/json"
} else {
    Write-Output "AMI creation failed or timed out."
}
