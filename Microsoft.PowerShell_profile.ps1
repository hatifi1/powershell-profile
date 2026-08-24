### Minimal local PowerShell profile

$CustomProfile = Join-Path (Split-Path $PROFILE) "Profile.ps1"
if (Test-Path $CustomProfile) {
    . $CustomProfile
}
