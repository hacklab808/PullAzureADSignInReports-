#------------------------------------------------------------
# Copyright (c) Microsoft Corporation.  All rights reserved.
#------------------------------------------------------------
cls
Import-Module Azure

# This is the ID of your Tenant. You may replace the value with your Tenant Domain
$tenantId = "731c4d0a-4630-47c4-a878-61a112af78c2" # replace with your tenant ID. This is a random GUID.

# You can add or change filters here
$url = "https://graph.microsoft.com/beta/auditLogs/signIns?`$filter=createdDateTime%20ge%202019-02-01T06:00:00Z%20and%20createdDateTime%20le%202019-02-28T00:07:01.607Z&`$top=1000"

# By default, this script saves its results to DownloadedReport_currentTime.csv. You may change the file name as needed.
$now = "{0:yyyyMMdd_hhmmss}" -f (get-date)
$outputFile = "AAD_SignInReport_$now.csv"

###################################
#### DO NOT MODIFY BELOW LINES ####
###################################
Function Get-Headers {
    param( $token )

    Return @{
        "Authorization" = ("Bearer {0}" -f $token);
        "Content-Type" = "application/json";
    }
}

$clientId = "1b730954-1685-4b74-9bfd-dac224a7b894" # PowerShell clientId
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$MSGraphURI = "https://graph.microsoft.com"

$authority = "https://login.microsoftonline.com/$tenantId"
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
$authResult = $authContext.AcquireToken($MSGraphURI, $clientId, $redirectUri, "Always")
$token = $authResult.AccessToken

if ($token -eq $null) {
    Write-Output "ERROR: Failed to get an Access Token"
    exit
}

Write-Output "--------------------------------------------------------------"
Write-Output "Downloading report from $url"
Write-Output "Output file: $outputFile"
Write-Output "--------------------------------------------------------------"

# Call Microsoft Graph
$headers = Get-Headers($token)

