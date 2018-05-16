######################################################################
# code for distance restraints (soft constraints)
######################################################################
#list of global variables and procedures

#::sr_lookuplist1
#::sr_lookuplist2
#sr_top
#::sr_checkall
#::sr_entryvar(choicenum)
#::sr_entryvar(softatom1)
#::sr_entryvar(softatom2)
#::sr_entryvar(softphase)
#::sr_dminvalue
#::sr_dmaxvalue
#::sr_restraintdist
#::sr_restraintesd
#::sr_rvalue
#::sr_resd
#::srcb4.rbutton3
#::sr_crestraint
#::sr_phaselist
#::sr_bond_list

#SR_Read_Distances
#SR_Make_ScrollTable
#SR_Resize_Scroll_Table
#SR_Display
#SR_Set_Rval
#SR_Validate_Num
#SR_Load_Restraints
#SR_Write_Restraints
#SR_Update_Restraints
#SR_Delete_Restraints
#SR_Set_All_Check_Buttons
#SR_Build

set ::sr_atom1_button 1
set ::sr_atom2_button 1
set ::sr_distance_button 1
set ::sr_entryvar(choicenum) 0
#    set ::sr_entryvar(softphase) "1"
#    set ::sr_phaselist $::expmap(phaselist)
set ::sr_entryvar(softatom1) "all"
set ::sr_entryvar(softatom2) "all"
set ::sr_phaselist $::expmap(phaselist)
set ::sr_error 0
set ::sr_bond_list ""
set ::sr_dminvalue 0
set ::sr_dmaxvalue 1000
set ::sr_display_mode noedit
set ::sr_key_list ""

proc DisplayDistanceRestraints {args} {
    #puts DisplayDistanceRestraints
    global expcons
    eval destroy [winfo children $expcons(distmaster)]

    set leftfr $expcons(distmaster).f1
    set rightfr $expcons(distmaster).f2
    set phasebox $leftfr.f1
    set editorbox $leftfr.f2
    set atomfilter $leftfr.f3

    grid [frame $leftfr -bd 2 -relief groove] -column 0 -row 0 \
	-sticky nsew
    grid [frame $rightfr -bd 2 -relief groove] -column 1 -row 0 \
	-sticky nsew
    grid [frame $phasebox -bd 2 -relief groove] -column 0 -row 0 \
	-sticky new -columnspan 2


    grid [frame $editorbox -bd 2 -relief groove] -column 0 -row 2 \
	-sticky sew -columnspan 2


    grid rowconfigure $expcons(distmaster) 0 -weight 1
    grid columnconfigure $expcons(distmaster) 1 -weight 1


    # Pick Phase to be Evaluated **********************************************
    label $phasebox.phlabel -text Phase
    #    set ::sr_phaselist $::expmap(phaselist)

    eval tk_optionMenu $phasebox.phase ::sr_entryvar(softphase) $::expmap(phaselist)
    #    eval tk_optionMenu $phasebox.phase ::sr_entryvar(softphase) $::sr_phaselist
    #   trace variable ::sr_entryvar(softphase) w DisplayDistanceRestraints
    #   bind $phasebox.phase <ButtonRelease> {DisplayDistanceRestraints}

    grid $phasebox.phlabel -column 0 -row 0
    grid $phasebox.phase  -column 1 -row 0
    #**************************************************************************

    #Restraint Weight Control Box
    grid [label $leftfr.lweight -text "Restraint Weight"] -column 0 -row 1 -sticky sw -pady 10
    grid [entry $leftfr.weight -width 8 -textvariable entryvar(distrestweight)] -column 1 -row 1 -sticky sw \
	-padx 5 -pady 10
    set ::entrycmd(distrestweight) "SoftConst weight"
    set ::entrycmd(trace) 0
    set ::entryvar(distrestweight) [SoftConst weight]
    #RecordMacroEntry "set ::entryvar(distrestweight) [SoftConst weight]" 0
    set ::entrycmd(trace) 1
    #incr ::expgui(changed)

    #Run Disagl Commands *****************************************************
    #button $leftfr.disagl -text "Refresh Disagl"
    #grid $leftfr.disagl -column 1 -row 1
    #**************************************************************************



    #Activate Restraint Editor
    grid [button $editorbox.edit -text "Activate Restraint \n Editor" -command SR_TEST] -column 0 -row 4 \
	-columnspan 2 -pady 5
    $editorbox.edit config -bg LightGreen -bd 6

    grid [button $editorbox.search -text "Edit Search Distance \n Parameters" -command DA_Control_Panel] -column 0 -row 3 \
        -columnspan 2
    $editorbox.edit config -bd 4


    foreach {top main side lbl} [MakeScrollTable $rightfr 450 300] {}
    MouseWheelScrollTable $rightfr
    set atom1_state  1
    set atom2_state  1

    button $top.alabel1 -text "Atom 1"    -width 7 -anchor center \
	-command "SR_Sort atom1 $main $top.alabel1 $top.alabel2 {}"

    button $top.alabel2 -text "Atom 2"   -width 7  -anchor center \
	-command "SR_Sort atom2 $main $top.alabel1 $top.alabel2 {}"

    label  $top.rlabel1 -text "Restraint" -width 9 -anchor center
    label  $top.rlabel2 -text "Tolerance" -width 9 -anchor center

    grid $top.alabel1 -column 1 -row 2 -padx 3
    grid $top.alabel2 -column 2 -row 2 -padx 3
    grid $top.rlabel1 -column 4 -row 2
    grid $top.rlabel2 -column 5 -row 2


    #remove traces to reset ::sr_entryvar(softatom1) and ::sr_entryvar(softatom2)
    foreach item [trace vinfo ::sr_entryvar(softatom1)] {
        eval trace vdelete ::sr_entryvar(softatom1) $item
    }
    foreach item [trace vinfo ::sr_entryvar(softatom2)] {
        eval trace vdelete ::sr_entryvar(softatom2) $item
    }
    set ::sr_entryvar(softatom1) "all"
    set ::sr_entryvar(softatom2) "all"
    #restart traces
    trace variable ::sr_entryvar(softatom1) w SR_Display
    trace variable ::sr_entryvar(softatom2) w SR_Display


    SR_Rest_Only
    SR_Show_RestraintsOnly $main $rightfr
    foreach item [trace vinfo ::sr_entryvar(softphase)] {
	eval trace vdelete ::sr_entryvar(softphase) $item
    }

    trace add variable ::sr_entryvar(softphase) write "SR_Show_RestraintsOnly $main $rightfr"
}
proc SR_Show_RestraintsOnly {main rightfr args} {

    SR_Fill_Display  $main
    ResizeScrollTable $rightfr
    #puts $rightfr
}

