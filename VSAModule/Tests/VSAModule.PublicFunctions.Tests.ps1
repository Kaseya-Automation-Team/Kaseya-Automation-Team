$ModuleRoot = Split-Path -Path (Split-Path -Parent $PSScriptRoot)
$ModulePath = Join-Path -Path $ModuleRoot -ChildPath 'VSAModule.psd1'

BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "New-VSAAdminTask - sends a body (T-6.2)" {
    It "includes Reference, Description, EnabledFlag and TimeSheetFlag in the JSON body" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAAdminTask -Reference 'VSA-1' -Description 'Task one' -EnabledFlag -TimeSheetFlag | Out-Null
            $script:body | Should -Not -BeNullOrEmpty
            $obj = $script:body | ConvertFrom-Json
            $obj.Reference     | Should -Be 'VSA-1'
            $obj.Description    | Should -Be 'Task one'
            $obj.EnabledFlag    | Should -BeTrue
            $obj.TimeSheetFlag  | Should -BeTrue
        }
    }
}

Describe "Custom extension functions - Params initialised before use (T-6.4)" {
    It "New-VSACustomExtensionFolder forwards the exact VSAConnection" {
        InModuleScope VSAModule {
            $script:conn = $null
            Mock Invoke-VSARestMethod { $script:conn = $VSAConnection }
            $c = [VSAConnection]::new('https://vsa.example.com','u','t','p',[datetime]::Now.AddHours(1),$false,$false)
            New-VSACustomExtensionFolder -AgentId 10001 -Folder 'NewFolder' -VSAConnection $c | Out-Null
            $script:conn | Should -Be $c
        }
    }

    It "Publish-VSACustomExtensionFile forwards the exact VSAConnection" {
        InModuleScope VSAModule {
            $script:conn = $null
            $script:suffix = $null
            Mock Invoke-VSARestMethod { $script:conn = $VSAConnection; $script:suffix = $URISuffix }
            $tmp = New-TemporaryFile
            Set-Content -Path $tmp -Value 'hello'
            $c = [VSAConnection]::new('https://vsa.example.com','u','t','p',[datetime]::Now.AddHours(1),$false,$false)
            Publish-VSACustomExtensionFile -AgentId 10001 -SourceFilePath $tmp -DestinationFolder 'Dest' -VSAConnection $c | Out-Null
            Remove-Item $tmp -Force
            $script:conn | Should -Be $c
            $script:suffix | Should -Match 'customextensions/10001/file/Dest'
        }
    }
}

Describe "Update-VSAAPSettings - value in path AND flag in query (F-15, live Swagger docs/v1.0)" {
    # Live spec: PUT /automation/agentprocs/quicklaunch/askbeforeexecuting/{value} needs the value
    # in the path (required) AND a flag query boolean (required). The public webhelp was wrong
    # (fact #6) and the earlier F-49b change regressed this to query-only; restored here.
    It "sends the boolean in both the {value} path segment and the ?flag= query" {
        InModuleScope VSAModule {
            $script:capturedSuffix = $null
            Mock Invoke-VSARestMethod { $script:capturedSuffix = $URISuffix }
            Update-VSAAPSettings -Flag | Out-Null
            $script:capturedSuffix | Should -Be 'api/v1.0/automation/agentprocs/quicklaunch/askbeforeexecuting/true?flag=true'
        }
    }
}

Describe "Remove-VSAPatch - dangling URISuffix assignment removed (T-6.11)" {
    It "does not null out the default URISuffix before use" {
        InModuleScope VSAModule {
            $script:capturedSuffix = $null
            Mock Invoke-VSARestMethod { $script:capturedSuffix = $URISuffix }
            Remove-VSAPatch -AgentIds '979868787875855' | Out-Null
            $script:capturedSuffix | Should -Not -BeNullOrEmpty
            $script:capturedSuffix | Should -Match 'agentGuids=979868787875855'
        }
    }
}

