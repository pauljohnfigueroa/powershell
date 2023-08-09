function GenPwd {
    param (
        [Parameter(Mandatory)]
        [int] $length,
        [int] $amountOfNonAlphanumeric = 1
    )
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}
 
GenPwd 40
#Read more: https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html#ixzz89lrfmx2r