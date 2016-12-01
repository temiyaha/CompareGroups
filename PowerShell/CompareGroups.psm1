function Compare-RespectUser{
    param(
        [Parameter(Mandatory=$True)][string]$targetUPN
    )
    Add-Type -Path "C:\<Folder Path>\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    Add-Type -Path "C:\<Folder Path>\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    #Target Tenant Domain
    $tenant = "contoso.local"

    #Registered Application (Client ID)
    $clientID = "0f764d123-xxx-xxx-xxx-xxxxxxxxxx"
    $redirect = new-object System.Uri("http://localhost")

    #Get AAD Token
    $resource = "https://graph.microsoft.com"
    $AuthContext = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext("https://login.microsoftonline.com/$tenant") 
    $promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto
    $result = $AuthContext.AcquireToken($resource,$clientID,$redirect,$promptBehavior) 
    $headers = @{Authorization =("Bearer "+ $result.AccessToken)}

    #Get my groups
    $mymemberOfUrl = "https://graph.microsoft.com/v1.0/me/memberOf"
    $mymemberOf = Invoke-RestMethod -Method Get -Uri $mymemberOfUrl -headers $headers -ContentType 'application/json'
    $mygroups = $mymemberOf.value | where {$_.mailEnabled -eq 'True'} | select displayName,mailNickName,securityEnabled,"my","Respect","JoinURL"

    #Get target user's Groups
    $targetMemberOfUrl = "https://graph.microsoft.com/v1.0/users/$targetUPN/memberOf"
    $targetMemberOfs = Invoke-RestMethod -Method Get -Uri $targetMemberOfUrl -headers $headers -ContentType 'application/json'
    $targetGroups = $targetMemberOfs.value | where {$_.mailEnabled -eq 'True'} | select displayName,mailNickName,securityEnabled,"my","Respect","JoinURL"

    #create master group list
    $masterCollection = @()
    $masterCollection = $mygroups + $targetGroups | Select-Object displayName,mailNickName,securityEnabled,my,Respect,JoinURL -Unique
    
    #update my group data
    foreach ($masterRow in $masterCollection){
        foreach ($myRow in $mygroups){
            if($masterRow.mailNickName -eq $myRow.mailNickName){
                $masterRow.my = "1";
            }
        }
        foreach ($targetRow in $targetGroups){
         if($masterRow.mailNickName -eq $targetRow.mailNickName){
                $masterRow.Respect = "1";
            }
        }
    }
    foreach ($masterRow in $masterCollection){
        if (($masterRow.Respect -eq '1') -AND ($masterRow.my -ne '1')){
            $masterRow.JoinURL = "http://xyz"
        }
    }

    $masterCollection | Sort-Object displayName | Out-GridView -Title "Result Respect User"
        
}


function Compare-MyColleague{

    Add-Type -Path "C:\<Folder Path>\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    Add-Type -Path "C:\<Folder Path>\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    #Target Tenant Domain
    $tenant = "contoso.local"

    #Registered Application
    $clientID = "0f764123-xxx-xxx-xxx-xxxxxxxxxx"
    $redirect = new-object System.Uri("http://localhost")

    #Get AAD Token
    $resource = "https://graph.microsoft.com"
    $AuthContext = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext("https://login.microsoftonline.com/$tenant") 
    $promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto
    $result = $AuthContext.AcquireToken($resource,$clientID,$redirect,$promptBehavior) 
    $headers = @{Authorization =("Bearer "+ $result.AccessToken)}

    #Get my UPN
    $myInfoUrl = "https://graph.microsoft.com/v1.0/me"
    $myInfo = Invoke-RestMethod -Method Get -Uri $myInfoUrl -headers $headers -ContentType 'application/json'
    $myUPN = $myInfo.userPrincipalName

    #Get my groups
    $mymemberOfUrl = "https://graph.microsoft.com/v1.0/me/memberOf"
    $mymemberOf = Invoke-RestMethod -Method Get -Uri $mymemberOfUrl -headers $headers -ContentType 'application/json'
    $mygroups = $mymemberOf.value | where {$_.mailEnabled -eq 'True'} | select displayName,mailNickName,securityEnabled,"my","JoinURL"

    #Get my manager's UPN
    $managerUrl = "https://graph.microsoft.com/v1.0/me/manager"
    $manager = Invoke-RestMethod -Method Get -Uri $managerUrl -headers $headers -ContentType 'application/json'
    $managerUPN = $manager.userPrincipalName

    #Get my manager's direct Reports
    $directReportUrl = "https://graph.microsoft.com/v1.0/users/$managerUPN/directReports"
    $members = Invoke-RestMethod -Method Get -Uri $directReportUrl -headers $headers -ContentType 'application/json'
    $membersUPN = $members.value | select userPrincipalName

    $masterCollection = @()

    #Get colleague Groups exclude me
    foreach($colleague in $membersUPN){
        $upn = $colleague.userPrincipalName
        if ($upn -ne $myUPN){
            $memberOfUrl = "https://graph.microsoft.com/v1.0/users/$upn/memberOf"
            $memberOfs = Invoke-RestMethod -Method Get -Uri $memberOfUrl -headers $headers -ContentType 'application/json'
            $groups = $memberOfs.value |  where {$_.mailEnabled -eq 'True'} | select displayName,mailNickName,securityEnabled,"my","JoinURL"
            $masterCollection = $masterCollection + $groups |  Select-Object displayName,mailNickName,securityEnabled,"my","JoinURL" –Unique
        }
    }

    #update my group data
    foreach ($masterRow in $masterCollection){
        foreach ($myRow in $mygroups){
            if($masterRow.mailNickName -eq $myRow.mailNickName){
                $masterRow.my = "1";
            }
        }
    }

    foreach ($masterRow in $masterCollection){
        if ($masterRow.my -ne '1'){
            $masterRow.JoinURL = "http://xyz"
        }
    }

    $masterCollection | Sort-Object displayName | Out-GridView -Title "Result My Colleague"


}

Export-ModuleMember *







