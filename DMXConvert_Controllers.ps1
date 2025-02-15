# Accept files dragged onto the batch file
param (
    [Parameter(Mandatory=$true)]
    [string[]]$Files
)

# Convert the files into an array if provided as a single string
if ($Files -is [string]) {
    $Files = $Files -split "`r?`n"
}

# Validate file existence
foreach ($File in $Files) {
    if (-not (Test-Path -Path $File)) {
        Write-Host "ERROR: File '$(Split-Path $File -Leaf)' does not exist.`n"
        exit 1
    }
}

# Specify the VGame path here to override your VGame environment variable (leave empty to use the variable)
# The path *usually* points to the 'game' folder (parent folder of the bin folder)
# Example for SFM: $VGameOverride = "C:\Program Files (x86)\Steam\steamapps\common\SourceFilmmaker\game\"
# -------------------------------------------------------------------------------------------------------------
$VGameOverride = ""
# $VGameOverride = "Z:\SteamLibrary\steamapps\common\Half-Life Alyx\game\"
# -------------------------------------------------------------------------------------------------------------

function Write-Separator1 { Write-Host "---------------------------------------------------------------------" }
function Write-Separator2 { Write-Host "=====================================================================" }

# Set and validate the VGame path
$VGamePath = if ($VGameOverride -ne "") { $VGameOverride } elseif ($env:VGame) { $env:VGame } else {
    Write-Host "ERROR: No path specified for VGame. Set the environment variable or override it at the top of the script.`n"
    exit 1
} # Normalize
$VGamePathLower = $VGamePath.ToLower()

# Verify dmxconvert.exe exists in the specified VGame path
$DmxConvertPath = Join-Path -Path $VGamePath -ChildPath "bin\dmxconvert.exe"
if (-not (Test-Path -Path $DmxConvertPath)) {
    $DmxConvertPath = Join-Path -Path $VGamePath -ChildPath "bin\win64\dmxconvert.exe"
    if (-not (Test-Path -Path $DmxConvertPath)) {
        Write-Host "`nERROR: dmxconvert.exe not found in the specified VGame path:"
        Write-Host "$VGamePath"
        Write-Host "`nEnsure the path points to the 'game' directory containing the bin folder`n"
        exit 1
    }
}

# Function to verify resourcecompiler.exe exists in the same bin folder (confirms if we have the Source 2 build of dmxconvert)
$ResourceCompilerPath = Join-Path -Path $VGamePath -ChildPath "bin\resourcecompiler.exe"
$ResourceCompilerPathWin64 = Join-Path -Path $VGamePath -ChildPath "bin\win64\resourcecompiler.exe"
function Check-ResourceCompiler {
    if (-not (Test-Path -Path $ResourceCompilerPath) -and -not (Test-Path -Path $ResourceCompilerPathWin64)) {
        Write-Host "`nERROR: Detected Source 2 but resourcecompiler.exe was not found in bin or bin\win64 of Vgame path:"
        Write-Host "$VGamePath"
        Write-Host "`nEnsure the path points to the 'game' directory containing your Source 2 workshop tools`n"
        exit 1
    }
}

