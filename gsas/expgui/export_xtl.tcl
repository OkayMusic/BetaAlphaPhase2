# $Id: export_xtl.tcl 1251 2014-03-10 22:17:29Z toby $
# set local variables that define the proc to execute and the menu label
set label "MSI .xtl format"
set action exp2xtl
# write coordinates in an MSI .xtl file
proc exp2xtl {} {
    global expmap expgui
    # don't bother if there are no phases to write
    if {[llength $expmap(phaselist)] == 0} {
	MyMessageBox -parent . -title "No phases" \
		-message "Sorry, no phases are present to write" \
		-icon warning
	return
    }
    MakeExportBox .export "Export coordinates in MSI .xtl format" \
	    "MakeWWWHelp expgui.html ExportMSI"
    #------------------------------------------------------------------
    # special code to get the spacegroup info
    pack [label .export.special.1 -text "Space Group: "] -side left
    pack [entry .export.special.2 -textvariable expgui(export_sg) \
	    -width 8] -side left
    pack [checkbutton .export.special.3 -variable expgui(export_orig) \
	    -text "Origin 2"] -side left
    trace variable expgui(export_phase) w MSI_SP_convert
    # force processing of the spacegroup
    SetExportPhase [lindex $expmap(phaselist) 0] .export
    # end of special code to get the spacegroup info
    #------------------------------------------------------------------
    #
    # force the window to stay on top
    putontop .export
    # Wait for the Write or Quit button to be pressed
    tkwait window .export
    afterputontop
    #------------------------------------------------------------------
    # special code to get the spacegroup info
    trace vdelete  expgui(export_phase) w MSI_SP_convert
    # end of special code to get the spacegroup info
    #------------------------------------------------------------------
    # test for Quit
    if {$expgui(export_phase) == 0} {return}
    # 
    set phase $expgui(export_phase)
    #------------------------------------------------------------------
    # special code to get the spacegroup info
    set origin $expgui(export_orig)
    set rhomb $expgui(export_rhomb)
    set spsymbol $expgui(export_sg)
    set errmsg {}
    if {$spsymbol == ""} {
	set errmsg "Error: invalid Space Group: $spsymbol"
    }
    if {$errmsg != ""} {
	MyMessageBox -parent . -title "Export error" \
		-message "Export error: $errmsg" -icon warning
	return
    }
    # end of special code to get the spacegroup info
    #------------------------------------------------------------------

    if [catch {
	set filnam [file rootname $expgui(expfile)]_${phase}.xtl
	set fp [open $filnam w]
	puts $fp "TITLE Phase $phase from $expgui(expfile)"
	puts $fp "TITLE history [string trim [lindex [exphistory last] 1]]"
	puts $fp "TITLE phase [phaseinfo $phase name]"
	puts $fp "CELL"
	puts $fp "  [phaseinfo $phase a] [phaseinfo $phase b] [phaseinfo $phase c] [phaseinfo $phase alpha] [phaseinfo $phase beta] [phaseinfo $phase gamma]"
	
	puts $fp "Symmetry Label $spsymbol"
	if $origin {
	    puts $fp "Symmetry Qualifier origin_2"
	}
	if $rhomb {
	    puts $fp "Symmetry Qualifier rhombohedral"
	}
	
	puts $fp "ATOMS"
	puts $fp "NAME       X          Y          Z    UISO      OCCUP"
	if {[lindex $expmap(phasetype) [expr {$phase - 1}]] == 4} {
	    set mm 1
	    set cmd mmatominfo
	} else {
	    set mm 0
	    set cmd atominfo
	}
	foreach atom $expmap(atomlist_$phase) {
	    set label [$cmd $phase $atom label]
	    # remove () characters
	    regsub -all "\[()\]" $label "" label
	    set uiso [$cmd $phase $atom Uiso]
	    # are there anisotropic atoms?
	    if {!$mm} {
		if {[atominfo $phase $atom temptype] == "A"} {
		    set uiso [expr \
			    ([atominfo $phase $atom U11] + \
			    [atominfo $phase $atom U22] + \
			    [atominfo $phase $atom U33]) / 3.]
		}
	    }
	    puts $fp "$label [$cmd $phase $atom x] \
			[$cmd $phase $atom y] [$cmd $phase $atom z] \
			$uiso  [$cmd $phase $atom frac]"
	}
	close $fp
    } errmsg] {
	MyMessageBox -parent . -title "Export error" \
		-message "Export error: $errmsg" -icon warning
    } else {
	MyMessageBox -parent . -title "Done" \
		-message "File [file tail $filnam] was written"
    }
}

# process the spacegroup whenever the phase is changed
proc MSI_SP_convert {args} {
    global expgui
    set phase 0
    catch {set phase $expgui(export_phase)}
    if {$phase == 0} return
    set spacegroup [phaseinfo $phase spacegroup]
    set expgui(export_rhomb) 0
    # remove final R from rhombohedral space groups
    if {[string toupper [string range $spacegroup end end]] == "R"} {
	set expgui(export_rhomb) 1
	set spacegroup [string range $spacegroup 0 \
		[expr [string length $spacegroup]-2]] 
    }
    # remove spaces from space group
    regsub -all " " $spacegroup "" spacegroup
    set expgui(export_sg) $spacegroup
    set expgui(export_orig) 0
    # scan through the Origin 1/2 spacegroups for a match
    set spacegroup [string toupper $spacegroup]
    # treat bar 3 as the same as 3 (Fd3m <==> Fd-3m)
    regsub -- "-3" $spacegroup "3" spacegroup
    set fp [open [file join $expgui(scriptdir) spacegrp.ref] r]
    # skip over the first section of file
    set line 0
    while {[lindex $line 1] != 230} {
	if {[gets $fp line] < 0} return
    }
    while {[gets $fp line] >= 0} {
	set testsg [string toupper [lindex $line 8]]
	regsub -all " " $testsg "" testsg
	regsub -- "-3" $testsg "3" testsg
	if {$spacegroup == $testsg} {
	    set expgui(export_orig) 1
	    break
	}
    }
    close $fp
}