#*********************************************************************************************
#Read Disangle File and Create Bond List (sr_bond_list)**************************************************************************
#*********************************************************************************************
proc SR_Read_Distances {filename} {
    # initialiaze
    catch {unset ::sr_lookuplist1}
    catch {unset ::sr_lookuplist2}
    #        catch {unset ::sr_restraintdist}
    #        catch {unset ::sr_restraintesd}
    set ::sr_bond_list ""
    set ::sr_key_list ""

    #::sr_bond_list       0       - Phase Number
    #                     1, 2    - Atom 1 number, Atom 2 number
    #                     3, 4    - symmetry information
    #                     5, 6, 7 - cell translations
    #                     8       - bond distance
    #                     9, 10   - atom types
    #                     11, 12  - atom labels
    #                     13      - bond id key


    # switch to run disagl here someday
    if {[file exists $filename]} {
	#puts "$filename from [pwd] is opened"
	set fh [open $filename r]
	#		puts $fh
    } else {
	puts "$filename not found in directory [pwd]"
    }
    # read in the file
    set bond_totals -1
    while {[gets $fh line] >= 0} {
	if {[lindex $line 2] == 0} {
	    incr bond_totals
	    set bond_dist_array($bond_totals) $line
	    #puts "$bond_dist_array($bond_totals)"
	}
    }
    #puts "there are [phaseinfo 1 natoms] atoms in the file"
    #puts "$bond_totals bond distances have been read from the file"
    close $fh

    #create initial parameter for implimentation of soft restraints
    catch (unset initsoftpar)
    set x 0

    #set ::sr_bond_list ""
    while {$x < $bond_totals} {

	#phase number (0)
	set initsoftpar($x) [lindex $bond_dist_array($x) 1]

	#atom number 1 (1)
	lappend initsoftpar($x) [lindex $bond_dist_array($x) 5]

	#atom number 2 (2)
	lappend initsoftpar($x) [lindex $bond_dist_array($x) 6]

	#extract symmetry information (3, 4)
	set temp [lindex $bond_dist_array($x) 7]
	lappend initsoftpar($x) [expr abs($temp) % 100 * abs($temp) / $temp]
	lappend initsoftpar($x) [expr abs($temp)/100]

	#extract unit cell translations  (5, 6, 7)
	lappend initsoftpar($x) [expr [string index [lindex $bond_dist_array($x) 8] 0] - 5]
	lappend initsoftpar($x) [expr [string index [lindex $bond_dist_array($x) 8] 1] - 5]
	lappend initsoftpar($x) [expr [string index [lindex $bond_dist_array($x) 8] 2] - 5]

	#create bond ID code
	set t2 [string map {" " ""} [set t1 $initsoftpar($x)]]

	#              set z [info exists ::sr_restraintdist($t2)]
	#              if {$z == 0} {
	#                            set ::sr_restraintdist($t2) ""
	#                            set ::sr_restraintesd($t2) ""
	#                            }

	#extract bond distance
	lappend initsoftpar($x) [lindex $bond_dist_array($x) 3]

	#extract atom type and labels
	set num1 [lindex $bond_dist_array($x) 5]
	set num2 [lindex $bond_dist_array($x) 6]
	set type1 [atominfo [lindex $bond_dist_array($x) 1] [lindex $bond_dist_array($x) 5] type]
	set type1 [lindex [split $type1 {+-}] 0]
	set type2 [atominfo [lindex $bond_dist_array($x) 1] [lindex $bond_dist_array($x) 6] type]
	set type2 [lindex [split $type2 {+-}] 0]
	lappend initsoftpar($x) $type1
	lappend initsoftpar($x) $type2

	lappend initsoftpar($x) [atominfo [lindex $bond_dist_array($x) 1] [lindex $bond_dist_array($x) 5] label]
	lappend initsoftpar($x) [atominfo [lindex $bond_dist_array($x) 1] [lindex $bond_dist_array($x) 6] label]

	#puts "$initsoftpar($x)"
	#set atom types into array
	set i [lindex $bond_dist_array($x) 1]


	lappend ::sr_lookuplist1${i}($type1) $x
	lappend ::sr_lookuplist2${i}($type2) $x

	#add bond code to list element and key list
	lappend initsoftpar($x) $t2
	lappend ::sr_key_list $t2

	#create master list of bonds
	lappend ::sr_bond_list $initsoftpar($x)

	incr x
    }
}

