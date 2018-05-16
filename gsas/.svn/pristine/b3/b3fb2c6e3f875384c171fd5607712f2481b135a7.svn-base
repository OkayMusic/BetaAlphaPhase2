if {[llength $argv] != 1} {
    wm withdraw .
    tk_dialog .err {Wrong Args} \
	    "$argv0: argument should be a .EXP file name" \
	    error 0 Continue
    exit
}

package require Tk

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
set list1 {}
foreach hist $expmap(powderlist) {
    set list2 $hist
    set instcons {}
    foreach item {difc difa zero ipola pola} {
	lappend instcons [histinfo $hist $item] 
    }
    lappend list2 "$expmap(htype_$hist) [list $instcons]"
    foreach i $expmap(phaselist_$hist) {
	set list $i
	lappend list [string trim [hapinfo $hist $i proftype]]
	lappend list [hapinfo $hist $i pcut]
	set nterms [hapinfo $hist $i profterms]
	for { set num 1 } { $num <= $nterms } { incr num } {
	    lappend list [hapinfo $hist $i pterm$num]
	}
	lappend list2 $list
    }
    lappend list1 $list2
}
puts $list1
exit