Describe "New-VSAAPScheduled - AgentID/AgentProcedureId accept large numeric IDs (T-6.6)" {
    # New-VSAAPScheduled's DynamicParam block has a pre-existing, unrelated bug (a nonexistent
    # 'Create-Parameter' helper passed a bare [int] type-literal, which PowerShell's binder
    # rejects) that fires on every invocation regardless of -Repeat, so the cmdlet itself cannot
    # be invoked end-to-end here. That bug belongs to a separate remediation item; this test
    # verifies the T-6.6 fix directly against the static parameter metadata instead.
    It "declares AgentID as [string], not [int] (would overflow Int32 for real VSA IDs)" {
        $cmd = Get-Command -Name New-VSAAPScheduled
        $cmd.Parameters['AgentID'].ParameterType.Name | Should -Be 'String'
    }

    It "declares AgentProcedureId as [string], not [int]" {
        $cmd = Get-Command -Name New-VSAAPScheduled
        $cmd.Parameters['AgentProcedureId'].ParameterType.Name | Should -Be 'String'
    }

    It "the AgentID ValidateScript accepts a value exceeding Int32.MaxValue" {
        $cmd = Get-Command -Name New-VSAAPScheduled
        $validator = $cmd.Parameters['AgentID'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }
        $underscoreVar = New-Object System.Management.Automation.PSVariable('_', '979868787875855')
        { $validator.ScriptBlock.InvokeWithContext($null, $underscoreVar) } | Should -Not -Throw
    }
}

Describe "Enable-VSATenantRoleType - correct body for both parameter sets (T-6.3)" {
    It "ByName produces a non-null body containing the resolved role type IDs" {
        InModuleScope VSAModule {
            $script:body = $null
            # Role-type name->Id is now resolved from the live VSA (F-64), not a hardcoded map.
            Mock Get-VSARoleType {
                @(
                    [pscustomobject]@{ RoleTypeId = 105; RoleTypeName = 'SB Admin' }
                    [pscustomobject]@{ RoleTypeId = 116; RoleTypeName = 'KDP Admin' }
                )
            }
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Enable-VSATenantRoleType -TenantId 10001 -RoleType 'SB Admin', 'KDP Admin' | Out-Null
            $script:body | Should -Not -BeNullOrEmpty
            $script:body | Should -Not -Be 'null'
            $ids = $script:body | ConvertFrom-Json
            $ids | Should -Contain 105
            $ids | Should -Contain 116
        }
    }

    It "ById produces a non-null body containing the given role type IDs" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Enable-VSATenantRoleType -TenantId 10001 -RoleTypeId 105, 116 | Out-Null
            $script:body | Should -Not -BeNullOrEmpty
            $script:body | Should -Not -Be 'null'
            $ids = $script:body | ConvertFrom-Json
            $ids | Should -Contain 105
            $ids | Should -Contain 116
        }
    }
}

Describe "New-VSAOrganization - body built from bound params (T-6.7)" {
    It "preserves values containing commas and ampersands exactly" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Smith, Jones & Co' -OrgRef 'SJC' -Website 'https://x/?a=1' | Out-Null
            $script:body | Should -Not -BeNullOrEmpty
            $obj = $script:body | ConvertFrom-Json
            $obj.OrgName | Should -Be 'Smith, Jones & Co'
            $obj.Website | Should -Be 'https://x/?a=1'
            $obj.OrgRef  | Should -Be 'SJC'
        }
    }
}

Describe "Get-VSAAudit AllAgentsSummaries hits the base audit collection (F-24)" {
    It "builds URISuffix 'api/v1.0/assetmgmt/audit' (no /{0}) for the default AuditOf" {
        InModuleScope VSAModule {
            $script:auditSuffix = $null
            Mock Invoke-VSARestMethod { $script:auditSuffix = $URISuffix }
            $conn = [VSAConnection]::new('https://vsa.example.com','u','tok','pat',[datetime]::Now.AddHours(1),$false,$false)
            Get-VSAAudit -VSAConnection $conn | Out-Null   # default AuditOf = AllAgentsSummaries, no AgentID
            $script:auditSuffix | Should -Be 'api/v1.0/assetmgmt/audit'
        }
    }
    It "still targets the agent sub-resource for a specific AuditOf" {
        InModuleScope VSAModule {
            $script:auditSuffix = $null
            Mock Invoke-VSARestMethod { $script:auditSuffix = $URISuffix }
            $conn = [VSAConnection]::new('https://vsa.example.com','u','tok','pat',[datetime]::Now.AddHours(1),$false,$false)
            Get-VSAAudit -VSAConnection $conn -AuditOf Summary -AgentID 123 | Out-Null
            $script:auditSuffix | Should -Be 'api/v1.0/assetmgmt/audit/123/summary'
        }
    }
}