#**************************************************************************************
# Procedure to sort soft restraints ---------------------------------------------
#**************************************************************************************
proc SR_Sort {whichbutton main alabel1 alabel2 dlabel1} {
    # reset all button labels
    $alabel1 config -text "Atom 1"
    $alabel2 config -text "Atom 2"
    if {$dlabel1 != ""} {$dlabel1 config -text "Distance"}

    if {$whichbutton == "atom1"} {
	if {$::sr_atom1_button == 1} {
	    set sr_prsort [lsort -integer -decreasing -index 1 $::sr_bond_list]

	    $alabel1 config -text "Atom 1 \u2193" -width 7
	} else {
	    set sr_prsort [lsort -integer -increasing -index 1 $::sr_bond_list]
	    $alabel1 config -text "Atom 1 \u2191" -width 7
	}
	set x [expr $::sr_atom1_button * -1]
	set ::sr_atom1_button $x
	#puts $::sr_atom1_button
    } elseif {$whichbutton == "atom2"} {
	if {$::sr_atom2_button == 1} {
	    set sr_prsort [lsort -integer -decreasing -index 2 $::sr_bond_list]
	    $alabel2 config -text "Atom 2 \u2193" -width 7
	} else {
	    set sr_prsort [lsort -integer -increasing -index 2 $::sr_bond_list]
	    $alabel2 config -text "Atom 2 \u2191" -width 7
	}
	set x [expr $::sr_atom2_button * -1]
	set ::sr_atom2_button $x
    } else {
	if {$::sr_distance_button == 1} {
	    #puts "distance"
	    set sr_prsort [lsort -increasing -index 8 $::sr_bond_list]
	    $dlabel1 config -text "Distance \u2193" -width 9
	} else {
	    set sr_prsort [lsort -decreasing -index 8 $::sr_bond_list]
	    $dlabel1 config -text "Distance \u2191" -width 9
	}
	set x [expr $::sr_distance_button * -1]
	set ::sr_distance_button $x
    }
    set ::sr_bond_list $sr_prsort
    SR_Fill_Display $main
}
#*********************************************************************************
#Procedure to set up soft display ************************************************
# used for editing window
#*********************************************************************************

