# Personal overrides for Pretty PowerShell
# This file is loaded by Microsoft.PowerShell_profile.ps1.
# Keep this file local so no external repository is contacted at startup.

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	$themePath = Join-Path $PSScriptRoot "cobalt2.omp.json"
	$ompCache = Join-Path $env:TEMP "minimal_omp_init.ps1"
	if (Test-Path $themePath) {
		if (-not (Test-Path $ompCache)) {
			oh-my-posh init pwsh --config $themePath | Out-File $ompCache -Encoding utf8 -Force
		}
		. $ompCache
	}
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	$zoxideCache = Join-Path $env:TEMP "minimal_zoxide_init.ps1"
	if (-not (Test-Path $zoxideCache)) {
		zoxide init --cmd z powershell | Out-File $zoxideCache -Encoding utf8 -Force
	}
	. $zoxideCache
}

if (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
	Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

function Ensure-TerminalIcons {
	if (-not (Get-Module Terminal-Icons)) {
		Import-Module Terminal-Icons -ErrorAction SilentlyContinue
	}
}

function ff($name) {
	Get-ChildItem -Path . -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue |
		ForEach-Object { $_.FullName }
}

function libra {
	if ($env:LIBRA_TOOL_PATH) {
		$toolPath = $env:LIBRA_TOOL_PATH
	} else {
		$toolPath = @(
			"${HOME}\Desktop\Hamza\python\Libra_ft4232h_control"
			"${HOME}\Documents\Libra_ft4232h_control"
		) | Where-Object { Test-Path $_ -PathType Container } | Select-Object -First 1
	}

	if (-not $toolPath) {
		Write-Error "Libra repository not found. Set LIBRA_TOOL_PATH to its folder."
		return
	}

	$pythonPath = Join-Path $toolPath ".venv\Scripts\python.exe"
	$scriptPath = Join-Path $toolPath "ftdi_boot_reset.py"

	if (-not (Test-Path $scriptPath)) {
		Write-Error "Libra script not found: $scriptPath"
		return
	}

	if (-not (Test-Path $pythonPath)) {
		Write-Error "Libra venv not found: $pythonPath. Run: py -m venv .venv; .\.venv\Scripts\python.exe -m pip install -r requirements.txt"
		return
	}

	& $pythonPath $scriptPath @args
}

function ll {
	Ensure-TerminalIcons
	Get-ChildItem -Force | Format-Table -AutoSize
}

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

function ls {
	Ensure-TerminalIcons
	Get-ChildItem @args
}

function la {
	Ensure-TerminalIcons
	Get-ChildItem | Format-Table -AutoSize
}

function ss {
	$target = if ($args.Count -gt 0) { $args[0] } else { $null }
	$tioOptions = @($args | Select-Object -Skip 1)

	$portList = Get-CimInstance -ClassName Win32_PnPEntity |
		Where-Object { $_.Name -match '\(COM\d+\)' } |
		ForEach-Object {
			if ($_.Name -match '\((COM\d+)\)') {
				[PSCustomObject]@{
					PortName = $Matches[1]
					Description = $_.Name
				}
			}
		}

	if ([string]::IsNullOrWhiteSpace($target)) {
		if ($portList) {
			$portList | Format-Table -AutoSize -HideTableHeaders
		} else {
			Write-Host "No active COM ports found."
		}
		return
	}

	if ($target -match '^\d+$' -or $target -match '^COM\d+$') {
		if ($target -match '^\d+$') { $target = "COM$target" }
		$port = $portList | Where-Object { $_.PortName -eq $target }

		if (-not $port) {
			Write-Error "COM port '$target' was not found."
			return
		}

		Write-Host "Connecting to $target via tio ($($port.Description))"
		tio.exe -b 115200 @tioOptions $target
		return
	}

	tio.exe @tioOptions $target
}

function Show-Help {
	@"
PowerShell Profile Help
=======================
ff <name>       Findet Dateien rekursiv.
libra [options]  Startet Libra FT4232H (z. B. libra -r).
ll              Listet Dateien inklusive versteckter Dateien.
la              Listet Dateien ohne versteckte Dateien.
ss              Zeigt COM-Ports.
ss <port>       Oeffnet einen tio-Serial-Port, z. B. ss 10.
z <ordner>      Wechselt mit Zoxide in ein Verzeichnis.
Show-Help       Zeigt diese Hilfe.
"@
}
