function New-VSARuntimeParameter {
    <#
    .SYNOPSIS
        Builds a single RuntimeDefinedParameter for use inside a DynamicParam block.
    .DESCRIPTION
        Shared helper for the schedule/recurrence cmdlets whose DynamicParam blocks add the same
        family of runtime parameters (Times, DaysOfWeek, DayOfMonth, MonthOfYear, ...) when a
        recurring -Repeat is chosen. It constructs a
        System.Management.Automation.RuntimeDefinedParameter carrying a ParameterAttribute (with the
        requested Mandatory flag) and, when a value list is supplied, a ValidateSetAttribute.

        Being a private module function it is dot-sourced into module scope, which is the scope a
        DynamicParam block of any module cmdlet executes in, so the schedule cmdlets can call it
        directly instead of each redefining an identical local copy.
    .PARAMETER Name
        The name of the runtime parameter to create.
    .PARAMETER Type
        The .NET type of the runtime parameter (e.g. [int], [string]).
    .PARAMETER ValidateSet
        Optional set of permitted values; when supplied a ValidateSetAttribute is attached.
    .PARAMETER Mandatory
        Whether the runtime parameter is mandatory. Defaults to $false.
    .OUTPUTS
        System.Management.Automation.RuntimeDefinedParameter
    #>
    param (
        [string] $Name,
        [Type] $Type,
        [string[]] $ValidateSet = $null,
        [bool] $Mandatory = $false
    )

    $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $Mandatory
    $AttributesCollection.Add($ParameterAttribute)

    if ($ValidateSet) {
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
    }

    return New-Object System.Management.Automation.RuntimeDefinedParameter($Name, $Type, $AttributesCollection)
}
