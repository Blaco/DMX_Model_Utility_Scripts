::This is just a basic script to quickly convert a DMX model to binary encoding.

"%VGame%\bin\dmxconvert.exe" -i %1 -of dmx -oe binary -o "%~dpn1.dmx"