Describe "Get-VSAMachineGroup -ResolveIDs resolves orgs without a duplicate-key error (F-26)" {
    It "does not throw and attaches the resolved Organization" {
        InModuleScope VSAModule {
            Mock Update-VSAConnection {}
            Mock Invoke-VSARestMethod {
                if ($URISuffix -match 'machinegroups') { [pscustomobject]@{ MachineGroupId = 1; OrgId = 99 } }
                elseif ($URISuffix -match 'orgs')       { [pscustomobject]@{ OrgId = 99; OrgName = 'Acme' } }
            }
            $c = [VSAConnection]::new('https://vsa.example.com','u','t','p',[datetime]::Now.AddHours(1),$false,$false)
            # Before the F-26 fix this threw "Item has already been added: 'VSAConnection'".
            $r = Get-VSAMachineGroup -VSAConnection $c -ResolveIDs
            $r.Organization.OrgName | Should -Be 'Acme'
        }
    }
}

Describe "Get-VSAAuditDocument -DownloadDocument forwards OutFile, not DownloadsFolder (F-27)" {
    It "passes -OutFile (folder + document leaf) to the transport" {
        InModuleScope VSAModule {
            $script:outfile = 'UNSET'
            Mock Invoke-VSARestMethod { $script:outfile = $OutFile }
            $c = [VSAConnection]::new('https://vsa.example.com','u','t','p',[datetime]::Now.AddHours(1),$false,$false)
            Get-VSAAuditDocument -VSAConnection $c -AgentID 123 -Path 'sub/Doc.txt' -DownloadDocument -DownloadsFolder '/tmp/dl' | Out-Null
            $script:outfile | Should -Be (Join-Path '/tmp/dl' 'Doc.txt')
        }
    }
}

Describe "New-VSAAgentInstallPkg forwards the explicit VSAConnection (F-31)" {
    It "passes -VSAConnection through to the transport (was dropped -> only worked persistent)" {
        InModuleScope VSAModule {
            $script:conn = 'UNSET'
            Mock Invoke-VSARestMethod { $script:conn = $VSAConnection }
            $c = [VSAConnection]::new('https://vsa.example.com','u','t','p',[datetime]::Now.AddHours(1),$false,$false)
            New-VSAAgentInstallPkg -VSAConnection $c -MachineGroupId 123 -AgentType windows -PackageName 'p' -PackageDescription 'd' | Out-Null
            $script:conn | Should -Be $c
        }
    }
}

Describe "Get-VSAAPFile -DownloadFile routes through the transport so cert-bypass applies (F-32)" {
    It "calls Invoke-VSARestMethod (not a raw Invoke-RestMethod) with GET + OutFile + the getfiles/file URISuffix" {
        InModuleScope VSAModule {
            $script:dlUri = $null; $script:dlMethod = $null; $script:dlOut = $null; $script:dlConn = 'UNSET'
            # If the download path still used a raw Invoke-RestMethod, this mock would NOT be hit
            # (the call would try a real request with no cert-bypass). Asserting it IS hit, with an
            # OutFile, is the regression guard for F-32.
            Mock Invoke-VSARestMethod { $script:dlUri = $URISuffix; $script:dlMethod = $Method; $script:dlOut = $OutFile; $script:dlConn = $VSAConnection }
            $c = [VSAConnection]::new('https://vsa.example.com','u','t','p',[datetime]::Now.AddHours(1),$false,$false)
            Get-VSAAPFile -VSAConnection $c -AgentId 123 -Path 'sub\file.txt' -DownloadsFolder 'TestDrive:\' -DownloadFile | Out-Null
            $script:dlMethod | Should -Be 'GET'
            $script:dlUri    | Should -Match '^api/v1\.0/assetmgmt/getfiles/123/file/'
            $script:dlOut    | Should -Match 'file\.txt$'
            $script:dlConn   | Should -Be $c
        }
    }
    It "does not use a raw Invoke-RestMethod in the DownloadFile branch (source guard)" {
        # Strip comment lines first so an explanatory comment mentioning the cmdlet name by prose
        # can't trip the guard; we only care about actual code invoking the raw cmdlet.
        # Nested 2-arg Join-Path: Windows PowerShell 5.1's Join-Path takes only -Path/-ChildPath,
        # so the 3+-segment form (valid on PS7) throws "A positional parameter cannot be found" and
        # this source guard never runs on 5.1 (F-73).
        $code = (Get-Content (Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'public') 'Get-VSAAPFile.ps1')) |
            Where-Object { $_ -notmatch '^\s*#' }
        ($code -join "`n") | Should -Not -Match '\bInvoke-RestMethod\b'
    }
}

