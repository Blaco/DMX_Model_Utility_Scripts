# Define input and output file paths
param (
    [string]$inputFilePath
)

# Hungry Pumkin does not want Binary DMX files
$firstLine = Get-Content -Path $inputFilePath -TotalCount 1
if ($firstLine -match "binary") {
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

# Get the file name without extension and the extension separately
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($inputFilePath)
$fileExtension = [System.IO.Path]::GetExtension($inputFilePath)

# Define the output file path with "_stripped" appended before the extension
$outputFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($inputFilePath), $filenameWithoutExtension + "_stripped" + $fileExtension)

# Check if input file exists
if (!(Test-Path -Path $inputFilePath)) {
    Write-Output "File not found: $inputFilePath"
    exit
}

# Open file streams for reading and writing
$inputStream = [System.IO.StreamReader]::new($inputFilePath)
$outputStream = [System.IO.StreamWriter]::new($outputFilePath)

# Initialize state variables
$insideTargetArray = $false
$insideTargetBlock = $false
$bracketLevel = 0

# Variables to capture name information and counters
$currentName = ""
$currentDominator = ""
$currentSuppressed = ""
$flexControllerCount = 0
$dominatorRuleCount = 0
$separatorPrinted = $false  	# Flag to control single separator printing

# Timer for inactivity messages
$lastMessageTime = [datetime]::Now
$inactivityCheckEnabled = $true
$iterationCounter = 0 			# Counter for loop iterations
$checkFrequency = 100  			# Perform inactivity check only once every 100 iterations for performance

# Initial output acknowledging the file being worked on
Write-Host "-------------------------------------------------------------------------------------------------------------"
Write-Host "Processing file: $inputFilePath"
Write-Host "-------------------------------------------------------------------------------------------------------------"

# Function to handle final cleanup and reporting
function Finalize-Script {
    param (
        [int]$FlexControllerCount,
        [int]$DominatorRuleCount,
        [string]$OutputFilePath,
        [System.IO.StreamReader]$InputStream,
        [System.IO.StreamWriter]$OutputStream
    )

    # Close file streams
    if ($InputStream) { $InputStream.Close() }
    if ($OutputStream) { $OutputStream.Close() }

    # Reporting logic
    if ($FlexControllerCount -eq 0 -and $DominatorRuleCount -eq 0) {
        Write-Host "Nothing found to remove!"
        Write-Host "Either this DMX file was already stripped or you somehow snuck a Binary DMX file past the Pumkin??..."
    } else {
        Write-Host "-------------------------------------------------------------------------------------------------------------"
        Write-Host "Removal complete. Output saved to $( [System.IO.Path]::GetFileName($OutputFilePath) )"
        Write-Host "-------------------------------------------------------------------------------------------------------------"
        Write-Output "Total flex controllers removed: $FlexControllerCount"
        Write-Output "Total dominator rules removed: $DominatorRuleCount"
        Write-Host "-------------------------------------------------------------------------------------------------------------"
    }

    # Exit the script
    exit
}

