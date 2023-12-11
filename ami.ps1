$env:SLACK_API_TOKEN = "xoxb-6304431362048-6320659208197-YqD4S8FA2leoPaceMnKOEM2m"

param (
    [Parameter(Mandatory = $true)]
    [string]$InstanceID,

    [Parameter(Mandatory = $true)]
    [string]$BaseAMIName,

    [Parameter(Mandatory = $true)]
    [string]$Description
)

# Rest of your code remains unchanged up to the point where Slack integration starts

# Slack notification integration
if ($amiStatus -eq "available") {
    Write-Output "AMI creation completed. AMI ID: $AMIId"

    # Construct the Slack message
    $slackMessage = "AMI updated. New AMI ID: $AMIId"

    # Slack API endpoint and message payload
    $uri = "https://slack.com/api/chat.postMessage"
    $token = $env:SLACK_API_TOKEN  # Replace with your Slack API token
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    $body = @{
        text = $slackMessage
    }

    # Send a Slack notification using PowerShell equivalent of REST API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -ContentType "application/json" -Body ($body | ConvertTo-Json) -ErrorAction Stop
        Write-Output "Slack API call successful. Response: $response"
    } catch {
        Write-Output "Error sending message to Slack: $_"
        Write-Output "The detailed error message: $($_.Exception.Message)"
        # Add more logging or handling here if needed
    }
} else {
    Write-Output "AMI creation failed or timed out."
}
