function Get-WindowsProductKey
{
<#
    .SYNOPSIS
    
    Retrives a Windows license key.
    .DESCRIPTION
    
    Retrives a Windows license key from local and remote computers
    via a WMI call to the registry along with additonal information
    from the OperatingSystem WMI class.
    .PARAMETER Computers
    
    The list of computers to get the license key information for.
    .INPUTS
    
    Strings that are placed into an array to process.
    .OUTPUTS
    
    Returns an object with operating system and licensing data.
    .EXAMPLE
    
    Get-WindowsProductKey
	
	
    Node         : EXAMPLE1
    Hostname     : EXAMPLE1
    Caption      : Microsoft Windows 7 Enterprise 
    CSDVersion   : Service Pack 1
    OSArch       : 64-bit
    BuildNumber  : 7601
    RegisteredTo : Windows User
    ProductID    : 12345-678-9876543-21234
    ProductKey   : ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
	
    
    Returns the licensing information for the local computer.
    .EXAMPLE
    
    C:\PS> Get-WindowsProductKey -Computers EXAMPLE2, EXAMPLE3
    
    
    Node         : EXAMPLE2
    Hostname     : EXAMPLE2
    Caption      : Microsoft Windows Server 2012 Standard
    CSDVersion   : 
    OSArch       : 64-bit
    BuildNumber  : 9200
    RegisteredTo : Windows User
    ProductID    : 12345-678-9876543-21234
    ProductKey   : ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
    
    Node         : EXAMPLE3
    Hostname     : EXAMPLE3
    Caption      : Microsoft Windows 8 Enterprise
    CSDVersion   : 
    OSArch       : 64-bit
    BuildNumber  : 9200
    RegisteredTo : Windows User
    ProductID    : 12345-678-9876543-21234
    ProductKey   : ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
    
    
    Returns the licensing information for the remote computers.
    WMI call access and firewall exceptions are required.
    .EXAMPLE
    
    C:\PS> Get-WindowsProductKey -Computers 10.0.26.182, fe80::c9a5:ed01:f6d4:3890%10
    
    
    Node         : EXAMPLE4
    Hostname     : EXAMPLE4
    Caption      : Microsoft Windows Server 2008 R2 Standard
    CSDVersion   : Service Pack 1
    OSArch       : 64-bit
    BuildNumber  : 7601
    RegisteredTo : Windows User
    ProductID    : 12345-678-9876543-21234
    ProductKey   : ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
    
    Node         : EXAMPLE5
    Hostname     : EXAMPLE5
    Caption      : Microsoft Windows Server 2008 R2 Standard
    CSDVersion   : Service Pack 1
    OSArch       : 64-bit
    BuildNumber  : 7601
    RegisteredTo : Windows User
    ProductID    : 12345-678-9876543-21234
    ProductKey   : ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
    
    
    IPv6 and IPv4 addresses can also be used.
#>
	[cmdletbinding()]
	param
	(
		[Parameter(
        Mandatory=$false,
		Position=0)]
		[Alias("Computer","Server","Node")]
		[string[]]
        $ComputerName = $env:COMPUTERNAME,
        [Parameter(
        Mandatory=$false,
        Position=1)]
        [PSCredential]
        $Credential = [PSCredential]::Empty
	)

	foreach($computer in $ComputerName)
	{
		try
		{
            if(!($computer -eq $env:COMPUTERNAME))
            {
                $reg = Get-WmiObject -ComputerName $computer -List -Namespace "root\default" -Credential $Credential | Where-Object {$_.Name -eq "StdRegProv"}
    	        $win32os = Get-WmiObject -ComputerName $computer -Class Win32_OperatingSystem -Credential $Credential
            }
            else
            {
                $reg = Get-WmiObject -ComputerName $computer -List -Namespace "root\default" | Where-Object {$_.Name -eq "StdRegProv"}
                $win32os = Get-WmiObject -ComputerName $computer -Class Win32_OperatingSystem
            }
			$values = [byte[]]($reg.getbinaryvalue(2147483650,"SOFTWARE\Microsoft\Windows NT\CurrentVersion\DefaultProductKey","DigitalProductId").uvalue)
			$lookup = [char[]]("B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9")
			$keyStartIndex = [int]52;
			$keyEndIndex = [int]($keyStartIndex + 15);
			$decodeLength = [int]29
			$decodeStringLength = [int]15
			$decodedChars = New-Object char[] $decodeLength
			$hexPid = New-Object System.Collections.ArrayList
			for ($i = $keyStartIndex; $i -le $keyEndIndex; $i++) {[void]$hexPid.Add($values[$i])}
			for ($i = $decodeLength - 1; $i -ge 0; $i--)
			{
				if (($i + 1) % 6 -eq 0) {$decodedChars[$i] = '-'}
				else
				{
					$digitMapIndex = [int]0
					for ($j = $decodeStringLength - 1; $j -ge 0; $j--)
					{
						$byteValue = [int](($digitMapIndex * [int]256) -bor [byte]$hexPid[$j]);
						$hexPid[$j] = [byte]([math]::Floor($byteValue / 24));
						$digitMapIndex = $byteValue % 24;
						$decodedChars[$i] = $lookup[$digitMapIndex];
					}
				}
			}
			$STR = ''
			$decodedChars | % { $str+=$_ }

		    $object = New-Object Object
		    $object | Add-Member Noteproperty Node -value $computer
		    $object | Add-Member Noteproperty Hostname -value $win32os.CSName
		    $object | Add-Member Noteproperty Caption -value $win32os.Caption
		    $object | Add-Member Noteproperty CSDVersion -value $win32os.CSDVersion
		    $object | Add-Member Noteproperty OSArch -value $win32os.OSArchitecture
		    $object | Add-Member Noteproperty BuildNumber -value $win32os.BuildNumber
		    $object | Add-Member Noteproperty RegisteredTo -value $win32os.RegisteredUser
		    $object | Add-Member Noteproperty ProductID -value $win32os.SerialNumber
		    $object | Add-Member Noteproperty ProductKey -value $STR
		    Write-Output $object
		}
		catch [system.exception]
		{
			Write-Error $_
		}
	}
}
