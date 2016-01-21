function Get-WindowsProductKey
{
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
    [CmdletBinding(SupportsShouldProcess=$false,
                   PositionalBinding=$true)]
    [Alias()]
    [OutputType()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateNotNull()]
        [Alias('Name','CN')]
        [String[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin
    {
        [String]$session = Get-Date -Format o
        New-CimSession -ComputerName $ComputerName -Credential $Credential -Name $session
    }
    Process
    {
        try
        {
        # 2147483650 is the decimal representation for HKEY_LOCAL_MACHINE
        [Byte[]]$values = (Invoke-CimMethod -ComputerName $ComputerName -Name $session -Namespace 'root\cimv2' -ClassName 'StdRegProv' -MethodName 'GetBinaryValue' `
            -Arguments @{hDefKey=[UInt32]2147483650;sSubKeyName='SOFTWARE\Microsoft\Windows NT\CurrentVersion\DefaultProductKey';sValueName='DigitalProductId'}).UValue
        # A character array of all possible key values
        [Char[]]$lookup = @("B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9")
        # 56 - 59, magic numbers ¯\_(ツ)_/¯
        [Int]$keyStartIndex = 52
        [Int]$keyEndIndex = $keyStartIndex + 15
        [Int]$decodeLength = 29
        [Int]$decodeStringLength = 15
        [Char[]]$decodedChars = $decodeLength
        [System.Collections.ArrayList]$hexPid = $null
        for($i = $keyStartIndex; $i -le $keyEndIndex; $i++){[Void]$hexPid.Add($values[$i])}
        for($i = $decodeLength - 1; $i -ge 0; $i--)
        {
            if(($i + 1) % 6 -eq 0) {$decodedChars[$i] = '-'}
            else
            {
                $digitMapIndex = [Int]0
                for ($j = $decodeStringLength - 1; $j -ge 0; $j--)
                {
                    [Int]$byteValue = ($digitMapIndex * [Int]256) -bor [Byte]$hexPid[$j]
                    $hexPid[$j] = [Byte]([Math]::Floor($byteValue / 24))
                    $digitMapIndex = $byteValue % 24
                    $decodedChars[$i] = $lookup[$digitMapIndex]
                }
            }
        }
        $STR = ''
        $decodedChars | ForEach-Object { $str+=$_ }
        }
        catch
        {
            Write-Error 'ERROR IT BROK'
        }

        $obj = [PSCustomObject]@{
            Node = 'PLS'
            Hostname = 'PLS'
            Caption = 'PLS'
            CSDVersion = 'PLD'
            OSArch = ''
            BuildNumber = '' 
            RegisteredTo = ''
            ProductID = ''
            ProductKey = $STR
        }
        Write-Output $obj
    }
    End
    {
    }
}