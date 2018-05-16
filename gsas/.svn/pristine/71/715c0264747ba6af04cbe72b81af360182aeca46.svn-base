proc DA_Initialize {} {
    catch {unset ::da_ddrad}
    catch {unset ::da_darad}
    catch {unset ::da_drad}
    catch {unset ::da_arad}
    catch {unset ::da_acon}
    catch {unset ::da_dcon}
    set ::da_quit 1
    set ::da_phase $::expmap(phaselist)
    foreach j $::da_phase {
        set ::da_dcon($j) [phaseinfo $j DistCalc]
        set b [regexp -all {[0-9]} $::da_dcon($j)]
        if {$b > 0} {
	    set ::da_dval($j) $::da_dcon($j)]
    } else {
	set ::da_dval$j ""
    }

    set ::da_acon($j) [phaseinfo $j AngCalc]
    set c [regexp -all {[0-9]} $::da_acon($j)]
    if {$c > 0} {set ::da_aval$j $::da_acon($j)
    } else {
	set ::da_aval$j ""}

}

}

proc DA_Read {} {

    set ::da_list [AtmTypList]
    set da_angrad [DefAtmTypInfo angrad]
    set da_distrad [DefAtmTypInfo distrad]

    #Build search arrays
    #::da_darad array contains default angle search radii
    #::da_ddrad array contains default distance search radii
    #::da_arad array contains current angle search radii
    #::da_drad array contains current distance search radii

    foreach j $da_angrad {
	set ::da_darad([lindex $j 0]) [lindex $j 1]
    }
    foreach k $da_distrad {
	set ::da_ddrad([lindex $k 0]) [lindex $k 1]
    }
    foreach i $::da_list {
	set ::da_drad($i) [AtmTypInfo distrad $i]
	set ::da_arad($i) [AtmTypInfo angrad $i]
    }
}

#**************** Build Disagl Control Panel ****************************

proc DA_Control_Panel {"launchdisagl 0"} {
    DA_Initialize
    DA_Read
    destroy .disaglcon
    set dcb .disaglcon
    catch {toplevel $dcb}
    eval destroy [winfo children $dcb]

    #construct phase control box in phasecon frame
    set phasecon $dcb.phasecon
    frame $phasecon -bd 2 -relief groove
    grid $phasecon -column 0 -row 0

    label $phasecon.lbl1 -text "Bond Search \n Method"
    label $phasecon.lbl2 -text "Angle Search \n Method"
    grid  $phasecon.lbl1 -column 1 -row 0
    grid  $phasecon.lbl2 -column 2 -row 0


    foreach i $::da_phase {
	label  $phasecon.phase$i -text "Phase $i" -width 8
	set tacon [regexp {[0-9]+.[0-9]+} $::da_acon($i)]
	set tdcon [regexp {[0-9]+.[0-9]+} $::da_dcon($i)]
	if {$tacon} {set alist {none radii $::da_acon($i)}
	} else {set alist {none radii {fixed search range}}}
	if {$tdcon} {set dlist {none radii $::da_dcon($i)}
	} else {set dlist {none radii {fixed search range}}}

	#            set list  {none radii {fixed search range}}
	#if {[set ::da_dval$i] != ""} {lappend list [set ::da_dval$i]}
	eval tk_optionMenu $phasecon.dist$i ::da_dcon($i) $dlist
	$phasecon.dist$i config -width 10
	eval tk_optionMenu $phasecon.ang$i  ::da_acon($i) $alist
	$phasecon.ang$i config -width 10
	grid   $phasecon.phase$i -row $i -column 0 -padx 10
	grid   $phasecon.dist$i  -row $i -column 1 -padx 10
	grid   $phasecon.ang$i   -row $i -column 2 -padx 10
    }

    trace var ::da_dcon w DA_Controls
    trace var ::da_acon w DA_Controls


    #save box
    set dasave $dcb.dasave
    frame $dasave -bd 2 -relief groove
    grid $dasave -column 0 -row 2

    if {$launchdisagl} {
	wm title $dcb "DISAGL Control Panel"
	grab release $dcb
	checkbutton $dasave.option -text "DISAGL output in separate window" \
	    -variable ::expgui(disaglSeparateBox)
	grid $dasave.option -row 0 -column 0
	button $dasave.sexit -text "Save and run DISAGL" -command DA_Save -bg LightGreen
	grid $dasave.sexit -row 1 -column 0
    } else {
	wm title $dcb "Distance Search Parameters"
	grab release $dcb
	button $dasave.sexit -text "Save and Exit" -command DA_Save -bg LightGreen
	grid $dasave.sexit -row 0 -column 0
    }
    button $dasave.quit -text "Cancel" -command "destroy $dcb"
    grid $dasave.quit -row 2 -column 0


    #construct control box


    set dacon $dcb.dacon
    frame $dacon -bd 2 -relief groove
    grid $dacon -column 1 -row 2

    button $dacon.default -text "Restore to Default Radii" -command {
	foreach i $::da_list {
	    set ::da_drad($i) $::da_ddrad([lindex [split $i {+-}] 0])
	    set ::da_arad($i) $::da_darad([lindex [split $i {+-}] 0])
	}
    }
    grid $dacon.default -row 3 -column 0 -columnspan 3

    label $dacon.dradcon -text "Increment All Bond Search Radii (0.10 A)"
    label $dacon.aradcon -text "Increment All Angle Search Radii (0.10 A)"
    button $dacon.dradup -text "\u2191" -command DA_Inc_Drad
    button $dacon.draddn -text "\u2193" -command DA_Dec_Drad
    button $dacon.aradup -text "\u2191" -command DA_Inc_Arad
    button $dacon.araddn -text "\u2193" -command DA_Dec_Arad
    grid $dacon.dradcon -column 0 -row 0 -pady 5
    grid $dacon.dradup  -column 1 -row 0 -padx 5
    grid $dacon.draddn  -column 2 -row 0 -padx 5
    grid $dacon.aradcon -column 0 -row 1 -pady 5
    grid $dacon.aradup  -column 1 -row 1 -padx 5
    grid $dacon.araddn  -column 2 -row 1 -padx 5

    #     button $dacon.radcon -text "Radii Editor" -command {DA_Radii_Box .disaglcon}
    #     grid $dacon.radcon -row 1 -column 0

    DA_Radii_Box .disaglcon
    putontop  .disaglcon
    tkwait window .disaglcon
    afterputontop
    return $::da_quit

}

