# Accept files dragged onto the batch file
param (
    [string]$file1,
    [string]$file2
)

# Collect files in an array for easier handling
$files = @()
if ($file1) { $files += $file1 }
if ($file2) { $files += $file2 }

# Function to check if a file is a KeyValues2 DMX file
function IsKeyValues2File {
    param ($filePath)
    $firstLine = Get-Content -Path $filePath -TotalCount 1
    return -not ($firstLine -match "keyvalues2")
}

# Hungry Pumkin only wants KeyValues2 DMX files
foreach ($file in $files) {
    if (IsKeyValues2File($file)) {
		$pumkin = @"                                                                               
%%%%%%%%%%%%%%@@:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@# : ::::: ::: : @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@%%%%%%%%%%%%%@@:@@@@@@@@@@@@@@@@@@@@@@@@@@:   =*####+.   .:::.     :=*##%%%%%%*= .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@%%%%%%%%%%%%%@@:@@@@@@@@@@@@@@@@@@@@@- .%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%= @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@%%%%%%%%%%%%%@@:@@@@@@@@@@@@@@@@@# :%%%%%%%%%%%%%%%%%%%%%%%%% :%%%%%%%%%%%%%%%%%%%%%%%% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@%%%%%%%%%%%%%@@:%: .###%%%%-:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.%%%%%%%  :%%%%%%%%%%%%%%%%%
@%%%%%%%%%%%%%@+ *####%%%%# %%%%%%%%%%%%%%% ::::::  %%%%%%%%%%%%%%%%%%%%%%% :::::::%%%%%%%%%%-%%%%%%%%  +%%%%%%%%%%%%%%%
@%%%%%%%%%%%@= #######%%% =%%%%%%%%%%%%%%%%%%=.::::::: %%%%%%%%%%%%%%%%%% ::: =#%%%%%%%%%%%%%%*%%%%%%%%%  %%%%%%%%%%%%%%
@%%%%%%%%%%@ ########%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%: ::%%%%%%%%%%%%%%%   :%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+ #*-.   %%%%%%
@%%%%%%%%@: ########%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% :-----      
%%%%%%%* ###########%%%%%%%%%%%%%%%%%%%%%%%%%#--++-.*%%%%%%%%%%%%%%%%%%%=*%%%%%%.%%%%%%%%%%%%%%%%%%%%%%%%%%%#. --:%@%%@*
%%%%%% -##########%%%%%%%%%%%%%%%%%%%%%%%%+%%%%%%%%%%%%+%%%%%%%%%%%%%%%%%-    :%%%:%%%%%%%%%%%%%%%%%%%%%%%%%%#: -.@.*@@@
@%%%@ ############%%%%%%%%%%%%%%%%%%%%%%%%%:@*=:   == %%%%%%%%%%%%%%%%+@@*     *#%=%%%%%%%%%%%%%%%%%%%%%%%%%%##.  @@@@@@
@%%@ #############%%%%%%%%%%%%%%%%%%%%%%% @@      @  .@@ %%%%%%%%%%%%*@#+     @ +%@@*%%%%%%%%%%%%%%%%%%%%%%%%%## %@@@@@@
@%%*##############%%%%%%%%%%%%%%%%%%%%%%=@@@*        =@@@.%%%%%%%%%%%.@::       ==@@=%%%%%%%%%%%%%%%%%%%%%%%%#%#% @@@@@@
@%@:#############%%%%%%%%%%%%%%%%%%%%%%%%%:@        =:@:%%%%%%%%%%%%%%%::      :.% %%%%%%%%%%%%%%%%%%%%%%%%%%#%##+ @.-@@
@@*##############%%%%%%%%%%%%%%%%%%%%%%%%%%% :*   := *%%%%%%%%%%%%%%%%%%%%%%+--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%### %@@%%
%@ ##############%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####*.@%%%
@ ###############%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#####+:.%%
% ###############%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%######%.-- 
@ ################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=%%%%%%%%%%%%%%%%%%%%%%% .%%%%%%%%%%%%%%%%%%%%%%.%%%%%%%%%#####% ---
@ #*##############%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*%%%%%%%%%%%%%%%%%%%%%%%*%-#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%######## :::
@ ##*#####- .*#####%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%*.:==::%%%%%%%%%%#.%%%%%%%%%%%%%%%%%%%%%%%%%%%+%%%%%%%%#%######   :
@ #*#### ..:: #####%%%%%%%:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.%%%%%%  .  +###### @ :
@ #**#* ::::: ######%%%%%%:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*%%%%%%%% ::::: ##### @ :
@@ #*# :::::: =#####%%%%%%%%%:+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%* :::::. ###-@@ :
@@=:*#  :::::. ######%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% .:::::. ### @@ :
@@@ *# .:::::: #######%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+ .::::::::::::::-----:+%%%%%%%%%%%%%%%%%%%%%%%%% :::::: ### @@@@@
@@@@  .:::::::.#######%%%%%%%%%%%%%%%%%%%%%%%%%%%* ...:::::::::::::::::------:.  %*%%%%%%%%%%%%%%%%%%%#.::::::: # #@@@@@
@@@@ .::::::::::#########%%%%%%%%%%%%%%%%%%%%%=%%%%%%%%%* .::::::::::::::.#%%%%%%%.%%%%%%%%%%%%%%%%%%% ::::::::: +@@@@@@
@@@+ :::::::::: =#########%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+===+#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#:.:::::::::: %@@@@@
@@@ :::::::::: = +########%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=.:*%%%#+=%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%-   :::::::::: %@@@@
"@
        Write-Host $pumkin
        Write-Host "`n NO!"
        Start-Sleep -Milliseconds 600
        $message1 = "`n I DON'T WANT THAT!`n"
        Write-Host -NoNewline " "
        foreach ($char in $message1.ToCharArray()) {
            Write-Host -NoNewline $char
            Start-Sleep -Milliseconds 125 }
        Write-Host ""
        Write-Host -NoNewline " ."
        Start-Sleep -Milliseconds 600
        for ($i = 2; $i -le 4; $i++) {
            Write-Host -NoNewline "."
            Start-Sleep -Milliseconds 600 }
        Start-Sleep -Milliseconds 300
        $message2 = "`n GIVE ME THE KEYVALUES...`n"
        Write-Host -NoNewline "`n "
        foreach ($char in $message2.ToCharArray()) {
            Write-Host -NoNewline $char
            Start-Sleep -Milliseconds 125 }
        Write-Host ""
        exit
    }
}