$count=0
$retryCount = 0
$oneSuccessfulFetch = $False
$SignInReportArray = @()
Do {
    Write-Output "Fetching data using Url: $url"

    Try {
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $url)
        $XMLReportValues = ($myReport.Content | ConvertFrom-Json).value
		foreach ($SignInEntry in $XMLReportValues)
		    {
		     $SignInReport = New-Object PSObject
		     add-member -inputobject $SignInReport -membertype noteproperty -name "createdDateTime" -value $SignInEntry.createdDateTime
			 add-member -inputobject $SignInReport -membertype noteproperty -name "correlationId" -value $SignInEntry.correlationId
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Token Issuer Name" -value $SignInEntry.tokenIssuerName
		     add-member -inputobject $SignInReport -membertype noteproperty -name "Token Issuer Type" -value $SignInEntry.tokenIssuerType
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Original Request Id" -value $SignInEntry.originalRequestId
			 add-member -inputobject $SignInReport -membertype noteproperty -name "isInteractive" -value $SignInEntry.isInteractive
		     add-member -inputobject $SignInReport -membertype noteproperty -name "userDisplayName" -value $SignInEntry.userDisplayName
		     add-member -inputobject $SignInReport -membertype noteproperty -name "userprincipalname (UPN)" -value $SignInEntry.userPrincipalName
			 add-member -inputobject $SignInReport -membertype noteproperty -name "userId" -value $SignInEntry.userId
		     add-member -inputobject $SignInReport -membertype noteproperty -name "AppId" -value $SignInEntry.AppId
		     add-member -inputobject $SignInReport -membertype noteproperty -name "appDisplayName" -value $SignInEntry.appDisplayName
		     add-member -inputobject $SignInReport -membertype noteproperty -name "ipAddress" -value $SignInEntry.ipAddress
		     add-member -inputobject $SignInReport -membertype noteproperty -name "location" -value ($SignInEntry.location.city + ", " + $SignInEntry.location.state + ", " + $SignInEntry.location.countryOrRegion)
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Geo Location" -value $SignInEntry.location.geoCoordinates
		     add-member -inputobject $SignInReport -membertype noteproperty -name "clientAppUsed" -value $SignInEntry.clientAppUsed
		     add-member -inputobject $SignInReport -membertype noteproperty -name "DeviceId" -value $SignInEntry.deviceDetail.deviceId
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Device DisplayName" -value $SignInEntry.deviceDetail.devicedisplayname
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Device Operating System" -value $SignInEntry.deviceDetail.operatingSystem
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Device Compliance" -value $SignInEntry.deviceDetail.isCompliant
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Device Managed" -value $SignInEntry.deviceDetail.isManaged
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Device Trust Type" -value $SignInEntry.deviceDetail.trustType
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Browser" -value $SignInEntry.deviceDetail.browser	 
		     add-member -inputobject $SignInReport -membertype noteproperty -name "MFA Method" -value $SignInEntry.mfaDetail.authMethod
			 add-member -inputobject $SignInReport -membertype noteproperty -name "MFA Details" -value $SignInEntry.mfaDetail.authDetail
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Risk Detail" -value $SignInEntry.riskDetail
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Risk Level (Aggregate)" -value $SignInEntry.riskLevelAggregated
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Risk Level (SignIn)" -value $SignInEntry.riskLevelDuringSignIn
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Risk State" -value $SignInEntry.riskState
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Risk Type" -value (($SignInEntry.riskEventTypes | Out-String).Trim())
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Applied CA Policies" -value (($SignInEntry.appliedConditionalAccessPolicies | Out-String).Trim())
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Auth Processing Details" -value (($SignInEntry.authenticationProcessingDetails   | Out-String).Trim())
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Newtork Location Details" -value (($SignInEntry.networkLocationDetails | Out-String).Trim())
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Error Code" -value $SignInEntry.status.errorCode
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Failure Reason" -value $SignInEntry.status.failureReason
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Additional Details" -value $SignInEntry.status.additionalDetails
			 add-member -inputobject $SignInReport -membertype noteproperty -name "Authn Methods" -value (($SignInEntry.authenticationMethodsUsed | Out-String).Trim())
			 $SignInReportArray += $SignInReport
		     $SignInReport = $null
		     }
        $url = ($myReport.Content | ConvertFrom-Json).'@odata.nextLink'
        $count = $count+$XMLReportValues.Count
        Write-Output "Total Fetched: $count"
        $oneSuccessfulFetch = $True
        $retryCount = 0
    }
    Catch [System.Net.WebException] {
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Output $statusCode
        Write-Output $_.Exception.Message
        if($statusCode -eq 401 -and $oneSuccessfulFetch)
        {
            # Token might have expired! Renew token and try again
            $authResult = $authContext.AcquireToken($MSGraphURI, $clientId, $redirectUri, "Auto")
            $token = $authResult.AccessToken
            $headers = Get-Headers($token)
            $oneSuccessfulFetch = $False
			Write-Output "Access token expiry. Requested a new one and now retrying data query..."
        }
        elseif($statusCode -eq 429 -or $statusCode -eq 504 -or $statusCode -eq 503)
        {
            # throttled request or a temporary issue, wait for a few seconds and retry
            Start-Sleep -5
			Write-Output "A throttled request or a temporary issue. Waiting for 5 seconds and then retrying..."
			
        }
        elseif($statusCode -eq 403 -or $statusCode -eq 400 -or $statusCode -eq 401)
        {
            Write-Output "Please check the permissions of the user"
            break;
        }
        else {
            if ($retryCount -lt 5) {
                Write-Output "Retrying..."
                $retryCount++
            }
            else {
                Write-Output "Download request failed. Please try again in the future."
                break
            }
        }
     }
    Catch {
        $exType = $_.Exception.GetType().FullName
        $exMsg = $_.Exception.Message

        Write-Output "Exception: $_.Exception"
        Write-Output "Error Message: $exType"
        Write-Output "Error Message: $exMsg"

         if ($retryCount -lt 5) {
            Write-Output "Retrying..."
            $retryCount++
        }
        else {
            Write-Output "Download request failed. Please try again in the future."
            break
        }
    }

    Write-Output "--------------------------------------------------------------"
} while($url -ne $null)
$AuditOutputCSV = $Pwd.Path + "\" + $outputFile	
$SignInReportArray | select *  |  Export-csv $AuditOutputCSV -NoTypeInformation -Force
Write-host "Sign in activity report can be found at" $AuditOutputCSV "."