proc DA_Controls {var phase junk } {
    if {[set ${var}($phase)] == "none"} {
        if {$var == "::da_acon"} {
	    set ::da_dcon($phase) "none"
	    #puts 1
        } else {
	    set ::da_acon($phase) "none"
	    #puts 2
        }
    }
    if {[set ${var}($phase)] != "none" && ($::da_dcon($phase) == "none" || $::da_acon($phase) == "none")} {
        if {$var == "::da_acon"} {
	    set ::da_dcon($phase) "radii"
        } else {
	    set ::da_acon($phase) "radii"
        }
    }


    #     if {[set ${var}($phase)] == "fixed search range"} {}
    if {[set ${var}($phase)] != "none" && [set ${var}($phase)] != "radii" } {
	catch {destroy .disaglcon.top}
	set dedit .disaglcon.top
	toplevel $dedit
	bind $dedit <Return> "destroy $dedit"
	#           frame $dedit -bd 2 -relief groove
	#           pack $dedit -side top
	set temp [regexp {[0-9]+.[0-9]+} [set ${var}($phase)]]
	if {$temp == 0} {set ${var}($phase) 0.00}
	if {$var == "::da_acon"} {
	    label $dedit.lbl1    -text "set angle fixed search range \n for phase $phase in angstroms"
	    #              set ::da_acon($phase) 0
	    entry  $dedit.entry1 -textvariable ::da_acon($phase) -takefocus 1 
	    $dedit.entry1 selection range 0 end
	    grid $dedit.lbl1 -column 0 -row 0
	    grid $dedit.entry1 -column 0 -row 1
	    focus $dedit.entry1
	}
	if {$var == "::da_dcon"} {
	    #             set ::da_dcon($phase) 0
	    label $dedit.lbl1    -text "set bond fixed search range \n for phase $phase in angstroms"
	    entry  $dedit.entry1 -textvariable ::da_dcon($phase) -takefocus 1
	    $dedit.entry1 selection range 0 end
	    grid $dedit.lbl1 -column 0 -row 0
	    grid $dedit.entry1 -column 0 -row 1
	    focus $dedit.entry1
	}
	button $dedit.quit -text "Set" -command "destroy $dedit"
	grid $dedit.quit -column 0 -row 2
	putontop $dedit
	tkwait window $dedit
	afterputontop
    }




    #     puts "phase = $phase"
    #     puts "var = $var"
    #     puts "new value = [set ${var}($phase)]"
}

proc DA_Radii_Box {dcb args} {
    #construct radii control box
    catch {destory $dcb.radcon}
    catch {destory $dcb.discon}
    set radcon $dcb.radcon
    frame $radcon -bd 2 -relief groove
    grid $radcon -column 1 -row 0 -rowspan 2

    label $radcon.lbl1 -text "Atom/Ion"
    label $radcon.lbl2 -text "Bond \n Search Radii"
    label $radcon.lbl3 -text "Angle \n Search Radii"
    grid $radcon.lbl1 -row 0 -column 0
    grid $radcon.lbl2 -row 0 -column 1
    grid $radcon.lbl3 -row 0 -column 2
    set count 1
    foreach j [array names ::da_drad] {
	label $radcon.atom$j -text "$j" -width 5
	entry $radcon.drad$j -textvariable ::da_drad($j) -width 6 -takefocus 1
	entry $radcon.arad$j -textvariable ::da_arad($j) -width 6 -takefocus 1
	grid  $radcon.atom$j -row $count -column 0
	grid  $radcon.drad$j -row $count -column 1
	grid  $radcon.arad$j -row $count -column 2
	incr count
    }
}


proc DA_Inc_Drad {args} {
    foreach j [array names ::da_drad] {
	set ::da_drad($j) [format %.1f [expr $::da_drad($j) + 0.1]]
    }
}

proc DA_Dec_Drad {args} {
    foreach j [array names ::da_drad] {
	set ::da_drad($j) [format %.1f [expr $::da_drad($j) - 0.1]]
    }
}
proc DA_Inc_Arad {args} {
    foreach j [array names ::da_arad] {
	set ::da_arad($j) [format %.1f [expr $::da_arad($j) + 0.1]]
    }
}
proc DA_Dec_Arad {args} {
    foreach j [array names ::da_drad] {
	set ::da_arad($j) [format %.1f [expr $::da_arad($j) - 0.1]]
    }
}

proc DA_Save {args} {
    foreach i $::da_list {
	if {$::da_drad($i) >= 0 && $::da_drad($i) <= 10000} {
	    AtmTypInfo distrad $i set $::da_drad($i)
	}
	puts 1
	if {$::da_arad($i) >= 0 && $::da_arad($i) <= 10000} {
	    AtmTypInfo angrad $i set $::da_arad($i)
	}

    }
    foreach j $::da_phase {
        phaseinfo $j DistCalc set $::da_dcon($j)
        phaseinfo $j AngCalc set $::da_acon($j)
    }
    # indicate a change to the .EXP file
    incr ::expgui(changed)
    set ::da_quit 0
    destroy .disaglcon
}
