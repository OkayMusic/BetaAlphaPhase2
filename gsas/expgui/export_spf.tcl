# write coordinates for PLATON --  STANDARD PARAMETER FILE (.SPF) Format
## $Id: export_spf.tcl 1251 2014-03-10 22:17:29Z toby $
set label "export SPF (PLATON) format"
set action export_SPF
proc export_SPF {} {
    global expmap expgui
    # don't bother if there are no phases to write
    if {[llength $expmap(phaselist)] == 0} {
	MyMessageBox -parent . -title "No phases" \
		-message "Sorry, no phases are present to write" \
		-icon warning
	return
    }
    MakeExportBox .export "Export coordinates in SPF (PLATON) format" \
	    "MakeWWWHelp expgui.html ExportSPF"
    # note, change export in the line above to the name anchor for a 
    # section documenenting the format added to expgui.html, if added
    #
    # force the window to stay on top
    putontop .export
    # Wait for the Write or Quit button to be pressed
    tkwait window .export
    afterputontop
    # test for Quit
    if {$expgui(export_phase) == 0} {return}

    # now open the file and write it
    set phase $expgui(export_phase)
    if [catch {
	set filnam [file rootname $expgui(expfile)]_${phase}.spf
	set fp [open $filnam w]
	# deal with macromolecular phases
	if {[lindex $expmap(phasetype) [expr {$phase - 1}]] == 4} {
	    set mm 1
	    set cmd mmatominfo
	} else {
	    set mm 0
	    set cmd atominfo
	}
	#==============================================================
	# title info from GSAS title & phase title
	puts $fp "TITL   Phase $phase from $expgui(expfile) named [string trim [phaseinfo $phase name]]"
	#puts $fp "TITL   history [string trim [lindex [exphistory last] 1]]"
	#puts $fp "TITL   [expinfo title]"
	# write out cell parameters
	set cell {}
	foreach p {a b c alpha beta gamma} {
	    append cell " [phaseinfo $phase $p]"
	}
	puts $fp "CELL $cell"
	# process & writeout the spacegroup
	set spacegroup [phaseinfo $phase spacegroup]
	# remove final R from rhombohedral space groups
	if {[string toupper [string range $spacegroup end end]] == "R"} {
	    set spacegroup [string range $spacegroup 0 \
		    [expr [string length $spacegroup]-2]] 
	}
	# remove spaces from space group
	regsub -all " " $spacegroup "" spacegroup
	puts $fp "SPGR $spacegroup"
	# now loop over atoms
	foreach atom $expmap(atomlist_$phase) {
	    foreach var {x y z frac label type} {
		set $var [$cmd $phase $atom $var]
	    }
	    if {[catch {incr count($type)}]} {set count($type) 1}
	    # create a label, since the GSAS label may not work for platon
	    set lbl [string range $type 0 1]
	    append lbl ($count($type))
	    #write out the atom, tab delimited
	    puts $fp "ATOM  $lbl   $x $y $z $frac"
	    # is this atom anisotropic? 
	    if {!$mm && [atominfo $phase $atom temptype] == "A"} {
		set ulist {}
		foreach u {U11 U22 U33 U23 U13 U12} {
		    lappend ulist [atominfo $phase $atom $u]
		}
		puts $fp "UIJ   $lbl   $ulist"
	    } else {
		puts $fp "U     $lbl   [$cmd $phase $atom Uiso]"
	    }
	}
	#==============================================================
	close $fp
    } errmsg] {
	MyMessageBox -parent . -title "Export error" \
		-message "Export error: $errmsg" -icon warning
    } else {
	MyMessageBox -parent . -title "Done" \
		-message "File [file tail $filnam] was written"
    }
}