# Function to identify if a file is stripped (has no controllers) or filled (a controller source)
function IsFilledFile($filePath) {
    $content = Get-Content -Path $filePath -Raw
    # Check for data in "controls" and "dominators" arrays
    $controlsPattern = '"controls"\s+"element_array"\s*\[(.*?)\]'
    $dominatorsPattern = '"dominators"\s+"element_array"\s*\[(.*?)\]'
    $controlsMatch = [regex]::Match($content, $controlsPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $dominatorsMatch = [regex]::Match($content, $dominatorsPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # If there’s content in either array, assume this is the filled file
    return ($controlsMatch.Groups[1].Value.Trim() -ne "" -or $dominatorsMatch.Groups[1].Value.Trim() -ne "")
}

# Ensure "dominators" array is present in stripped file, insert it if not
function EnsureDominatorsArrayExists {
    param ($filePath)

    $content = Get-Content -Path $filePath -Raw

    # Correct patterns to match "dominators" and "targets"
    $dominatorsPattern = '(?m)^\s*"dominators"\s+"element_array"\s*\['
    $targetsPattern = '(?m)^\s*"targets"\s+"element_array"'

    # Check if "dominators" array is missing and "targets" array exists
    if (($content -notmatch $dominatorsPattern) -and ($content -match $targetsPattern)) {
        # Find the position of "targets" "element_array" in the content
        $targetsMatch = [regex]::Match($content, $targetsPattern)
        $insertPosition = $targetsMatch.Index

        # Define the "dominators" array
        $dominatorsArrayText = @"
		"dominators" "element_array"
		[
		]

"@
        # Insert the "dominators" array above "targets" "element_array"
        $content = $content.Insert($insertPosition, $dominatorsArrayText)

        # Save the modified content back to the file
        Set-Content -Path $filePath -Value $content -Force

		Write-Output "Inserted missing 'dominators' array in $([System.IO.Path]::GetFileName($filePath))."
    }
}

# If two files are provided, automatically assign based on content
if ($files.Count -eq 2) {
    $file1IsFilled = IsFilledFile $files[0]
    $file2IsFilled = IsFilledFile $files[1]

    if ($file1IsFilled -and -not $file2IsFilled) {
        $filledFile = $files[0]
        $strippedFile = $files[1]
    } elseif ($file2IsFilled -and -not $file1IsFilled) {
        $filledFile = $files[1]
        $strippedFile = $files[0]
    } elseif ($file1IsFilled -and $file2IsFilled) {
        Write-Host "`r`nWARNING: Both files appear to contain controller data.`r`n"
        Write-Host "-------------------------------------------------------------------------------------------------------------"
        Write-Host "Please specify which file you are transferring controllers to:`r`n"
        Write-Output "1 - $([System.IO.Path]::GetFileName($files[0]))"
        Write-Output "2 - $([System.IO.Path]::GetFileName($files[1]))`r`n"
        
        # Loop until a valid choice is entered
        $validInput = $false
        do {
            $choice = Read-Host "Enter your choice"
            if ($choice -eq "1") {
                $filledFile = $files[1]
                $strippedFile = $files[0]
                $validInput = $true
            } elseif ($choice -eq "2") {
                $filledFile = $files[0]
                $strippedFile = $files[1]
                $validInput = $true
            } else {
                Write-Host "-------------------------------------------------------------------------------------------------------------"
                Write-Host "ERROR: Invalid Entry // Type 1 or 2"
                Write-Host "-------------------------------------------------------------------------------------------------------------"
            }
        } until ($validInput)
        Write-Host "-------------------------------------------------------------------------------------------------------------"
    } elseif (-not $file1IsFilled -and -not $file2IsFilled) {
        Write-Host "`r`nERROR: Both files appear to be stripped. Please provide one file with controller data.`r`n"
        exit
    }

    # Ensure the "dominators" array exists in the stripped file if needed
    EnsureDominatorsArrayExists $strippedFile

    Write-Host "Controller source and stripped DMX identified. Data extraction will proceed."
    Write-Host "-------------------------------------------------------------------------------------------------------------"

# If only one file is provided, determine if it’s filled or stripped and prompt for the other file
} elseif ($files.Count -eq 1) {
    $warningShown = $false  # Flag to track if warning message has been shown
    if (IsFilledFile $files[0]) {
        $filledFile = $files[0]
        # Loop to prompt until a valid stripped file is provided
        do {
            Write-Host "`r`nController source detected. Specify the stripped DMX file (e.g., 'model_stripped.dmx'):"
            $strippedFileInput = Read-Host
            $strippedFile = if ($strippedFileInput) { Join-Path -Path (Get-Location) -ChildPath $strippedFileInput }
            Write-Host "-------------------------------------------------------------------------------------------------------------"
            if (![string]::IsNullOrWhiteSpace($strippedFileInput) -and (Test-Path $strippedFile)) {
                if (IsKeyValues2File $strippedFile) {
                    $validInput = $false
                    Write-Host "ERROR: The specified DMX file is not encoded in KeyValues2 format. Please convert it with DMXconvert first."
                    Write-Host "-------------------------------------------------------------------------------------------------------------"
                } else {
                    $validInput = $true
                    if (IsFilledFile $strippedFile) {
                        Write-Host "WARNING: The specified file appears to contain existing controller data! This will be overridden!!!"
                        Write-Host "-------------------------------------------------------------------------------------------------------------"
                        $warningShown = $true
                    }
                    # Ensure the "dominators" array exists in the stripped file
                    EnsureDominatorsArrayExists $strippedFile
                }
            } else {
                Write-Host "ERROR: Stripped DMX file not found or invalid input. Please try again."
                Write-Host "-------------------------------------------------------------------------------------------------------------"
                $validInput = $false
            }
        } until ($validInput)
    } else {
        $strippedFile = $files[0]
        # Ensure the "dominators" array exists in the stripped file
        EnsureDominatorsArrayExists $strippedFile
        # Loop to prompt until a valid filled file is provided
        do {
            Write-Host "`r`nStripped DMX file detected. Specify the controller source (e.g., 'controllers.txt' or 'model.dmx'):"
            $filledFileInput = Read-Host
            $filledFile = if ($filledFileInput) { Join-Path -Path (Get-Location) -ChildPath $filledFileInput }
            Write-Host "-------------------------------------------------------------------------------------------------------------"
            if (![string]::IsNullOrWhiteSpace($filledFileInput) -and (Test-Path $filledFile)) {
                if (IsKeyValues2File $filledFile) {
                    $validInput = $false
                    Write-Host "ERROR: The specified DMX file is not encoded in KeyValues2 format. Please convert it with DMXconvert first."
                    Write-Host "-------------------------------------------------------------------------------------------------------------"
                } else {
                    $validInput = $true
                }
            } else {
                Write-Host "ERROR: Controller file not found or invalid input. Please try again."
                Write-Host "-------------------------------------------------------------------------------------------------------------"
                $validInput = $false
            }
        } until ($validInput)
    }
    # Display confirmation message only if no warning was shown
    if (-not $warningShown) {
        Write-Host "Controller source and stripped DMX identified. Data extraction will proceed."
        Write-Host "-------------------------------------------------------------------------------------------------------------"
    }
}

# Display the names of the stripped and filled files
Write-Output "Controller Source:   $([System.IO.Path]::GetFileName($filledFile))"
Write-Output ("Transferring To:     $([System.IO.Path]::GetFileName($strippedFile))" + ($(if ($warningShown) { " [NOT STRIPPED]" } else { "" })))
Write-Host "-------------------------------------------------------------------------------------------------------------"

# Prompt user for behavior option
$validChoice = $false
while (-not $validChoice) {
	Write-Host "Choose the output behavior:`r`n"
	Write-Host "1 - Create a new 'filled' file"
	Write-Host "2 - Overwrite the 'stripped' file with a 'filled' file"
	Write-Host "3 - Overwrite the original DMX file and keep the 'stripped' file"
	Write-Host "4 - Overwrite the original DMX file and delete the 'stripped' file`r`n"
    $option = Read-Host "Enter your choice"
	Write-Host "-------------------------------------------------------------------------------------------------------------"
    
    switch ($option) {
		"1" {
			# For option 1, transfer controllers to a new copy of the file and name it "_filled"
			$baseName = [System.IO.Path]::GetFileNameWithoutExtension($strippedFile) -replace '_stripped$', ''
			$extension = [System.IO.Path]::GetExtension($strippedFile)
			$outputFilePath = Join-Path -Path (Get-Item $strippedFile).DirectoryName -ChildPath ("${baseName}_filled${extension}")
			
			# Check if the target file already exists
			if (Test-Path $outputFilePath) {
				Write-Output "WARNING: A file with the name '$outputFilePath' already exists."
				Write-Host "Would you like to overwrite it? (Y/N)"
				$overwriteChoice = Read-Host
				if ($overwriteChoice -ieq "Y") {
					Remove-Item -Path $outputFilePath -Force
					Write-Host "Existing file deleted. Proceeding with creation."
				} else {
					$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm"
					$outputFilePath = Join-Path -Path (Get-Item $strippedFile).DirectoryName -ChildPath ("${baseName}_filled_$timestamp${extension}")
					Write-Output "Saving as '$outputFilePath' to avoid conflict."
				}
			}
			$validChoice = $true
		}

		"2" {
			# For option 2, transfer controllers to the stripped file then rename it to "_filled"
			$outputFilePath = $strippedFile  # Process content first
			$renameFile = $true
			$newFilePath = Join-Path -Path (Get-Item $strippedFile).DirectoryName -ChildPath "$(([System.IO.Path]::GetFileNameWithoutExtension($strippedFile) -replace '_stripped$', '_filled'))$([System.IO.Path]::GetExtension($strippedFile))"
			
			# Check if the target file already exists
			if (Test-Path $newFilePath) {
				Write-Output "WARNING: A file with the name '$newFilePath' already exists."
				Write-Host "Would you like to overwrite it? (Y/N)"
				$overwriteChoice = Read-Host
				if ($overwriteChoice -ieq "Y") {
					Remove-Item -Path $newFilePath -Force
					Write-Host "Existing file deleted. Proceeding with rename."
				} else {
					$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm"
					$newFilePath = Join-Path -Path (Get-Item $strippedFile).DirectoryName -ChildPath "$(([System.IO.Path]::GetFileNameWithoutExtension($strippedFile) -replace '_stripped$', "_filled_$timestamp"))$([System.IO.Path]::GetExtension($strippedFile))"
					Write-Output "Renaming to '$newFilePath' to avoid conflict."
				}
			}
			$validChoice = $true
		}

		"3" {
			# For option 3, transfer controllers to the original DMX file, keep the "_stripped" file
			$baseName = [System.IO.Path]::GetFileNameWithoutExtension($strippedFile) -replace '_stripped$', ''
			$extension = [System.IO.Path]::GetExtension($strippedFile)
			$originalFilePath = Join-Path -Path (Get-Item $strippedFile).DirectoryName -ChildPath ("$baseName$extension")

			Write-Host "WARNING: This will overwrite the original unstripped file! Press 'B' to go back to selection or Enter to continue."
			Write-Host "-------------------------------------------------------------------------------------------------------------"

			# Capture user input to decide whether to proceed or go back
			$confirmation = Read-Host "Press Enter to continue or 'B' to go back to selection"

			if ($confirmation -ieq "B") {
				Write-Host "-------------------------------------------------------------------------------------------------------------"
				$validChoice = $false  # Reset valid choice to re-display options
				continue  # Go back to the behavior selection loop
			} elseif ($confirmation -eq "") {
				Write-Host "-------------------------------------------------------------------------------------------------------------"
				# Proceed if the user pressed Enter without entering 'B'
				$deleteStrippedFile = $false
				$outputFilePath = $originalFilePath
				$validChoice = $true
			} else {
				Write-Host "Invalid input. Please press 'B' to go back or Enter to continue."
				$validChoice = $false  # Remain in the selection loop
			}
		}
		"4" {
			# For option 4, transfer controllers to the original DMX file, delete the "_stripped" file
			$baseName = [System.IO.Path]::GetFileNameWithoutExtension($strippedFile) -replace '_stripped$', ''
			$extension = [System.IO.Path]::GetExtension($strippedFile)
			$originalFilePath = Join-Path -Path (Get-Item $strippedFile).DirectoryName -ChildPath ("$baseName$extension")

			Write-Host "WARNING: This will overwrite the original unstripped file! Press 'B' to go back to selection or Enter to continue."
			Write-Host "-------------------------------------------------------------------------------------------------------------"

			# Capture user input to decide whether to proceed or go back
			$confirmation = Read-Host "Press Enter to continue or 'B' to go back to selection"

			if ($confirmation -ieq "B") {
				Write-Host "-------------------------------------------------------------------------------------------------------------"
				$validChoice = $false  # Reset valid choice to re-display options
				continue  # Go back to the behavior selection loop
			} elseif ($confirmation -eq "") {
				# Proceed if the user pressed Enter without entering 'B'
				Write-Host "-------------------------------------------------------------------------------------------------------------"
				$deleteStrippedFile = $true
				$outputFilePath = $originalFilePath
				$validChoice = $true
			} else {
				Write-Host "Invalid input. Please press 'B' to go back or Enter to continue."
				$validChoice = $false  # Remain in the selection loop
			}
		}
    }
}

# Read content of the specified files
try {
    $filledContent = Get-Content -Path $filledFile -Raw
    $strippedContent = Get-Content -Path $strippedFile -Raw
	Write-Host "Files loaded successfully. Processing..."
	Write-Host "-------------------------------------------------------------------------------------------------------------"
} catch {
	Write-Host "ERROR reading files. Ensure they exist, are accessible, and not locked by other processes."
	Write-Host "-------------------------------------------------------------------------------------------------------------"
    pause
    exit
}

# Function to extract array content with nested bracket handling
function ExtractNestedArrayContent {
    param ($content, $arrayName)
    $startPattern = "$arrayName\s+""element_array""\s*\["
    $startMatch = [regex]::Match($content, $startPattern)
    if (!$startMatch.Success) { throw "$arrayName array not found in filled file." }
    $startIndex = $startMatch.Index + $startMatch.Length
    $bracketLevel = 1
    $arrayContent = ""
    for ($i = $startIndex; $i -lt $content.Length; $i++) {
        $char = $content[$i]
        $arrayContent += $char
        if ($char -eq '[') { $bracketLevel++ }
        elseif ($char -eq ']') { $bracketLevel-- }
        if ($bracketLevel -eq 0) { break }
    }
    return $arrayContent.TrimEnd()
}

# Extract "controls" and "dominators" array data from the filled file
try {
    $controlsData = ExtractNestedArrayContent -content $filledContent -arrayName '"controls"'
    $dominatorsData = ExtractNestedArrayContent -content $filledContent -arrayName '"dominators"'
} catch {
	Write-Output "ERROR during array extraction: $_"
	Write-Host "-------------------------------------------------------------------------------------------------------------"
    pause
    exit
}

# Indentation and replacement
$indentedControlsData = "`t`t`t" + ($controlsData -replace "^\s*([^\r\n]+)", '$1').TrimEnd()
$indentedDominatorsData = "`t`t`t" + ($dominatorsData -replace "^\s*([^\r\n]+)", '$1').TrimEnd()
$strippedContent = [regex]::Replace(
    $strippedContent,
    '("controls"\s+"element_array"\s+\[)(.*?)(\])',
    "`$1`r`n$indentedControlsData",
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
$strippedContent = [regex]::Replace(
    $strippedContent,
    '("dominators"\s+"element_array"\s+\[)(.*?)(\])',
    "`$1`r`n$indentedDominatorsData",
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# Save the modified content to the determined output path
try {
    $strippedContent.TrimEnd() + "`r`n" | Set-Content -Path $outputFilePath

    # Rename operations for option 2, 3, and 4
    if ($renameFile -eq $true) {
		Rename-Item -Path $outputFilePath -NewName $newFilePath -Force
		Write-Output "Data transfer complete. File saved as: $newFilePath"
		Write-Host "-------------------------------------------------------------------------------------------------------------"
    } elseif ($option -eq "3" -or $option -eq "4") {
        Rename-Item -Path $outputFilePath -NewName $originalFilePath -Force
		Write-Output "Data transfer complete. File saved as: $originalFilePath"
		Write-Host "-------------------------------------------------------------------------------------------------------------"
        if ($deleteStrippedFile -and (Test-Path $strippedFile)) {
            Remove-Item -Path $strippedFile -Force
        }
    } else {
		Write-Output "Data transfer complete. File saved as: $outputFilePath"
		Write-Host "-------------------------------------------------------------------------------------------------------------"
    }
} catch {
    Write-Output "ERROR during file saving/renaming process: $_"
	Write-Host "-------------------------------------------------------------------------------------------------------------"
    pause
    exit
}