proc SR_Display {args} {
    #global rprint
    destroy .mainrestraintbox.sr_rvaluebox
    set sr_rb .mainrestraintbox.sr_rvaluebox
    frame $sr_rb
    pack $sr_rb -side top -fill both -expand 1

    foreach {sr_top main side lbl} [MakeScrollTable $sr_rb] {}
    set     ::contraintmainbox $main

    button $sr_top.alabel1 -text "Atom 1 " -width 7   \
	-command "SR_Sort atom1 $main $sr_top.alabel1 $sr_top.alabel2 $sr_top.dlabel1"
    button $sr_top.alabel2 -text "Atom 2 " -width 7 \
	-command "SR_Sort atom2 $main $sr_top.alabel1 $sr_top.alabel2 $sr_top.dlabel1"
    button $sr_top.dlabel1 -text "Distance " -width 9 \
	-command "SR_Sort distance $main $sr_top.alabel1 $sr_top.alabel2 $sr_top.dlabel1"

    grid $sr_top.alabel1 -column 1 -row 2
    grid $sr_top.alabel2 -column 2 -row 2
    grid $sr_top.dlabel1 -column 3 -row 2

    label  $sr_top.rlabel1 -text "Restraint"
    label  $sr_top.rlabel2 -text "Tolerance"
    grid $sr_top.rlabel1 -column 4 -row 2 -padx 20
    grid $sr_top.rlabel2 -column 5 -row 2 -padx 20


    button $sr_top.rcon1   -text "Check\nAll" -width 4 -command "
	set ::sr_checkall 1;
	SR_Set_All_Check_Buttons;
	grid forget $sr_top.rcon1;
	grid $sr_top.rcon2 -column 6 -row 2 -padx 5;
    "

    button $sr_top.rcon2   -text "Clear\nAll" -width 4 -command "
	set ::sr_checkall 0;
	SR_Set_All_Check_Buttons;
	grid forget $sr_top.rcon2;
	grid $sr_top.rcon1 -column 6 -row 2 -padx 5;
    "

    grid $sr_top.rcon1   -column 6 -row 2 -padx 5

    #SR_Sort atom1 $main
    SR_Fill_Display  $main
    bind $sr_rb <Configure> "ResizeScrollTable $sr_rb"
    MouseWheelScrollTable $sr_rb
    # see if reset of grab fixes tk bug with tk_optionMenu
    grab release .mainrestraintbox
}

