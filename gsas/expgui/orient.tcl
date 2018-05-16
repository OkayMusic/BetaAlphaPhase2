# $Revision: 1251 $ $Date: 2014-03-10 22:17:29 +0000 (Mon, 10 Mar 2014) $
# Pamela Whitfield & Brian Toby
# a GUI for March-Dollase preferred orientation
# revised labeling as per egbert.keller@krist.uni-freiburg.de (msg of 12/13/02)

proc MakeOrientPane {} {
    global expgui expmap
    pack [frame $expgui(orientFrame).hs -class HistList] \
	    -side left -expand y -fill both
    MakeHistBox $expgui(orientFrame).hs
    bind $expgui(orientFrame).hs.lbox <ButtonRelease-1> {
	set expgui(curhist) [$expgui(orientFrame).hs.lbox curselection]
	DisplayOrient
    }
    bind $expgui(orientFrame).hs.lbox <Button-3>  {
	if $expgui(globalmode) {
	    $expgui(orientFrame).hs.lbox selection set 0 end
	    set expgui(curhist) [$expgui(orientFrame).hs.lbox curselection]
	    DisplayOrient
	}
    }

    # Create a frame on the right side
    pack [TitleFrame $expgui(orientFrame).f1 -bd 4 \
	      -text "March-Dollase Preferential Orientation" \
	      -relief groove] -fill both -expand true
    set PrefOrientBox [$expgui(orientFrame).f1 getframe]

    grid columnconfigure $PrefOrientBox 0 -weight 1
    grid rowconfigure $PrefOrientBox 1 -weight 1
    # Create canvas with a frame inside for scrolling
    grid [set expgui(OrientBox) [canvas $PrefOrientBox.orientBox \
	    -scrollregion {0 0 5000 500} \
	    -yscrollcommand "$PrefOrientBox.yscroll set" \
	    -width 500 -height 350 -bg lightgrey]] \
	    -sticky news -row 1 -column 0
    set expgui(OrientScroll) [scrollbar $PrefOrientBox.yscroll \
	    -command "$expgui(OrientBox) yview" \
	    -orient vertical]
    # control the griding of the scrollbar in DisplayOrient
    #grid $PrefOrientBox.yscroll -sticky ns -row 1 -column 1
    frame $expgui(OrientBox).f -bd 0	
    $expgui(OrientBox) create window 0 0 -anchor nw \
	    -window $expgui(OrientBox).f 

    # insert the histograms & resize in case the pane needs more space
    sethistlist
#    ResizeNotebook
}

