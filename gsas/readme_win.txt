GSAS for Windows 95/98/NT/2000 Distribution kit

You should have a self-extracting executable file, gsaskit.exe, containing 
the distribution materials for GSAS and at least 41Mb of free disk space. 

REVISED 03/31/05 for new Windows version of GSAS with PGPLOT graphics.
I will assume in the following that your computer has a single hard disk C:, 
use a different disk designations if needed.

To install GSAS:

1. Double click on gsaskit.exe to execute it. The gsas files will be unzipped.
You will be asked for the location of gsas; you may put it anywhere but for easiest 
installation please put it in the default location (C:\gsas). Alternatively, use a 
different drive letter as X:\gsas (X = any disk); however in this case you must 
modify the file gsas\exe\pc-gsas.bat for that choice of disk drive. GSAS can be 
installed in some other subdirectory but pc-gsas.bat must be modified to reflect this.
pc-gsas.bat contains the following lines:

echo off
if "%gsas%" == "" set gsas=c:\gsas
set PGPLOT_FONT=%gsas%\pgl\grfont.dat
if NOT "%OS%" == "" (if %2==noname (title %1) else (title %1 %2))
cd %3
"%gsas%\exe\%1.exe" %2
pause

modify only the second line to reflect the changed disk drive letter.

2. GSAS is now ready to use from pc-gsas.exe. You no longer need to modify the 
autoexec.bat file (Win95/98/ME) or reboot the computer. For WinNT/2K/XP, you also 
no longer need to modify the environment variables.
3. (WIN95/98/ME/NT40/2000) create a shortcut to pc-gsas.exe and move it to the desktop. 
You may have to modify the properties of this file if you installed gsas anywhere 
else other than C:\gsas.
4. If you use GSAS in batch files modify them to include the following lines before 
any gsas program is invoked:

if "%gsas%" == "" set gsas=c:\gsas
set PGPLOT_FONT=%gsas%\pgl\grfont.dat

These are copied directly from the pc-gsas.bat file; perhaps as modified with different 
drive letter. Also change any of the gsas program names you may use to reflect the 
full path to their location including the ".exe". E.g. change "expedt" to 
"c:\gsas\exe\expedt.exe". This will ensure correct execution and that the opening 
banner will show the correct "Distribution Date".

5. WinNT4.0 & Win2000: To register the GSAS experiment file (optional):
	a. in Windows Explorer select "Tools" and then "Folder Options"
	b. select "file types"
	c. select "new type"
        d. enter "EXP" for File Extension; click "OK"
        e. click "advanced"
	f. select "change icon"
	g. select "browse" and find C:\GSAS\GSAS.ICO
	h. select "OK" (for icon)
	i. for description of type enter: GSAS experiment file
        j. select "new"
	k. for action enter: Expedt
	l. for application enter: C:\GSAS\EXE\PC-GSAS.BAT EXPEDT "%1"
	m. repeat j-l for POWPREF, GENLES, POWPLOT, etc. as desired
	n. select "OK" to finish
A similar scheme exists for Win95/98/ME. Now you will be able to "right click" 
on an experiment file and select the GSAS routine you want to use. Moreover, 
the window for each program will stay open after it completes so you may 
examine the result.

	