#*****************************************************************************************
#Procedure to fill in sorted Restraint and esd data **************************************
# used for both editing windows and restrain-only display in main EXPGUI window
#*****************************************************************************************
proc SR_Fill_Display {main args} {
    eval destroy [winfo children $main]
    set choice   $::sr_entryvar(choicenum)
    set atomreq1 $::sr_entryvar(softatom1)
    set atomreq2 $::sr_entryvar(softatom2)
    set phasereq $::sr_entryvar(softphase)
    set mode [string match "edit" $::sr_display_mode]

    set len [llength $::sr_bond_list]
    set rownum 0
    if {[string trim $::sr_dminvalue] == ""} {set ::sr_dminvalue 0}
    if {[string trim $::sr_dmaxvalue] == ""} {set ::sr_dmaxvalue 1000}
    for {set i 0} {$i <= $len} {incr i} {
	set rprint  [lindex $::sr_bond_list $i]
	set atomid1 [lindex $rprint 9]
	set atomid2 [lindex $rprint 10]
	if {$::sr_entryvar(softphase) == [lindex $rprint 0]} {
	    if {([lindex $rprint 8] >= $::sr_dminvalue || [lindex $rprint 8] == "?.???") && ([lindex $rprint 8] <= $::sr_dmaxvalue || [lindex $rprint 8] == "?.???")} {
		if {$atomreq1 == "" || $atomreq1 == "all" || $atomreq1 == $atomid1} {
		    if {$atomreq2 == "" || $atomreq2 == "all" || $atomreq2 == $atomid2} {
			if {$choice == 0 || ($choice == 1 && [string trim $::sr_restraintdist([lindex $rprint 13])] != "") \
				|| ($choice == 2 && [string trim $::sr_restraintdist([lindex $rprint 13])] == "") } {
			    label $main.ratom1$i -text [lindex $rprint 11] -justify center -anchor center
			    label $main.ratom2$i -text [lindex $rprint 12] -justify center -anchor center
			    if {$mode} {
				label $main.rdistance$i -text [lindex $rprint 8] -justify center -anchor center
				entry $main.restraint$i -width 8 -textvariable ::sr_restraintdist([lindex $rprint 13]) -takefocus 1
				$main.restraint$i selection range 0 end
                                bind  $main.restraint$i <KeyRelease> {SR_Validate_Soft %W distance}
				entry $main.restesd$i -width 8 -textvariable ::sr_restraintesd([lindex $rprint 13]) -takefocus 1
				$main.restesd$i selection range 0 end
				bind  $main.restesd$i <KeyRelease> {SR_Validate_Soft %W esd}
				checkbutton $main.sr_crestraint$i -variable ::sr_crestraint([lindex $rprint 13])
			    } else {
				label $main.restraint$i -width 8 -textvariable ::sr_restraintdist([lindex $rprint 13]) -takefocus 1  -justify center -anchor center
				label $main.restesd$i -width 8 -textvariable ::sr_restraintesd([lindex $rprint 13]) -takefocus 1   -justify center -anchor center
			    }
			    incr rownum
			    grid $main.ratom1$i -column 1 -row $rownum
			    grid $main.ratom2$i -column 2 -row $rownum
			    if {$mode} {
				grid $main.rdistance$i -column 3 -row $rownum
				grid $main.sr_crestraint$i -column 6 -row $rownum
				$main.ratom1$i conf -width 8
				$main.ratom2$i conf -width 8
				$main.rdistance$i conf -width 8
				bind $main.restraint$i <ButtonPress> {SR_Set_Rval %W}
			    }
			    grid $main.restraint$i -column 4 -row $rownum
			    grid $main.restesd$i -column 5 -row $rownum
			}
		    }
		}
	    }
	}
    }
}
#****************************************************************************
#Procedure for updating sr_rvalue and sr_resd Boxes *******************************
#****************************************************************************
proc SR_Set_Rval {window} {
    set ::sr_rvalue [$window get]
    set ::sr_resd [[regsub ".f.restraint" $window ".f.restesd"] get]
}

#****************************************************************************
#Error Checking Procedures for Entry Boxes **********************************
#****************************************************************************

proc SR_Validate_Num {val1} {
    # is it a valid number?
    if {[string trim $val1] != ""} {
	expr $val1
	if {$val1 < 0} {error}
    }
}

proc SR_Validate_Soft {win type} {
    set val [$win get]
    if {[catch {
        SR_Validate_Num $val
    }]} {
	# error on validation
        $win config -fg red
        $::srcb3.rbutton3 config -bg red -text "Invalid Restraints"
        set ::sr_error 1
    } else {
	# valid value
        $win config -fg black
        $::srcb3.rbutton3 config -bg LightGreen -text "Save Changes"
        set ::sr_error 0
    }
}

