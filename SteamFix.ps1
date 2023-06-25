$folder = Get-Location
$user = $env:username
$account = New-Object System.Security.Principal.NTAccount ($user)
takeown /a /r /d Y /f $folder
$acl = Get-ACL $folder
$acl.SetOwner($account)
$permission = "FullControl"
$rights = [System.Security.AccessControl.FileSystemRights]$permission
$type = [System.Security.AccessControl.AccessControlType]::Allow
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule ($account, $rights, $type)
$acl.AddAccessRule($rule)
Set-ACL $folder -AclObject $acl
Get-ChildItem $folder -Recurse | ForEach-Object {
    $acl = Get-ACL $_.FullName
    $acl.AddAccessRule($rule)
    Set-ACL $_.FullName -AclObject $acl
}
