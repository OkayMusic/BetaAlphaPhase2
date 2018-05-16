#!/usr/bin/env python
'''
*makeMacApp: Create Mac Applet*
===============================

This script creates an AppleScript app to launch EXPGUI. The app is
created in the main directory where the GSAS files are located.

Run this script with one optional argument, the path to the expgui file.
The script path may be specified relative to the current path or given
an absolute path, but will be converted to an absolute path. 
If no arguments are supplied, this script will look for file
expgui in the same directory as this file.

'''
import sys, os, os.path, stat, shutil, subprocess, plistlib
def Usage():
    print("\n\tUsage: python "+sys.argv[0]+" [<path/>expgui]\n")
    sys.exit()

project="EXPGUI"

if __name__ == '__main__':
    # find the expgui tcl script if not on command line
    if len(sys.argv) == 1:
        script = os.path.abspath(os.path.join(
            os.path.split(__file__)[0],
            "expgui"
            ))
    elif len(sys.argv) == 2:
        script = os.path.abspath(sys.argv[1])
    else:
        Usage()

    while os.path.isdir(script):
        print("found expgui directory: "+str(script))
        script = os.path.join(script,'expgui')

    # make sure we found it
    if not os.path.exists(script):
        print("\nFile "+script+" not found")
        Usage()
    # where the app will be created
    scriptdir = os.path.split(os.path.split(script)[0])[0]
    # name of app
    apppath = os.path.abspath(os.path.join(scriptdir,project+".app"))
    iconfile = os.path.join(scriptdir,'expgui','expgui.icns') # optional icon file

    if os.path.exists(apppath): # cleanup
        print("\nRemoving old "+project+" app ("+str(apppath)+")")
        shutil.rmtree(apppath)

    # create an AppleScript that launches python with the requested app
    AppleScript = '''(*   Launch EXPGUI: launches EXPGUI by double clicking on app or by dropping a data file or folder on the app

version for 10.6 and later

original script by F. Farges; farges@univ-mlv.fr ; many changes by B. Toby brian.toby@anl.gov

To debug this script, create file /tmp/EXPGUIdebug.txt (from command line: touch /tmp/EXPGUIdebug.txt)
The output from launching EXPGUI will be appended to the end of that file.
*)


(*--------------------------------------------------------
Define subroutines  used in later sections of code
----------------------------------------------------------- 
*)

(*  get  directory  from a file name *)
on GetParentPath(theFile)
	tell application "Finder" to return container of theFile as text
end GetParentPath

(* find a wish executable or return an error *)
on GetWishExe(myPath)
	set WishExe to myPath & "exe:ncnrpack"
	set WishExe to the POSIX path of WishExe
	tell application "System Events"
		if (file WishExe exists) then
			return WishExe
		end if
		(*set WishExe to "/sw/bin/wish"
		if (file WishExe exists) then
			return WishExe
		end if*)
		error ("Error: Tcl/Tk executable, " & WishExe & " was not found. See installation instructions.")
	end tell
end GetWishExe

(* test if a file is present and exit with an error message if it is not  *)
on TestFilePresent(appwithpath)
	tell application "System Events"
		if (file appwithpath exists) then
		else
			error ("Error: file " & appwithpath & " not found. This EXPGUI AppleScript must be run from the gsas directory. Did you move it?")
		end if
	end tell
end TestFilePresent

(* 
--------------------------------------------------------------
this section responds to a double-click. It starts X11 and then expgui, provided 
the expgui script is in the expgui folder of the location of this applescript
 o it finds the location of the current script and finds the expgui 
     tcl script relative to the applescript
 o it finds a version of Tcl/Tk to run either relative to the script location
     or if not present there, in the place where Fink would install it
 o it opens X11 (if needed)
-------------------------------------------------------------- 
*)
on run
	set Prefix to "cd ~;PATH=$PATH:/usr/local/bin:/usr/X11R6/bin "
	tell application "Finder"
		if POSIX file "/tmp/EXPGUIdebug.txt" exists then
			set Output to "/tmp/EXPGUIdebug.txt"
		else
			set Output to "/dev/null"
		end if
	end tell
	set myPath to (path to me)
	set ParentPath to GetParentPath(myPath)
	set appwithpath to ParentPath & "expgui:expgui"
	TestFilePresent(appwithpath)
	set posixapp to quoted form of the POSIX path of appwithpath
	set WishExe to the quoted form of GetWishExe(ParentPath)
	
	tell application "Finder"
		launch application "X11"
	end tell
	
	set results to do shell script Prefix & WishExe & " " & posixapp & "  >> " & Output & " 2>&1 &"
end run

(*
----------------------------------------------------------------------
this section handles opening files dragged into the AppleScript
 o it finds the location of the current script and finds the expgui 
     tcl script relative to the applescript
 o it finds a version of Tcl/Tk to run either relative to the script location
     or if not present there, in the place where Fink would install it
 o it opens X11 (if needed)
 o it goes through the list of files dragged in
 o then it converts the colon-delimited macintosh file location to a POSIX filename
 o for every non-directory file dragged into the icon, it tries to open that file in the script
-----------------------------------------------------------------------
*)

on open names
	
	set Prefix to "PATH=$PATH:/usr/local/bin:/usr/X11R6/bin "
	tell application "Finder"
		if POSIX file "/tmp/EXPGUIdebug.txt" exists then
			set Output to "/tmp/EXPGUIdebug.txt"
		else
			set Output to "/dev/null"
		end if
	end tell
	set myPath to (path to me)
	set ParentPath to GetParentPath(myPath)
	set appwithpath to GetParentPath(myPath) & "expgui:expgui"
	TestFilePresent(appwithpath)
	set posixapp to the quoted form of the POSIX path of appwithpath
	set WishExe to the quoted form of GetWishExe(ParentPath)
	
	tell application "Finder"
		launch application "X11"
	end tell
	
	set filePath to ""
	repeat with i in names
		set macpath to (i as string)
		if macpath ends with ":" then
			(* if this is a directory; start EXPGUI in that folder *)
			set filename to the quoted form of the POSIX path of macpath
			set results to do shell script "cd " & filename & ";" & Prefix & WishExe & "  " & posixapp & "  >> " & Output & " 2>&1 &"
		else if macpath ends with ".EXP" then
			(* if this is an experiment file, open it *)
			set filename to the quoted form of the POSIX path of macpath
			set results to do shell script "cd ~;" & Prefix & WishExe & " " & posixapp & " " & filename & "  >> " & Output & " 2>&1 &"
		else
			display dialog "This is not a valid GSAS Experiment file: " & macpath with icon caution buttons {"OK"}
		end if
	end repeat
end open
'''
    shell = os.path.join("/tmp/","appscrpt.script")
    f = open(shell, "w")
    f.write(AppleScript)
    f.close()

    if sys.version_info[0]+sys.version_info[1]/10. >= 2.7:
        try: 
            subprocess.check_output(["osacompile","-o",apppath,shell],stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError, msg:
            print('Error compiling AppleScript.\n'+
                  'Report the next message along with details about your Mac to toby@anl.gov')
            print(msg.output)
            sys.exit()
    else:
        try: 
            subprocess.call(["osacompile","-o",apppath,shell])
        except Exception, msg:
            print('Error compiling AppleScript in python <=2.6\n'+
                  'Report the next message along with details about your Mac to toby@anl.gov')
            print(msg)
            sys.exit()
    # change the icon
    oldicon = os.path.join(apppath,"Contents","Resources","droplet.icns")
    if os.path.exists(iconfile) and os.path.exists(oldicon):
        shutil.copyfile(iconfile,oldicon)

    # Edit the app plist file to restrict the type of files that can be dropped
    d = plistlib.readPlist(os.path.join(apppath,"Contents",'Info.plist'))
    d['CFBundleDocumentTypes'] = [{
        'CFBundleTypeExtensions': ['EXP'],
        'CFBundleTypeName': 'GSAS project',
        'CFBundleTypeRole': 'Editor'}]
    plistlib.writePlist(d,os.path.join(apppath,"Contents",'Info.plist'))

    print("\nCreated "+project+" app ("+str(apppath)+
          ").\nViewing app in Finder so you can drag it to the dock if, you wish.")
    subprocess.call(["open","-R",apppath])
