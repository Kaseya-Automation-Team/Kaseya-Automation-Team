BeforeAll {
    $script:ModuleRoot = Split-Path -Path (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $script:ModuleRoot 'VSAModule.psd1') -Force
}

Describe "ConvertTo-VSAHashtable normalizes every nested-object input form" {

    It "returns an empty hashtable for `$null" {
        InModuleScope VSAModule {
            $ht = ConvertTo-VSAHashtable $null
            $ht | Should -BeOfType ([hashtable])
            $ht.Count | Should -Be 0
        }
    }

    It "passes a hashtable through, copying (not aliasing) it" {
        InModuleScope VSAModule {
            $src = @{ City = 'New York'; Zip = '10001' }
            $ht  = ConvertTo-VSAHashtable $src
            $ht.City | Should -Be 'New York'
            $ht.Zip  | Should -Be '10001'
            # mutating the result must not touch the caller's object
            $ht['City'] = 'Boston'
            $src.City | Should -Be 'New York'
        }
    }

    It "converts a PSCustomObject's NoteProperties to keys" {
        InModuleScope VSAModule {
            $obj = [pscustomobject]@{ PrimaryEmail = 'a@b.com'; Country = 'US' }
            $ht  = ConvertTo-VSAHashtable $obj
            $ht.PrimaryEmail | Should -Be 'a@b.com'
            $ht.Country      | Should -Be 'US'
        }
    }

    It "parses the legacy brace form '{ k= v; k2= v2 }'" {
        InModuleScope VSAModule {
            $ht = ConvertTo-VSAHashtable '{ City= New York; Country= US }'
            $ht.City    | Should -Be 'New York'
            $ht.Country | Should -Be 'US'
        }
    }

    It "parses the legacy plain newline form 'k=v`nk2=v2'" {
        InModuleScope VSAModule {
            $ht = ConvertTo-VSAHashtable "City=New York`nCountry=US"
            $ht.City    | Should -Be 'New York'
            $ht.Country | Should -Be 'US'
        }
    }

    It "keeps a value that itself contains '=' (splits on first '=' only)" {
        InModuleScope VSAModule {
            $ht = ConvertTo-VSAHashtable '{ Token= a=b=c }'
            $ht.Token | Should -Be 'a=b=c'
        }
    }

    It "preserves a value containing ';' when passed structurally (no corruption)" {
        InModuleScope VSAModule {
            $ht = ConvertTo-VSAHashtable @{ PrimaryPhone = '555;x99' }
            $ht.PrimaryPhone | Should -Be '555;x99'
        }
    }

    It "does not treat a backslash as an escape sequence (unlike ConvertFrom-StringData)" {
        InModuleScope VSAModule {
            $ht = ConvertTo-VSAHashtable @{ Path = 'C:\Temp\New' }
            $ht.Path | Should -Be 'C:\Temp\New'
        }
    }

    It "returns empty for a whitespace-only / empty string" {
        InModuleScope VSAModule {
            (ConvertTo-VSAHashtable '').Count      | Should -Be 0
            (ConvertTo-VSAHashtable '   ').Count   | Should -Be 0
            (ConvertTo-VSAHashtable '{}').Count    | Should -Be 0
        }
    }
}

