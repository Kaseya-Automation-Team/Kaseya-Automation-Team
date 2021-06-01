$dir = $args[0]
$version = [System.Environment]::OSVersion.Version

function CheckForKB([string]$kb)
{
    $var = "NOT FOUND"

    Get-WmiObject -query 'select * from win32_quickfixengineering' | foreach { 
        if ($kb -eq $_.hotfixid) {
            $var = "FOUND"
        } 
    }

    return $var
}

function GetKBPackage([PSObject]$kb)
{
    
    echo "$kb.id is not installed. Downloading package now." | Out-File -FilePath $dir\adv-results.txt

    $arch = $env:PROCESSOR_ARCHITECTURE
    $url = ''
    if ($arch -eq 'ARM64') {
        $url = $kb.arm
    }
    elseif ($arch -eq "X86") {
        $url = $kb.thirtytwo
    }
    else {
        $url = $kb.sixtyfour
    }
    
    Invoke-WebRequest -Uri $url -OutFile $dir\adv990001.msu
}


# Windows 10
if ($version.Major -eq 10) {
    $kb = ""
    # Windows 10
    if ($version.Build -eq 10240) {
        $kbProperties = @{
            id = 'KB5001399'
            thirtytwo = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001399-x86_e3fe821338f8dcc5b9abc712ce940f34b6ce4f9e.msu'
            sixtyfour = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001399-x64_d33c5bf98f9c323bdfd3d7103a5215cb874221a1.msu'
            arm = ''
            server = ''
        }
        $kb = New-Object psobject -Property $kbProperties
    }
    # Windows 10 Version 1607/Server 2016
    elseif ($version.Build -eq 14393) {
        $kbProperties = @{
            id = 'KB5001402'
            thirtytwo = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001402-x86_27a769112966bdc171f5f300bfd4819f02941f5a.msu'
            sixtyfour = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001402-x64_0108fcc32c0594f8578c3787babb7d84e6363864.msu'
            arm = ''
            server = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001402-x64_0108fcc32c0594f8578c3787babb7d84e6363864.msu'
        }
        $kb = New-Object psobject -Property $kbProperties
    }
    # Windows 10 Version 1709/Windows Server, version 1709
    elseif ($version.Build -eq 16299) {
        $kbProperties = @{
            id = 'KB4565553'
            thirtytwo = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2020/07/windows10.0-kb4565553-x86_101e7e49f961c167004b225d4d1f2ccda2c01dd3.msu'
            sixtyfour = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2020/07/windows10.0-kb4565553-x64_37666386a4858aed971874a72cb8c07155c26a87.msu'
            arm = ''
            server = ''
        }
        $kb = New-Object psobject -Property $kbProperties
    }
    # Windows 10 1803
    elseif ($version.Build -eq 17134) {
        $kbProperties = @{
            id = 'KB5001400'
            thirtytwo = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001400-x86_33b0e69a37cce7580a22b26809324119f02dcf1c.msu'
            sixtyfour = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001400-x64_672ab2672f81d8d2ab5230330b85b4d9850ac364.msu'
            arm = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001400-arm64_731cf0186956fb37d5baa17cc69e758b7c347d37.msu'
            server = ''
        }
        $kb = New-Object psobject -Property $kbProperties
    }
    # Windows 10 1809/Server 2019
    elseif ($version.Build -eq 17763) {
        $kbProperties = @{
            id = 'KB5001404'
            thirtytwo = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001404-x86_1ea8389ee96eff8140e22ed380c18843feb6090a.msu'
            sixtyfour = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001404-x64_9f03f10f91f3273357c6664de75c7f21e1ff474f.msu'
            arm = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/04/windows10.0-kb5001404-arm64_5f8b70848dd152a1be103ed6a5ee145d33d4f907.msu'
            server = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001404-x64_9f03f10f91f3273357c6664de75c7f21e1ff474f.msu'
        }
        $kb = New-Object psobject -Property $kbProperties
    }
    # Windows 10 1903/Windows Server, version 1903
    elseif ($version.Build -eq 18362) {
        $kbProperties = @{
            id = 'KB4586863'
            thirtytwo = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2020/11/windows10.0-kb4586863-x86_86f473648ca0bda64644cd7468af9b5a59a704f9.msu'
            sixtyfour = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2020/11/windows10.0-kb4586863-x64_320630e7f8765a00c86d2669399889b2363d6d05.msu'
            arm = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2020/11/windows10.0-kb4586863-arm64_5a044802ade973512bc12019198289cb94e8e4f8.msu'
            server = 'http://download.windowsupdate.com/c/msdownload/update/software/secu/2020/11/windows10.0-kb4586863-x64_320630e7f8765a00c86d2669399889b2363d6d05.msu'
        }
        $kb = New-Object psobject -Property $kbProperties
    }
    # Windows 10 1909/Windows Server, version 1909
    elseif ($version.Build -eq 18363) {
        $kbProperties = @{
            id = 'KB5001406'
            thirtytwo = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001406-x86_0a632b8b2a0530cde819dc71e547261992df5d7d.msu'
            sixtyfour = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001406-x64_d1b35ccaf4c0ba85be7aa25568622a65675ae7dd.msu'
            arm = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001406-arm64_462d3efeff7d4ba7170dbc90b8eabaf407daff5c.msu'
            server = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2021/04/windows10.0-kb5001406-x64_d1b35ccaf4c0ba85be7aa25568622a65675ae7dd.msu'
        }
        $kb = New-Object psobject -Property $kbProperties
    }

    if ($kb -eq "")
    {
        echo "Operating System unaffected. (See: Kaseya Article #360019911337)" | Out-File -FilePath $dir\adv-results.txt
    }
    else {
        $result = CheckForKB($kb.id)
        if ($result -eq "FOUND")
        {
            echo "$kb.id already installed." | Out-File -FilePath $dir\adv-results.txt
        } 
        else {
            GetKBPackage($kb)
        }
    }
}