# List of keywords and corresponding engine detection messages
$EngineKeywords = @(
    @{ Pattern = "artifact"; Result = "Artifact (Source 2 - DMX Format 22)" },
    @{ Pattern = "deadlock"; Result = "Deadlock (Source 2 - DMX Format 22)" },
    @{ Pattern = "dota"; Result = "Dota 2 (Source 2 - DMX Format 22)" },
    @{ Pattern = "steamvr_environments"; Result = "SteamVR Home (Source 2 - DMX Format 22)" },
    @{ Pattern = "left 4 dead 2"; Result = "Left 4 Dead 2 (Source 2007 [Left 4 Dead Branch] - DMX Format 15)" },
    @{ Pattern = "left 4 dead"; Result = "Left 4 Dead (Source 2007 [Left 4 Dead Branch] - DMX Format 15)" },
    @{ Pattern = "black mesa"; Result = "Black Mesa (Source 2013 Multiplayer [Xengine] - DMX Format 1)" },
    @{ Pattern = "half-life alyx"; Result = "Half-Life: Alyx (Source 2 - DMX Format 22)" },
    @{ Pattern = "half-life 2"; Result = "Half-Life 2 (Source 2013 Singleplayer - DMX Format 1)" },
    @{ Pattern = "half-life"; Result = "Half-Life: Source (Source 2013 Singleplayer - DMX Format 1)" },
    @{ Pattern = "counter-strike source"; Result = "Counter-Strike: Source (Source 2013 Multiplayer - DMX Format 1)" },
    @{ Pattern = "source sdk base 2013 singleplayer"; Result = "Source 2013 Multiplayer - DMX Format 1)" },
    @{ Pattern = "source sdk base 2013 multiplayer"; Result = "Source 2013 Singleplayer - DMX Format 1)" },
    @{ Pattern = "team fortress 2"; Result = "Team Fortress 2 (Source 2013 Multiplayer [Team Fortress 2 Branch] - DMX Format 1)" },
    @{ Pattern = "garrysmod"; Result = "Garry's Mod (Source 2013 Multiplayer [Garry's Mod Branch] - DMX Format 1)" },
    @{ Pattern = "sourcefilmmaker"; Result = "Source Filmmaker (Alien Swarm Branch - DMX Format 18)" },
    @{ Pattern = "portal 2"; Result = "Portal 2 (Portal 2 Branch - DMX Format 18)" },
    @{ Pattern = "portal"; Result = "Portal (Source 2013 Singleplayer - DMX Format 1)" },
    @{ Pattern = "alien swarm"; Result = "Alien Swarm (Alien Swarm Branch - DMX Format 18)" },
    @{ Pattern = "titanfall 2"; Result = "Titanfall 2 (Titanfall Branch - DMX Format 18)" },
    @{ Pattern = "titanfall"; Result = "Titanfall (Titanfall Branch - DMX Format 18)" },
    @{ Pattern = "insurgency2"; Result = "Insurgency (CS:GO Branch - DMX Format 18)" },
    @{ Pattern = "entropyzero2"; Result = "Entropy: Zero 2 (Source 2013 [Mapbase] - DMX Format 1)" },
    @{ Pattern = "counter-strike global offensive"; Result = "CS:GO" } # Need to ask user if CS:GO or Counter Strike 2 (same directory name)
)

# Function to detect engine branch
function Detect-EngineBranch {
    param (
        [string]$Path,
        [array]$Keywords
    )
    foreach ($Keyword in $Keywords) {
        if ($Path -match $Keyword.Pattern) {
            # Handle special case for CS:GO
            if ($Keyword.Result -eq "CS:GO") {
                while ($true) {
                    Write-Host ""
                    Write-Host "Is this Legacy Global Offensive or Counter-Strike 2?"
                    Write-Separator1
                    Write-Host "1 - CS:GO"
                    Write-Host "2 - Counter-Strike 2"
                    $Choice = Read-Host "Enter your choice (1 or 2)"
                    switch ($Choice) {
                        "1" {
							Write-Separator1
							return "Branch: Counter-Strike: Global Offensive [Legacy] (CS:GO Branch - DMX Format 18)"
						}
                        "2" {
                            # Check for resourcecompiler.exe for Source 2
                            Check-ResourceCompiler
							Write-Separator1
                            return "Branch: Counter-Strike 2 (Source 2 - DMX Format 22)" 
                        }
                        default {
                            Write-Separator1
                            Write-Host "Invalid choice. Please enter 1 or 2."
                        }
                    }
                }
            }

            # Check for Source 2 patterns requiring resourcecompiler.exe
            if ($Keyword.Result -match "Source 2") { Check-ResourceCompiler }
            return "Branch: $($Keyword.Result)"
        }
    }
    return "Branch: it is a mystery" # 👻
}

# Detect the engine branch
$DetectedBranch = Detect-EngineBranch -Path $VGamePathLower -Keywords $EngineKeywords

# Output the detected branch
Write-Host "VGame: $VGamePath"
$DmxConvertFolder = if ($DmxConvertPath -like "*\win64\*") { "bin\win64" } else { "bin" }
Write-Host "dmxconvert.exe discovered in $DmxConvertFolder folder"
Write-Host "///"
Write-Host "$DetectedBranch"
Write-Separator1

# Function to clean up existing encoding formats in the file name
function Remove-ExistingEncoding {
	param (
		[string]$FileName,
		[array]$Encodings
	)
	# Sort encodings by length (descending) to ensure longest matches are prioritized
	$Encodings = $Encodings | Sort-Object -Descending { $_.Length }
	# Construct a regex pattern to match any of the encoding formats
	$Pattern = "(_(?:{0}))" -f ($Encodings -join "|")
	# Remove the matched encoding format (if found)
	return $FileName -replace $Pattern, ""
}