Describe "New-VSAAPScheduled omits SpecificDayOfMonth unless supplied (F-35)" {
    It "does NOT send SpecificDayOfMonth when only -DayOfMonth is used (server: 'Both ... cannot be set')" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAAPScheduled -AgentID 1 -AgentProcedureId 2 -Repeat 'Months' -DayOfMonth 'LastDay' `
                -EndAt '1345' -EndOn ([datetime]'2030-12-31') -StartOn ([datetime]'2030-01-01') | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.Recurrence.DayOfMonth | Should -Be 'LastDay'
            # Before F-35 this was always present (=0), colliding with DayOfMonth -> HTTP 400.
            ($obj.Recurrence.PSObject.Properties.Name -contains 'SpecificDayOfMonth') | Should -BeFalse
        }
    }
    It "DOES send SpecificDayOfMonth when the caller supplies it" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAAPScheduled -AgentID 1 -AgentProcedureId 2 -Repeat 'Months' -SpecificDayOfMonth 15 `
                -EndAt '1345' -EndOn ([datetime]'2030-12-31') -StartOn ([datetime]'2030-01-01') | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.Recurrence.SpecificDayOfMonth | Should -Be 15
        }
    }
}

Describe "Get-VSASDTicket refuses ambiguity with an ACTIONABLE message" {

    # The VSA API has no "all tickets" collection -- a bare api/v1.0/automation/servicedesktickets
    # returns HTTP 403 -- so tickets are addressable only per service desk. Requiring an id is
    # therefore correct, but "provide an id" is a dead end unless the message says where ids come
    # from. Reported by a user running `Get-VSASDTicket -VSAConnection $c -Parallel`.

    It "names both parameters, explains the API constraint, and points at Get-VSASD" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            $err = $null
            try { Get-VSASDTicket -VSAConnection $conn } catch { $err = $_ }
            $err | Should -Not -BeNullOrEmpty
            $err.Exception.Message | Should -BeLike '*-ServiceDeskId*'
            $err.Exception.Message | Should -BeLike '*-ServiceDeskTicketId*'
            $err.Exception.Message | Should -BeLike '*no "all tickets" endpoint*'
            $err.Exception.Message | Should -BeLike '*Get-VSASD*'
        }
    }

    It "still rejects supplying BOTH ids" {
        InModuleScope VSAModule {
            $conn = [VSAConnection]::new(); $conn.URI = 'https://vsa.example/'; $conn.Token = 't'
            { Get-VSASDTicket -VSAConnection $conn -ServiceDeskId 1 -ServiceDeskTicketId 2 } |
                Should -Throw '*exactly one*'
        }
    }

    It "the Get-VSASD alias it recommends actually exists and is exported" {
        # Guards the message against naming a cmdlet that does not exist.
        (Get-Command Get-VSASD -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Import-PowerShellDataFile "$ModuleRoot/VSAModule.psd1").AliasesToExport | Should -Contain 'Get-VSASD'
    }
}

