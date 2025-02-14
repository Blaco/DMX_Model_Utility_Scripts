# DMX_KV2_Controller_Tools
Powershell scripts to automate the processing of Source 1 DMX files. \
These scripts automatically remove or transfer flex controller and dominator rule datablocks in KeyValues2 DMX files. \

An additional script utilizes the Dmxconvert command line tool, automatically detecting your Source 1 (or 2) branch and the format of your provided DMX files in order to provide options in a GUI interface that simply allow you to choose what format you wish to convert to without the need for manual specification of the tool's required parameters. \

*Just drag and drop your DMX files on to the script and select what you want Dmxconvert to do.*

## DMXConvert_Controllers.ps1
Provides an automated interface for using Dmxconvert without the need for command line parameters or batch files
Currently only supports processing one file at a time.

1. Drag a DMX file on to the batch file, the tool will check your VGame path to determine your Dmxconvert.exe capabilities \
   *If your VGame environment variable is not set right, you can manually override it at the top of the Powershell script
2. The script will automatically detect your Source Engine branch and DMX file encoding and give you specific options to choose from \
   *The script also will detect if you gave it a SFM Preset .pre file that was not converted properly, and offer to fix it for you
3. Choose the new encoding format you want to convert to, and choose to output to a new file or overwrite the original
4. The script will run Dmxconvert.exe according to your input, and save the output

## Remove_Controllers.ps1
Strips all flex controllers and flex dominator rules out of a KeyValues 2 DMX file. \
The primary purpose of this script is to prepare a DMX file for controller injection from another source, via Transfer_Controllers.ps1

1.  Drag a KeyValues2 DMX file onto the batch file to remove its embedded controllers and dominators
2.  The script will save the new version of the file with _stripped appended to the name

## Transfer_Controllers.ps1
Transfers flex controller and dominator data from one data source to another \
The source can be another KeyValues2 DMX file, or any raw text file (such as Blender generated controller files)

1.  Drag a stripped DMX file, controller source, or both on the batch file to begin \
    *If only one file was provided, identify the other file for the script to use
2. The script will automatically decide which is the transfer source and which is the stripped file
3. Choose one of the four available options to determine file output behaviour
4. The script will then transfer the controllers from the source file to the stripped file, and save the output

## Links
- [Valve Developer Wiki - DMX Format](https://developer.valvesoftware.com/wiki/DMX)
- [Valve Developer Wiki - Dmxconvert](https://developer.valvesoftware.com/wiki/Dmxconvert)
- [Valve Developer Wiki - Flex Animation](https://developer.valvesoftware.com/wiki/Flex_animation#DMX_format)