#**************************************************************************************
#Procedure to load current restraints, flag presetraints and build restraint only list
#**************************************************************************************
proc SR_Load_Restraints {args} {

    catch {unset ::sr_restraintdist}
    catch {unset ::sr_restraintesd}
    set temp_res [SoftConst restraintlist]
    set lenr [llength $temp_res]

    #for {set i 0} {$i < $lenr} {incr i} {
    #    set temp_res1 [lindex $temp_res $i]
    #}
    foreach temp_res1 $temp_res {
	set t1 "[lindex $temp_res1 0] [lindex $temp_res1 1] [lindex $temp_res1 2] \
            [lindex $temp_res1 3] [lindex $temp_res1 4] [lindex $temp_res1 5] \
            [lindex $temp_res1 6] [lindex $temp_res1 7]"
	set t2 [string map {" " ""} $t1]

	set test [lsearch -exact $::sr_key_list $t2]

        if {$test == -1} {
	    set new_restraint ""
	    set type1 [atominfo [lindex $temp_res1 0] [lindex $temp_res1 1] type]
	    set type1 [lindex [split $type1 {+-}] 0]
	    set type2 [atominfo [lindex $temp_res1 0] [lindex $temp_res1 2] type]
	    set type2 [lindex [split $type2 {+-}] 0]

	    lappend new_restraint [lindex $temp_res1 0] [lindex $temp_res1 1] \
		[lindex $temp_res1 2] [lindex $temp_res1 3] [lindex $temp_res1 4] \
		[lindex $temp_res1 5] [lindex $temp_res1 6] [lindex $temp_res1 7] \
		"?.???" $type1 $type2 \
		[atominfo [lindex $temp_res1 0] [lindex $temp_res1 1] label] [atominfo [lindex $temp_res1 0] [lindex $temp_res1 2] label] \
		$t2
	    set x [llength $::sr_bond_list]
	    lappend ::sr_lookuplist1($type1) $x
	    lappend ::sr_lookuplist2($type2) $x
	    lappend ::sr_bond_list $new_restraint
        }
        set ::sr_restraintdist($t2) [lindex $temp_res1 8]
        set ::sr_restraintesd($t2) [lindex $temp_res1 9]
    }
}


#*************************************************************************
#write soft restraints to file *******************************************
#*************************************************************************
proc SR_Write_Restraints { } {
    if {$::sr_error == 0} {
	set sr_write ""
	set new_list ""
	#	set len [llength $::sr_bond_list]
	set ::sr_key_list ""
        foreach temp $::sr_bond_list  {
	    #	for {set i 0} {$i <= [expr $len-1]} {incr i} {}
	    #	    set temp [lindex $::sr_bond_list $i]

	    if {[catch {
		if {[string trim $::sr_restraintdist([lindex $temp 13])] != ""} {
		    set softrest "[lindex $temp 0] [lindex $temp 1] \
                                [lindex $temp 2] [lindex $temp 3] [lindex $temp 4] \
                                [lindex $temp 5] [lindex $temp 6] [lindex $temp 7]\
                                $::sr_restraintdist([lindex $temp 13])\
                                $::sr_restraintesd([lindex $temp 13])"
		    lappend sr_write $softrest
		    #lappend new_list $temp
		}
	    } errmsg]} {puts "error: $errmsg"}
        }
	#
	#puts $sr_write
	# put the entire restraint list back into the .EXP file
	#puts "SoftConst restraintlist set $sr_write"
	SoftConst restraintlist set $sr_write
        RecordMacroEntry "SoftConst restraintlist set $sr_write" 0
	#set ::sr_bond_list $new_list
	# indicate a change to the .EXP file
	incr ::expgui(changed)
	# close the window and return access to main window
	destroy .mainrestraintbox
	set ::sr_display_mode noedit
	afterputontop
	SR_Rest_Only
	DisplayDistanceRestraints
    } else {
	bell
	#puts "invalid restaint / esd.  Save aborted"
    }
}

#*********************************************************************************
#Procedure to update restraints *************************************************
#*********************************************************************************
proc SR_Update_Restraints {args} {
    foreach i [array names ::sr_crestraint] {
	if {$::sr_crestraint($i) == 1} {
	    #puts "::sr_restraintdist($i) $::sr_rvalue"
	    set ::sr_restraintdist($i) $::sr_rvalue
	    set ::sr_restraintesd($i) $::sr_resd
	}
    }
}

#*******************************************************************************
#Procedure to delete restraints ************************************************
#*******************************************************************************

proc SR_Delete_Restraints {args} {
    foreach i [array names ::sr_crestraint] {
	if {$::sr_crestraint($i) == 1} {
	    set ::sr_restraintdist($i) ""
	    set ::sr_restraintesd($i) ""
	}
    }
}