while (($line = $inputStream.ReadLine()) -ne $null) {
    # Increment the iteration counter
    $iterationCounter++

	# Break the loop and finish when no activity has been detected for 2 seconds
	if ($inactivityCheckEnabled -and $iterationCounter % $checkFrequency -eq 0) {
		if (([datetime]::Now - $lastMessageTime).TotalSeconds -ge 2) {

			# Write the current line to ensure no data is skipped
			$outputStream.WriteLine($line)

			# Align stream position and read all remaining lines in bulk
			$remainingLines = $inputStream.ReadToEnd()
			
			# Validate and clean up remaining lines
			if ($remainingLines -ne "") {
				$remainingLines = $remainingLines.TrimStart("`n", "`r").TrimEnd("`n", "`r")  # Remove extra newlines
				$outputStream.Write($remainingLines)
			}

            # Finalize and exit
            Finalize-Script -FlexControllerCount $flexControllerCount -DominatorRuleCount $dominatorRuleCount -OutputFilePath $outputFilePath -InputStream $inputStream -OutputStream $outputStream
        }
	}

    # Detect start of the target arrays ("controls" or "dominators") containing element_array
    if ($line -match '"controls" "element_array"') {
        $insideTargetArray = "controls"
        $outputStream.WriteLine($line)  		# Write the array header line
        $outputStream.WriteLine("        [")  	# Write the opening bracket for the array with double indentation
        $lastMessageTime = [datetime]::Now  	# Reset timer because significant work is happening
        $inactivityCheckEnabled = $true  		# Re-enable inactivity checks
        continue
    } elseif ($line -match '"dominators" "element_array"') {
        $insideTargetArray = "dominators"
        $outputStream.WriteLine($line)  		# Write the array header line
        $outputStream.WriteLine("        [")  	# Write the opening bracket for the array with double indentation
        $lastMessageTime = [datetime]::Now  	# Reset timer because significant work is happening
        $inactivityCheckEnabled = $true  		# Re-enable inactivity checks
        continue
    }

    # If inside the target array, check for start and end of blocks to remove
    if ($insideTargetArray) {
        # Detect start of a block to remove
        if ($line -match '"DmeCombinationInputControl"') {
            $insideTargetBlock = "DmeCombinationInputControl"
            $bracketLevel = 0  					# Reset bracket level for nested tracking
            $lastMessageTime = [datetime]::Now  # Reset timer because significant work is happening
            $inactivityCheckEnabled = $true  	# Re-enable inactivity checks
            continue
        } elseif ($line -match '"DmeCombinationDominationRule"') {
            # Print separator if it hasn't been printed after flex controllers
            if (-not $separatorPrinted -and $flexControllerCount -gt 0) {
                Write-Host "-------------------------------------------------------------------------------------------------------------"
                $separatorPrinted = $true  		# Ensure this only prints once
            }
            $insideTargetBlock = "DmeCombinationDominationRule"
            $bracketLevel = 0  					# Reset bracket level for nested tracking
            $lastMessageTime = [datetime]::Now  # Reset timer because significant work is happening
            $inactivityCheckEnabled = $true  	# Re-enable inactivity checks
            continue
        }

        # Track nested brackets within the target block to identify its end
        if ($insideTargetBlock) {
            # Capture "name" values for reporting
            if ($insideTargetBlock -eq "DmeCombinationInputControl" -and $line -match '"name" "string" "(.*)"') {
                $currentName = $matches[1]
                $flexControllerCount++
                Write-Output "Removing flex controller: $currentName"
                $lastMessageTime = [datetime]::Now  # Reset timer because significant work is happening
                $inactivityCheckEnabled = $true  	# Re-enable inactivity checks
            } elseif ($insideTargetBlock -eq "DmeCombinationDominationRule") {
                # Capture "name" or "dominators" and "suppressed" values for DmeCombinationDominationRule
                if ($line -match '"name" "string" "(.*)"') {
                    $currentName = $matches[1]
                }
                # Capture each item in "dominators" or "suppressed" array until closing bracket
                elseif ($line -match '"dominators" "string_array"') {
                    $currentDominator = $inputStream.ReadLine().Trim(" []`"").Trim()
                    while (($arrayLine = $inputStream.ReadLine().Trim()) -notmatch '^\]') {
                        $currentDominator += $arrayLine.Trim(" ", "`"").Trim() + ", "
                    }
                    $currentDominator = $currentDominator.TrimEnd(", ")  # Remove trailing comma
                } elseif ($line -match '"suppressed" "string_array"') {
                    $currentSuppressed = $inputStream.ReadLine().Trim(" []`"").Trim()
                    while (($arrayLine = $inputStream.ReadLine().Trim()) -notmatch '^\]') {
                        $currentSuppressed += $arrayLine.Trim(" ", "`"").Trim() + ", "
                    }
                    $currentSuppressed = $currentSuppressed.TrimEnd(", ")  # Remove trailing comma
                    $dominatorRuleCount++
                    Write-Output "Removing dominator rule: $currentDominator suppressing $currentSuppressed"
                    $lastMessageTime = [datetime]::Now  # Reset timer because significant work is happening
                    $inactivityCheckEnabled = $true  	# Re-enable inactivity checks
                }
            }
            # Update bracket level for nested structures
            if ($line -match '^\s*\{') { $bracketLevel++ }
            if ($line -match '^\s*\}') { $bracketLevel-- }
            # Exit block when reaching the matching closing bracket
            if ($bracketLevel -eq 0) {
                # Reset block-specific variables
                $insideTargetBlock = $false
                $currentName = ""
                $currentDominator = ""
                $currentSuppressed = ""
            }
            continue  # Skip lines inside the target block
        }

        # Detect the end of the target array and write the closing bracket only once
        if ($line -match '^\s*\]') {
            $outputStream.WriteLine("        ]")  	# Write only the closing bracket for an empty array with double indentation
            $insideTargetArray = $false  			# Exit the array
            $lastMessageTime = [datetime]::Now  	# Reset timer because significant work is happening
            $inactivityCheckEnabled = $true  		# Re-enable inactivity checks
        }
        continue
    }

    # Write lines outside of the target arrays
    $outputStream.WriteLine($line)
}

# Fallback to finalize in case inactivity check is skipped
Finalize-Script -FlexControllerCount $flexControllerCount -DominatorRuleCount $dominatorRuleCount -OutputFilePath $outputFilePath -InputStream $inputStream -OutputStream $outputStream