# this is used to update the contents of the PO page when histogram(s)
# are selected
proc DisplayOrient {} {
    global expgui entrycmd entryvar entrybox expmap
	
    # identify the frame and kill the old contents
    set pOrientf1 $expgui(OrientBox).f
    eval destroy [winfo children $pOrientf1]
    grid columnconfig $pOrientf1 0 -weight 1
    grid columnconfig $pOrientf1 15 -weight 1
    grid columnconfig $pOrientf1 9 -min 10
    grid columnconfig $pOrientf1 12 -min 10
    # trap if more than one histogram is selected unless global mode
    if {$expgui(globalmode) == 0 && [llength $expgui(curhist)] > 1} {
	set expgui(curhist) [lindex $expgui(curhist) 0]
    }

    # display the selected histograms
    $expgui(orientFrame).hs.lbox selection clear 0 end
    foreach h $expgui(curhist) {
	$expgui(orientFrame).hs.lbox selection set $h
    }

    #disable traces on entryvar
    set entrycmd(trace) 0
    trace vdelete entryvar w entvartrace
    
    #display selected histograms
    $expgui(orientFrame).hs.lbox selection clear 0 end
    foreach hist $expgui(curhist) {
	$expgui(orientFrame).hs.lbox selection set $hist
    }

    #get histogram list by histogram number
    set histlist {}
    foreach item $expgui(curhist) {
	lappend histlist [lindex $expmap(powderlist) $item]
    }

    # loop over histograms and phases
    set row -1
    foreach hist $histlist {
	foreach phase $expmap(phaselist_$hist) {
	    grid [frame $pOrientf1.sp$row -bd 8 -bg white] \
		-columnspan 20 -column 0 -row [incr row] -sticky nsew
	    # add extra label here when more than one histogram is selected
	    if {[llength $histlist] > 1} {
		set lbl "Histogram $hist\nPhase $phase"
	    } else {
		set lbl "Phase $phase"
	    }
	    grid [label $pOrientf1.l1$row -text $lbl] \
		    -column 0 -row [incr row] -sticky nws
	    set naxis [hapinfo $hist $phase POnaxis]
	    set col 0
	    foreach var {h k l} lbl {h k l} {
		grid [label $pOrientf1.l${var}$row -text $lbl \
			-anchor center] \
			-column [incr col] -row $row -sticky ews
	    }
	    grid [label $pOrientf1.lrat$row -text "Ratio" -anchor center] \
		    -column 10 -row $row -sticky ews
	    if {$naxis > 1} {
		grid [label $pOrientf1.lfrac$row -text "Fraction" \
			-anchor center] \
			-column 13 -row $row -sticky ews
	    }
	    grid [label $pOrientf1.ld$row -text "Damping"] \
		    -column 15 -row $row -sticky es
	    for {set axis 1} {$axis <= $naxis} {incr axis} {
		set phax ${phase}_$axis
		# define variables needed
		foreach var {ratio fraction ratioref fracref damp type} {
		    set entrycmd(${var}$phax) \
			    "MDprefinfo $hist $phase $axis $var"
		    set entryvar(${var}$phax) [eval $entrycmd(${var}$phax)]
		}
		foreach var {h k l} {
		    set entrycmd(${var}$phax) \
			    "MDprefinfo $hist $phase $axis $var"
		    set entryvar(${var}$phax) \
			    [format %.2f [eval $entrycmd(${var}$phax)]]
		}
		incr row
		set col -1
		grid [label $pOrientf1.axis$row -text "Plane $axis"\
			-anchor center ] \
			-column [incr col] -row $row
		set col 0
		# Axis
		foreach var {h k l} {
		    grid [entry $pOrientf1.e${var}$row \
			    -textvariable entryvar(${var}$phax) -width 4] \
			    -column [incr col] -row $row
		    set entrybox(${var}$phax) $pOrientf1.e${var}$row
		}
		# Ratio
		grid [entry $pOrientf1.erat$row \
			-textvariable entryvar(ratio$phax) -width 10] \
			-column 10 -row $row -sticky e
		set entrybox(ratio$phax) $pOrientf1.erat$row
		# ratio refine
		grid [checkbutton $pOrientf1.ratref$row \
			-variable entryvar(ratioref$phax)] \
			-column 11 -row $row -sticky w
		if {$naxis > 1} {
		    # Fraction
		    grid [entry $pOrientf1.efrac$row \
			    -textvariable entryvar(fraction$phax) -width 10] \
			    -column 13 -row $row -sticky e
		    set entrybox(fraction$phax) $pOrientf1.efrac$row
		    # fraction refine
		    grid [checkbutton $pOrientf1.fracref$row \
			    -variable entryvar(fracref$phax)] \
			    -column 14 -row $row -sticky w
		}
  		#damp
		tk_optionMenu $pOrientf1.opd$row \
			entryvar(damp$phax) \
			0 1 2 3 4 5 6 7 8 9
		grid $pOrientf1.opd$row \
			-column 15 -row $row -sticky e
	    }
	    grid [button $pOrientf1.add$row -text "Add plane" \
		    -command "AddNewPOaxis $hist $phase"] \
		    -column 0 -columnspan 4 -row [incr row] -sticky nws

	}
    }
    grid [frame $pOrientf1.sp$row -bd 8 -bg white] \
	    -columnspan 20 -column 0 -row [incr row] -sticky nsew

    # resize the scroll area
    update
    set sizes [grid bbox $pOrientf1]
    $expgui(OrientBox) config -scrollregion $sizes -width [lindex $sizes 2]
    # use the scroll for BIG lists
    if {[lindex $sizes 3] > [winfo height $expgui(OrientBox)]} {
	grid $expgui(OrientScroll) -sticky ns -column 1 -row 1
    } else {
	grid forget $expgui(OrientScroll)
    }
    update
    #enable traces on entryvar now
    set entrycmd(trace) 1
    trace variable entryvar w entvartrace
    ResizeNotebook
}

proc AddNewPOaxis {hist phase} {
    global expgui
    set nextaxis [hapinfo $hist $phase POnaxis]
    incr nextaxis
    if {$nextaxis > 9} return
    MDprefinfo $hist $phase $nextaxis new set
    RecordMacroEntry "MDprefinfo $hist $phase $nextaxis new set" 0
    hapinfo $hist $phase POnaxis set $nextaxis
    RecordMacroEntry "hapinfo $hist $phase POnaxis set $nextaxis" 0
    incr expgui(changed)
    RecordMacroEntry "incr expgui(changed)" 0
    DisplayOrient
}