Describe "Update-VSAStaff always sends Function, because the backend requires it (F-69)" {

    # Found by real (non -WhatIf) writes against a live VSA: the stored procedure behind this
    # endpoint takes this field as '@purpose' and rejects the WHOLE update with HTTP 500 --
    # "expects parameter '@purpose', which was not supplied" -- when the key is absent.
    # It was historically sent unconditionally for this reason; the F-52 prune-by-bound-state
    # refactor made it conditional and silently reintroduced the failure.

    It "sends Function even when the caller omits it, using the CURRENT value (no wipe)" {
        InModuleScope VSAModule {
            $script:sentBody = $null
            Mock Get-VSAStaff { [pscustomobject]@{ OrgStaffId = '42'; Function = 'Engineer' } }
            Mock Invoke-VSAWriteRequest { $script:sentBody = $Body }
            Update-VSAStaff -OrgStaffId '42' -OrgIdNumber '7' -StaffFullName 'Someone' -Confirm:$false
            $body = $script:sentBody | ConvertFrom-Json
            $body.PSObject.Properties.Name | Should -Contain 'Function' -Because 'omitting the key 500s the whole update'
            $body.Function | Should -Be 'Engineer' -Because 'the existing job function must be preserved, not wiped'
        }
    }

    It "honours an explicitly supplied Function" {
        InModuleScope VSAModule {
            $script:sentBody = $null
            Mock Get-VSAStaff { [pscustomobject]@{ OrgStaffId = '42'; Function = 'Engineer' } }
            Mock Invoke-VSAWriteRequest { $script:sentBody = $Body }
            Update-VSAStaff -OrgStaffId '42' -OrgIdNumber '7' -StaffFullName 'Someone' -Function 'Manager' -Confirm:$false
            ($script:sentBody | ConvertFrom-Json).Function | Should -Be 'Manager'
        }
    }
}

Describe "Set-VSARCService preserves ClientApp/Path when omitted (F-79)" {

    # The update endpoint null-refs (HTTP 500) if the body lacks ClientApp/Path, so an update of just
    # ServiceName/Port (their mandatory params) failed live. The cmdlet now reads the current service
    # and re-sends the existing ClientApp/Path when the caller does not override them.

    It "sends the current ClientApp/Path when the caller supplies only ServiceName/Port" {
        InModuleScope VSAModule {
            Mock Get-VSARCService { [pscustomobject]@{ ServiceId = 'svc-1'; ServiceName = 'old'; Port = 22; ClientApp = 'https'; Path = 'C:\Keep' } }
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Set-VSARCService -ServiceId 'svc-1' -ServiceName 'new' -Port 3390 -Confirm:$false
            $script:body['ServiceName'] | Should -Be 'new'
            $script:body['Port']        | Should -Be 3390
            $script:body['ClientApp']   | Should -Be 'https' -Because 'preserved from the current service, not dropped'
            $script:body['Path']        | Should -Be 'C:\Keep'
        }
    }

    It "honours an explicitly supplied ClientApp/Path over the current values" {
        InModuleScope VSAModule {
            Mock Get-VSARCService { [pscustomobject]@{ ServiceId = 'svc-1'; ClientApp = 'https'; Path = 'C:\Keep' } }
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Set-VSARCService -ServiceId 'svc-1' -ServiceName 'new' -Port 3390 -ClientApp 'ssh' -Path '' -Confirm:$false
            $script:body['ClientApp'] | Should -Be 'ssh'
        }
    }
}

Describe "Send-VSAEmail always sends a UniqueTag (F-80)" {

    # The server rejects a missing UniqueTag with HTTP 400 "UniqueTag can't be null". -UniqueTag stays
    # optional for the caller; the module generates one when it is omitted.

    It "generates a UniqueTag when the caller omits it" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Send-VSAEmail -FromAddress 'a@b.com' -ToAddress 'c@d.com' -Subject 's' -Body 'b' -Confirm:$false
            $obj = $script:body | ConvertFrom-Json
            $obj.UniqueTag | Should -Not -BeNullOrEmpty
        }
    }

    It "honours an explicit UniqueTag" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSAWriteRequest { $script:body = $Body }
            Send-VSAEmail -FromAddress 'a@b.com' -ToAddress 'c@d.com' -Subject 's' -Body 'b' -UniqueTag 'mytag' -Confirm:$false
            ($script:body | ConvertFrom-Json).UniqueTag | Should -Be 'mytag'
        }
    }
}