Describe "New-VSAOrganization nested objects reach the request body" {

    It "accepts -ContactInfo as a hashtable and nests it under ContactInfo" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' `
                -ContactInfo @{ PrimaryEmail = 'a@b.com'; City = 'New York'; PrimaryPhone = '555;x99' } | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.ContactInfo.PrimaryEmail | Should -Be 'a@b.com'
            $obj.ContactInfo.City         | Should -Be 'New York'
            $obj.ContactInfo.PrimaryPhone | Should -Be '555;x99'
            # discrete contact fields must not leak to the top level
            $obj.PSObject.Properties.Name | Should -Not -Contain 'PrimaryEmail'
        }
    }

    It "still accepts the legacy -ContactInfo brace string" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' `
                -ContactInfo '{ PrimaryEmail= a@b.com; City= New York }' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.ContactInfo.PrimaryEmail | Should -Be 'a@b.com'
            $obj.ContactInfo.City         | Should -Be 'New York'
        }
    }

    It "builds ContactInfo from discrete parameters when -ContactInfo is not supplied" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' -PrimaryEmail 'x@y.com' -City 'Reno' | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.ContactInfo.PrimaryEmail | Should -Be 'x@y.com'
            $obj.ContactInfo.City         | Should -Be 'Reno'
        }
    }

    It "accepts -CustomFields as an array of hashtables, one object per element (no flattening)" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' -CustomFields @(
                @{ FieldName = 'Region'; FieldValue = 'EMEA' },
                @{ FieldName = 'Tier';   FieldValue = 'Gold' }
            ) | Out-Null
            $obj = $script:body | ConvertFrom-Json
            @($obj.CustomFields).Count | Should -Be 2
            ($obj.CustomFields | Where-Object FieldName -eq 'Region').FieldValue | Should -Be 'EMEA'
            ($obj.CustomFields | Where-Object FieldName -eq 'Tier').FieldValue   | Should -Be 'Gold'
        }
    }

    It "serializes a SINGLE -CustomFields element as a JSON array, not a bare object (live-found regression)" {
        # Deserializing back through ConvertFrom-Json hides this bug (a bare object round-trips just
        # like a 1-element array under Where-Object), so this checks the raw JSON text for the '['
        # array marker -- exactly what the live VSA API rejects with an HTTP 400 when missing.
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' -CustomFields @(
                @{ FieldName = 'Region'; FieldValue = 'EMEA' }
            ) | Out-Null
            $script:body | Should -Match '"CustomFields":\s*\['
        }
    }

    It "serializes a single -FieldName/-FieldValue pair as a JSON array too" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' -FieldName 'Region' -FieldValue 'EMEA' | Out-Null
            $script:body | Should -Match '"CustomFields":\s*\['
        }
    }

    It "accepts -Attributes as a hashtable" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAOrganization -OrgName 'Acme' -OrgRef 'acme' -Attributes @{ Segment = 'SMB' } | Out-Null
            $obj = $script:body | ConvertFrom-Json
            $obj.Attributes.Segment | Should -Be 'SMB'
        }
    }
}

Describe "Attributes-only cmdlets accept a native hashtable" {

    It "New-VSAScope nests -Attributes hashtable" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSAScope -ScopeName 'S1' -Attributes @{ Segment = 'SMB' } | Out-Null
            ($script:body | ConvertFrom-Json).Attributes.Segment | Should -Be 'SMB'
        }
    }

    It "New-VSARole nests -Attributes hashtable" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSARole -RoleName 'R1' -RoleTypeIds @('4') -Attributes @{ Segment = 'SMB' } | Out-Null
            ($script:body | ConvertFrom-Json).Attributes.Segment | Should -Be 'SMB'
        }
    }

    It "New-VSADepartment nests -Attributes hashtable" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            New-VSADepartment -OrgId 12345 -DepartmentName 'D1' -Attributes @{ Segment = 'SMB' } | Out-Null
            ($script:body | ConvertFrom-Json).Attributes.Segment | Should -Be 'SMB'
        }
    }

    It "New-VSAMachineGroup nests -Attributes hashtable" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            Mock Get-VSAOrganization { [pscustomobject]@{ OrgRef = 'acme'; OrgId = 12345 } }
            # A non-null connection is required so the internal parent-org lookup binds and the
            # Get-VSAOrganization mock is reached (its -VSAConnection param rejects $null).
            $conn = [VSAConnection]::new()
            New-VSAMachineGroup -VSAConnection $conn -OrgId 12345 -MachineGroupName 'G1' -Attributes @{ Segment = 'SMB' } | Out-Null
            ($script:body | ConvertFrom-Json).Attributes.Segment | Should -Be 'SMB'
        }
    }

    It "New-VSATenant now accepts a real -Attributes hashtable (was declared [hashtable] but string-parsed)" {
        InModuleScope VSAModule {
            $script:body = $null
            Mock Invoke-VSARestMethod { $script:body = $Body }
            $sec = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
            New-VSATenant -Ref 'T1' -AdminUserName 'admin' -Password $sec -EMail 'a@b.com' `
                -Attributes @{ Segment = 'SMB' } | Out-Null
            ($script:body | ConvertFrom-Json).Attributes.Segment | Should -Be 'SMB'
        }
    }
}
