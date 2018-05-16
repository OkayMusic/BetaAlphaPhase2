#!/bin/sh
# the next line restarts this script using wish found in the path\
exec wish "$0" "$@"
# If this does not work, change the #!/usr/bin/wish line below
# to reflect the actual wish location and delete all preceeding lines
#
# (delete here and above)
#!/usr/bin/wish
# $Id: dumpexp.tcl 1251 2014-03-10 22:17:29Z toby $

package require Tk

if {[llength $argv] != 1} {
    wm withdraw .
    tk_dialog .err {Wrong Args} \
	    "$argv0: argument should be a .EXP file name" \
	    error 0 Continue
    exit
}

set filename [lindex $argv 0]

set expgui(font) 14
set expgui(debug) 0

pack [label .l -text "Reading $filename\nPlease wait"]
update
wm protocol . WM_DELETE_WINDOW {puts ""; exit}
#=============================================================================
#----------------------------------------------------------------
# where are we?
set expgui(script) [info script]
# translate links -- go six levels deep
foreach i {1 2 3 4 5 6} {
    if {[file type $expgui(script)] == "link"} {
	set link [file readlink $expgui(script)]
	if { [file  pathtype  $link] == "absolute" } {
	    set expgui(script) $link
	} {
	    set expgui(script) [file dirname $expgui(script)]/$link
	}
    } else {
	break
    }
}
# fixup relative paths
if {[file pathtype $expgui(script)] == "relative"} {
    set expgui(script) [file join [pwd] $expgui(script)]
}
set expgui(scriptdir) [file dirname $expgui(script) ]
#----------------------------------------------------------------
source [file join $expgui(scriptdir) opts.tcl]
# fetch EXP file processing routines 
source [file join $expgui(scriptdir) readexp.tcl]
# commands for running GSAS programs
#source [file join $expgui(scriptdir) gsascmds.tcl]
# override options with locally defined values
set filelist [file join $expgui(scriptdir) localconfig]
if {$tcl_platform(platform) == "windows"} {
    lappend filelist "c:/gsas.config"
} else {
    lappend filelist [file join ~ .gsas_config]
}
catch {
    foreach file $filelist {
	if [file exists $file] {source $file}
    }
}

SetTkDefaultOptions $expgui(font)

if {![file exists $filename]} {
    # read error
    wm withdraw .
    tk_dialog .err {Bad file} \
	    "$argv0: error\nfile $filename not found" \
	    error 0 Continue
    exit
}
set fmt [expload $filename]
if {$fmt < 0} {
    # read error
    wm withdraw .
    tk_dialog .err {Bad file} \
	    "$argv0: error reading $filename\nThis is not a valid GSAS .EXP file" \
	    error 0 Continue
    exit
}
mapexp
if {[llength $expmap(phaselist)] == 0} {
    # read error
    wm withdraw .
    tk_dialog .err {Bad file} \
	    "$argv0: error reading $filename\nNo phases found" \
	    error 0 Continue
    exit
}
if {[llength $expmap(phaselist)] > 1} {
    # count non-mm phases
    set i 0
    foreach p $expmap(phaselist) type $expmap(phasetype) {
	if {$type != 4} {incr i; set phase $p}
    }
    if {$i > 1} {
	# need to select a phase
	.l config -text "Select a phase"
	foreach p $expmap(phaselist) type $expmap(phasetype) {
	    set n [phaseinfo $p name]
	    pack [radiobutton .p$p -text "Phase $p: $n" -variable phase \
		    -value $p] -anchor w
	    if {$type == 4} {
		.p$p config -state disabled
	    }
	}
	wm withdraw .
	update idletasks
	set x [expr {[winfo screenwidth .]/2 - [winfo reqwidth .]/2}]
	set y [expr {[winfo screenheight .]/2 - [winfo reqheight .]/2}]
	wm geom . +$x+$y
	wm deiconify .
	grab .
	focus .
        set phase {}
	tkwait variable phase
    }
} else {
    set phase $expmap(phaselist)
    if {$expmap(phasetype) == 4} {
	tk_dialog .err {Only mm phase} \
		"$argv0: unable to read from $filename\nOnly a macromolecular phase is present." \
		error 0 Continue
	exit
    }
}
foreach v {a b c alpha beta gamma} {
    lappend l [phaseinfo $phase $v]
}
set l1 {}
foreach a $expmap(atomlist_$phase) {
    set l2 {}
    foreach p {label x y z type frac} {
	lappend l2 [atominfo $phase $a $p]
    }
    if {[atominfo $phase $a temptype] == "I"} {
	lappend l2 [atominfo $phase $a Uiso]
    } else {
	set ueq {} 
	catch {
	    set ueq [expr {
		([atominfo $phase $a U11] + 
		[atominfo $phase $a U22] + 
		[atominfo $phase $a U33]) /3.
	    }]
	    }
	lappend l2 $ueq
#    }
    lappend l1 $l2
}
puts [list [phaseinfo $phase spacegroup] $l $l1]
exit