# Process each file
foreach ($File in $Files) {
	# Display file name
	Write-Host (($Files | ForEach-Object { Split-Path $_ -Leaf }) -join "`n")
    $FileContent = Get-Content $File -TotalCount 2
    $FirstLine = $FileContent[0]
    $SecondLine = $FileContent[1]
    $FileExtension = [System.IO.Path]::GetExtension($File).ToLower()
    $DisplayMessage = $null
    $OutputFormat = $null
    $NewExtension = $null

    # Case 1: SFM Elements (Presets)
    if ($FirstLine -match "binary" -and $SecondLine -match "DmePresetGroup") {
        $DisplayMessage = "Source Filmmaker Element (Binary DMX)"
        $OutputFormat = "preset"
        $NewExtension = ".pre"
        # Restore the correct file extension if it was changed (renaming the .dmx to .pre without converting it technically works in SFM)
        if ($FileExtension -eq ".pre") {
            $NewFileName = $File -replace "\.pre$", ".dmx"
            Write-Host "NOTICE: Detected Binary DMX with .pre extension. Restoring '$(Split-Path $File -Leaf)' to '$(Split-Path $NewFileName -Leaf)'."
			Write-Separator1
            Rename-Item -Path $File -NewName $NewFileName
            $File = $NewFileName
        }
        Write-Host "Input File Type: $DisplayMessage"
        Write-Separator2
        Write-Host "Choose the output behavior:"
        Write-Host "1 - Convert the original DMX files to PRE"
        Write-Host "2 - Make new PRE files and keep the original DMX files"
        Write-Separator2
    } elseif ($FirstLine -match "keyvalues2" -and $SecondLine -match "DmePresetGroup") {
        $DisplayMessage = "Source Filmmaker Element (KeyValues2 PRE)"
        $OutputFormat = "dmx"
        $NewExtension = ".dmx"
        # Restore the correct file extension if it was changed (this reverse case shouldn't appear but we will cover it anyway)
        if ($FileExtension -eq ".dmx") {
            $NewFileName = $File -replace "\.dmx$", ".pre"
            Write-Host "NOTICE: Detected KeyValues2 PRE with .dmx extension. Restoring '$(Split-Path $File -Leaf)' to '$(Split-Path $NewFileName -Leaf)'."
			Write-Separator1
            Rename-Item -Path $File -NewName $NewFileName
            $File = $NewFileName
        }
        Write-Host "Input File Type: $DisplayMessage"
        Write-Separator2
        Write-Host "Choose the output behavior:"
        Write-Host "1 - Convert the original PRE files to DMX"
        Write-Host "2 - Make new DMX files and keep the original PRE files"
        Write-Separator2
    }

    # Run dmxconvert.exe based on detected format
    if ($DisplayMessage) {
        while ($true) {
            $Choice = Read-Host "Enter your choice (1 or 2)"
            
            if ($Choice -eq "1" -or $Choice -eq "2") {
                # Set OutputFile based on user choice
                $OutputFile = $File -replace "(\.\w+)$", $NewExtension
                
                # Run the conversion command
                & $DmxConvertPath -i $File -o $OutputFile -of $OutputFormat 2>&1 | Out-Null
                
                # Check conversion success
                if (Test-Path $OutputFile) {
					Write-Separator1
                    Write-Host "Conversion complete: $(Split-Path $OutputFile -Leaf)`n"
                    
                    # Delete original file for Option 1
                    if ($Choice -eq "1") { Remove-Item -Path $File -Force }
                    
                    exit 0
                } else {
                    Write-Host "ERROR: Conversion failed for '$(Split-Path $File -Leaf)'`n"
                    exit 1
                }
            } else {
                Write-Host "Invalid choice. Please enter 1 or 2."
            }
        }
    }

    # Case 2: Source 2 Formats
    elseif ($FirstLine -match "model 22|dmx 22") {
        # Ensure we can process Source 2 formats
        Check-ResourceCompiler
        # Determine the current format and set a beautified description
        if ($FirstLine -match "keyvalues2_flat") {
            $DisplayMessage = "KeyValues2 Flat -"
            $CurrentEncode = "keyvalues2_flat"
        } elseif ($FirstLine -match "keyvalues2_noids") {
            $DisplayMessage = "KeyValues2 No IDs -"
            $CurrentEncode = "keyvalues2_noids"
        } elseif ($FirstLine -match "keyvalues2 4") {
            $DisplayMessage = "KeyValues2 -"
            $CurrentEncode = "keyvalues2"
        } elseif ($FirstLine -match "binary 9|binary_seqids") {
            $DisplayMessage = "Binary 9 - Sequenced IDs -"
            $CurrentEncode = "binary_seqids"
        } else {
            $DisplayMessage = ""
            $CurrentEncode = ""
        }
        # Extract the format and version from the header
        if ($FirstLine -match "format (\w+)\s+(\d+)") {
            $Format = $Matches[1]
            $FormatVersion = $Matches[2]
        } else {
            Write-Host "WARNING: Failed to read format from the DMX header. Assuming 'Model 22'"
            $Format = "model"
            $FormatVersion = "22"
        }
        # Beautification of format
        $Format = $Format.Substring(0, 1).ToUpper() + $Format.Substring(1).ToLower()
        # Display detected format and encoding
        Write-Host "..."
        Write-Host "Input File Type: ModelDoc DMX ($DisplayMessage $Format $FormatVersion - Source 2)"
        # Define available formats with beautified descriptions
        $AvailableEncodes = @(
            @{ Key = "keyvalues2_noids"; Display = "KeyValues2 (No IDs)" },
            @{ Key = "binary_seqids"; Display = "Binary 9 (Sequenced IDs)" },
            @{ Key = "keyvalues2"; Display = "KeyValues2" },
            @{ Key = "keyvalues2_flat"; Display = "KeyValues2 Flat" }
        )
        # Filter out the current detected format
        $Options = $AvailableEncodes | Where-Object { $_.Key -ne $CurrentEncode }
        # Prompt the user to choose the output format
        while ($true) {
            Write-Separator2
            Write-Host "Choose a format to convert to:"
            for ($i = 0; $i -lt $Options.Count; $i++) {
                Write-Host "$($i + 1) - $($Options[$i].Display)"
            }
            $Choice = Read-Host "Enter your choice (1-$($Options.Count))"
            if ($Choice -ge 1 -and $Choice -le $Options.Count) {
                $OutputFormat = $Options[$Choice - 1].Key
                $NewExtension = ".dmx"
                break
            } else {
                Write-Host "Invalid choice. Please enter a valid number between 1 and $($Options.Count)."
            }
        }
        Write-Separator2
        Write-Host "Choose the output behavior:"
        Write-Host "1 - Overwrite existing files"
        Write-Host "2 - Create new files"
        Write-Separator2
        while ($true) {
            $Choice = Read-Host "Enter your choice (1 or 2)"
            if ($Choice -eq "1" -or $Choice -eq "2") { break }
            Write-Host "Invalid choice. Please enter '1' or '2'."
        }
        # Define a list of encoding formats to handle (longest to shortest to prioritize)
        $EncodingFormats = @("binary_seqids", "keyvalues2_flat", "keyvalues2_noids", "keyvalues2", "binary")
        # Updated output file logic
        if ($Choice -eq "1") {
            $CleanedFileName = Remove-ExistingEncoding -FileName $File -Encodings $EncodingFormats
            $OutputFile = if ($File -ne $CleanedFileName) {
                # Detected existing encoding; switch to Choice 2 logic
                if ($CleanedFileName -match "(\.\w+)$") {
                    $CleanedFileName -replace "(\.\w+)$", "_$OutputFormat$NewExtension"
                } else {
                    # Handle files with no extensions gracefully
                    "$CleanedFileName_$OutputFormat$NewExtension"
                }
            } else {
                $File
            }
        } else {
            $CleanedFileName = Remove-ExistingEncoding -FileName $File -Encodings $EncodingFormats
            $OutputFile = if ($CleanedFileName -match "(\.\w+)$") {
                $CleanedFileName -replace "(\.\w+)$", "_$OutputFormat$NewExtension"
            } else {
                "$CleanedFileName_$OutputFormat$NewExtension"
            }
        }
        & $DmxConvertPath -i $File -o $OutputFile -oe $OutputFormat -of model 2>&1 | Out-Null
        if (Test-Path $OutputFile) {
            Write-Host "Conversion complete: $(Split-Path $OutputFile -Leaf)`n"
            if ($Choice -eq "1" -and $File -ne $OutputFile) {
                Remove-Item -Path $File -Force
            }
        }
        else {
            Write-Host "ERROR: Conversion failed for '$(Split-Path $File -Leaf)'`n"
        }
    }

    # Case 3: All Others
    elseif ($FirstLine -match "keyvalues2|keyvalues2_flat|binary") {
        $EncodingMatch = $Matches[0]
        # Beautify the encoding format or default to "Unknown"
        switch ($EncodingMatch) {
            "keyvalues2" { $BeautifiedEncoding = "KeyValues2" }
            "keyvalues2_flat" { $BeautifiedEncoding = "KeyValues2 Flat" }
            "binary" { $BeautifiedEncoding = "Binary" }
            default { $BeautifiedEncoding = "Unknown" }
        }
        # Extract the format from the header
        if ($FirstLine -match "format (\w+)") {
            $Format = $Matches[1]
        } else {
            Write-Host "ERROR: Could not extract format from the DMX header in '$(Split-Path $File -Leaf)'"
            continue
        }
        # Detect DMX format
        if ($FirstLine -match "model 1|dmx 1") {
            $DisplayMessage = "$BeautifiedEncoding (DMX Format 1)"
        } elseif ($FirstLine -match "model 15|dmx 15") {
            $DisplayMessage = "$BeautifiedEncoding (DMX Format 15)"
        } elseif ($FirstLine -match "model 18|dmx 18") {
            $DisplayMessage = "$BeautifiedEncoding (DMX Format 18)"
        } else {
            Write-Host "ERROR: Unsupported file format for '$(Split-Path $File -Leaf)'`n"
            continue
        }
        # Display detected format
        Write-Host "..."
        Write-Host "Input File Type: $DisplayMessage"
        # Prompt the user for the desired output format
        $Options = @("keyvalues2", "keyvalues2_flat", "binary") | Where-Object { $_ -ne $EncodingMatch }
        Write-Separator2
        Write-Host "Choose a format to convert to:"
        for ($i = 0; $i -lt $Options.Count; $i++) {
            switch ($Options[$i]) {
                "keyvalues2" { $OptionBeautified = "KeyValues2" }
                "keyvalues2_flat" { $OptionBeautified = "KeyValues2 Flat" }
                "binary" { $OptionBeautified = "Binary" }
                default { $OptionBeautified = "Unknown" }
            }
            Write-Host "$($i + 1) - $OptionBeautified"
        }
        while ($true) {
            $Choice = Read-Host "Enter your choice (1-$($Options.Count))"
            if ($Choice -ge 1 -and $Choice -le $Options.Count) {
                $OutputFormat = $Options[$Choice - 1]
                $NewExtension = ".dmx"
                break
            } else {
                Write-Host "Invalid choice. Please enter a valid number between 1 and $($Options.Count)."
            }
        }
        Write-Separator2
        Write-Host "Choose the output behavior:"
        Write-Host "1 - Overwrite existing files"
        Write-Host "2 - Create new files"
        Write-Separator2
        while ($true) {
            $Choice = Read-Host "Enter your choice (1 or 2)"
            if ($Choice -eq "1" -or $Choice -eq "2") { break }
            Write-Host "Invalid choice. Please enter '1' or '2'."
        }
        # Compute the output file name for Case 3
        $EncodingFormats = @("binary_seqids", "keyvalues2_flat", "keyvalues2_noids", "keyvalues2")
        $CleanedFileName = Remove-ExistingEncoding -FileName $File -Encodings $EncodingFormats
        if ($Choice -eq "1") {
            if ($CleanedFileName -match "(\.\w+)$") {
                $OutputFile = $CleanedFileName -replace "(\.\w+)$", "_$OutputFormat$NewExtension"
            } else {
                $OutputFile = "$CleanedFileName_$OutputFormat$NewExtension"
            }
        } else {
            if ($CleanedFileName -match "(\.\w+)$") {
                $OutputFile = $CleanedFileName -replace "(\.\w+)$", "_$OutputFormat$NewExtension"
            } else {
                $OutputFile = "$CleanedFileName_$OutputFormat$NewExtension"
            }
        }
        & $DmxConvertPath -i $File -o $OutputFile -oe $OutputFormat -of model 2>&1 | Out-Null
        if (Test-Path $OutputFile) {
            Write-Host "Conversion complete: $(Split-Path $OutputFile -Leaf)"
            if ($Choice -eq "1" -and $File -ne $OutputFile) {
                Remove-Item -Path $File -Force
            }
        } else {
            Write-Host "ERROR: Conversion failed for '$(Split-Path $File -Leaf)'"
        }
    }
}