#*********************************************************************************
#set flag for restraint update ***************************************************
#*********************************************************************************
proc SR_Set_All_Check_Buttons { } {
    # loop over all widgets in main frame
    foreach w [winfo children $::contraintmainbox] {
	# pick out checkboxes which have crest
	if {[string first crest $w] != -1} {
	    $w deselect
	    if {$::sr_checkall} {
		$w invoke
	    }
	}
    }
}

#*********************************************************************************
#Main Program Begin***************************************************************
#*********************************************************************************
proc SR_Main_Editor {args} {

    catch {destroy .mainrestraintbox}
    set mrb .mainrestraintbox
    toplevel $mrb
    #pack $mrb -side top
    wm title $mrb "Soft Restraint Control Panel for Phase $::sr_entryvar(softphase)"
    #wm geometry $mrb 415x500+10+10
    #wm geometry $mrb {}
    set srcb1 $mrb.srconbox1
    set srcb2 $mrb.srconbox2
    set ::srcb3 $mrb.srconbox3
    frame $srcb1 -bd 2 -relief groove -pady 5
    frame $srcb2 -bd 2 -relief groove -pady 5
    frame $::srcb3 -bd 2 -relief groove -pady 5
    pack $srcb1 -side top -anchor w -fill x
    pack $srcb2 -side top -anchor w -fill x
    pack $::srcb3 -side bottom -anchor w -fill x

    label $srcb1.atomlabel1   -text "Atom 1 Filter"
    label $srcb1.atomlabel2   -text "Atom 2 Filter"
    label $srcb1.dminlabel    -text "Dmin"
    label $srcb1.dmaxlabel    -text "Dmax"
    label $srcb2.restlabel    -text "Restraint Value" -width 16 -anchor w
    label $srcb2.restlabelesd -text "Tolerance"

    eval tk_optionMenu $srcb1.atom1 ::sr_entryvar(softatom1) "[lsort [array names ::sr_lookuplist1${::sr_entryvar(softphase)}]] all"
    eval tk_optionMenu $srcb1.atom2 ::sr_entryvar(softatom2) "[lsort [array names ::sr_lookuplist2${::sr_entryvar(softphase)}]] all"


    entry  $srcb1.sr_dminvalue -width 8 -textvariable ::sr_dminvalue        -takefocus 1
    $srcb1.sr_dminvalue selection range 0 end
    entry  $srcb1.sr_dmaxvalue -width 8 -textvariable ::sr_dmaxvalue        -takefocus 1
    $srcb1.sr_dmaxvalue selection range 0 end
    entry  $srcb2.sr_rvalue    -width 8 -textvariable ::sr_rvalue           -takefocus 1
    $srcb2.sr_rvalue selection range 0 end
    entry  $srcb2.sr_resd      -width 8 -textvariable ::sr_resd             -takefocus 1
    $srcb2.sr_resd selection range 0 end

    bind  $srcb1.sr_dminvalue <KeyRelease> {SR_Validate_Soft %W dmin}
    bind  $srcb1.sr_dmaxvalue <KeyRelease> {SR_Validate_Soft %W dmax}
    bind  $srcb2.sr_rvalue    <KeyRelease> {SR_Validate_Soft %W sr_rvalue}
    bind  $srcb2.sr_resd      <KeyRelease> {SR_Validate_Soft %W sr_resd}

    button $srcb1.recalc   -text "Filter" -bd 6 -command {SR_Display}
    button $srcb2.rbutton1 -text "Set checked" -command {SR_Update_Restraints}
    button $srcb2.rbutton2 -text "Delete checked" -command {SR_Delete_Restraints}
    button $::srcb3.rbutton3 -text "Save changes" -bd 6 -bg LightGreen -command {SR_Write_Restraints}
    button $::srcb3.rbutton4 -text "Cancel" -command {
	destroy .mainrestraintbox
	afterputontop
	SR_Rest_Only
	DisplayDistanceRestraints
    }
    wm protocol .mainrestraintbox WM_DELETE_WINDOW {
	destroy .mainrestraintbox
	afterputontop
	SR_Rest_Only
	DisplayDistanceRestraints
    }

    grid $srcb1.atomlabel1   -column 1 -row 0
    grid $srcb1.atom1        -column 2 -row 0
    $srcb1.atom1 conf -width 2
    grid $srcb1.atomlabel2   -column 1 -row 1
    grid $srcb1.atom2        -column 2 -row 1
    $srcb1.atom2 conf -width 2
    grid $srcb1.recalc       -column 4 -row 2 -padx 5
    $srcb1.recalc conf -width 7

    grid $srcb1.dminlabel       -column 3 -row 0
    grid $srcb1.sr_dminvalue    -column 4 -row 0
    grid $srcb1.dmaxlabel       -column 3 -row 1
    grid $srcb1.sr_dmaxvalue    -column 4 -row 1


    set choice {"Show All Bonds" "Restrained Bonds" "Unrestrained Bonds"}

    set m1 [eval tk_optionMenu $srcb1.rcon3 sr_entryvar(choice) $choice]
    # set up a variable to track menu choices by number. Do this by adding a command
    # to each item in the option menu
    foreach i {0 1 2} {
	$m1 entryconfig $i -command "set ::sr_entryvar(choicenum) $i"
    }
    grid $srcb1.rcon3 -column 1 -row 2 -padx 5
    $srcb1.rcon3 config -width 23
    grid configure $srcb1.rcon3 -columnspan 2

    grid $srcb2.restlabel    -column 0 -row 3 -sticky w
    grid $srcb2.sr_rvalue    -column 1 -row 3
    grid $srcb2.restlabelesd -column 2 -row 3
    grid $srcb2.sr_resd      -column 3 -row 3
    grid $srcb2.rbutton1     -column 4 -row 3 -padx 5
    grid $srcb2.rbutton2     -column 5 -row 3 -padx 5

    grid $::srcb3.rbutton3     -column 0 -row 0
    grid $::srcb3.rbutton4     -column 0 -row 1 -pady 5

    # remove traces
    foreach item [trace vinfo ::sr_entryvar(softatom1)] {
        eval trace vdelete ::sr_entryvar(softatom1) $item
    }
    foreach item [trace vinfo ::sr_entryvar(softatom2)] {
        eval trace vdelete ::sr_entryvar(softatom2) $item
    }
    foreach item [trace vinfo ::sr_entryvar(choicenum)] {
        eval trace vdelete ::sr_entryvar(choicenum) $item
    }
    # reset filter vars
    set ::sr_entryvar(choice) "Show All Bonds"
    set ::sr_entryvar(choicenum) 0
    set ::sr_entryvar(softatom1) "all"
    set ::sr_entryvar(softatom2) "all"
    # search out distances
    SR_Display
    # set traces for future changes to filter vars
    trace variable ::sr_entryvar(softatom1) w SR_Display
    trace variable ::sr_entryvar(choicenum) w SR_Display
    trace variable ::sr_entryvar(softatom2) w SR_Display
    # make editor window modal (lock it on top)
    putontop $mrb
}

# load restraints w/o distances
proc SR_Rest_Only {} {
    set ::sr_display_mode noedit
    catch {unset ::sr_lookuplist1}
    catch {unset ::sr_lookuplist2}
    set ::sr_bond_list ""
    set ::sr_key_list ""
    SR_Load_Restraints
}

# load distances, restraints and make editing box
proc SR_TEST {} {
    # Run DISAGL
    global expgui
    pleasewait "searching interatomic distances"
    # save EXP file if changed
    savearchiveexp
    set root [file root $expgui(expfile)]
    catch {file delete -force $root.disagl}
    set ::sr_display_mode edit
    close [open disagl.inp w]
    catch {exec [file join $expgui(gsasexe) disagl] \
	       [file tail $root] < disagl.inp > disagl.out}
    catch {file delete -force disagl.inp disagl.out}
    if {! [file exists $root.disagl]} {
	MyMessageBox -parent . -title "DISAGL Problem" \
	    -message "Unable to run DISAGL. Do you have problems writing files in [pwd]?" \
	    -icon error
	donewait
	return
    }
    # load DISAGL distances
    SR_Read_Distances $root.disagl
    SR_Load_Restraints
    SR_Main_Editor
    donewait
}
