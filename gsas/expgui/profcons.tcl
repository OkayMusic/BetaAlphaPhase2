# Implement profile constraints
# $Revision: 1251 $ $Date: 2014-03-10 22:17:29 +0000 (Mon, 10 Mar 2014) $


# make the profile constraints pane
proc MakeProfileConstraintsPane {} {
    global expgui expcons

    grid [button $expcons(profilemaster).del -text "Delete" \
	    -command "DeleteProfileConstraints"] \
	    -column 1 -sticky se -row 1 -columnspan 2
    grid [button $expcons(profilemaster).add -text "Add Constraint" \
		    -command "NewProfileConstraint"] \
		    -column 0 -row 1 -sticky sw
    grid [canvas $expcons(profilemaster).canvas \
	    -scrollregion {0 0 5000 1000} -width 400 -height 250 \
	    -yscrollcommand "$expcons(profilemaster).scroll set"] \
	    -column 0 -row 0 -columnspan 2 -sticky nsew \
	    
    grid columnconfigure $expcons(profilemaster) 0 -weight 0
    grid rowconfigure $expcons(profilemaster) 0 -weight 1
    grid rowconfigure $expcons(profilemaster) 1 -pad 5
    grid [scrollbar $expcons(profilemaster).scroll \
	    -command "$expcons(profilemaster).canvas yview"] \
	    -row 0 -column 2 -sticky ns
}

# read and display the profile constraints
proc DisplayProfileConstraints {} {
    global expgui expcons expmap

    pleasewait "Processing constraints"	
    catch {destroy $expcons(profilemaster).canvas.fr}
    set top [frame $expcons(profilemaster).canvas.fr]
    $expcons(profilemaster).canvas create window 0 0 -anchor nw -window $top
    set col -1
    set row -1

    # column headings
    incr row
    set col 0
    grid [label $top.h$col -text profile\nterm] \
	    -column $col -row $row -columnspan 3
    incr col 4
    grid [label $top.h$col -text "#"] \
	    -column $col -row $row 
    grid columnconfigure $top $col -pad 8
    incr col 3
    grid [label $top.h$col -text "  Phase"] -column $col -row $row
    grid columnconfigure $top $col -pad 8
    incr col
    grid [label $top.h$col -text Histograms] -column $col -row $row
    grid columnconfigure $top $col -pad 8
    incr col
    grid [label $top.h$col -text Multiplier] -column $col -row $row
    grid columnconfigure $top $col -pad 8
    incr col 2
    grid [label $top.h$col -text delete\nflag] -column $col -row $row
    grid columnconfigure $top $col -pad 8

    incr row
    # vertical spacers
    foreach col {3 10} {
	grid [frame $top.vs$col -bd 8 -bg white] \
		-column $col -row $row -rowspan 999 -sticky nsew
	grid columnconfig $top $col -minsize 2 -pad 2
    }

    # loop over used profile terms
    set msg {}
    for {set i 1} {$i <= 36} {incr i} {
	set ncons [constrinfo profile$i get 0]
	if {$ncons == 0} continue
	# loop over constraints to look for duplicate phase/hist entries
	catch {unset varlist}
	for {set j 1} {$j <= $ncons} {incr j} {
	    # get the constraint list
	    set conslist [constrinfo profile$i get $j]
	    foreach item $conslist {
		set phaselist [lindex $item 0]
		set histlist [lindex $item 1]
		if {$phaselist == "ALL"} {set phaselist $expmap(phaselist)}
		if {$histlist == "ALL"} {set histlist $expmap(powderlist)}
		# tabulate phase/parameters used
		foreach p $phaselist {
		    foreach h $histlist {
			lappend varlist(${h}_$p) $j
		    }
		}
	    }
	}
	# scan for repeated references to phase/histogram combinations
	catch {unset errarr errarr1}
	set errlist {}
	foreach n [array names varlist] {
	    if {[llength $varlist($n)] > 1} {
		regexp {(.*)_(.*)} $n dummy h p
		if [catch {set errarr($p)}] {
		    set errarr($p) {}
		    set errarr1($p) {}
		}
		# tabulate histograms by phase
		lappend errarr($p) $h
		# make a list of constraints
		foreach c $varlist($n) {
		    if {[lsearch $errarr1($p) $c] == -1} {
			lappend errarr1($p) $c
		    }
		}
		eval lappend errlist $varlist($n)
	    }
	}
	catch {
	    foreach p [array names errarr] {
		if {[llength $errarr($p)] >0} {
		    append msg " Term #$i: phase $p, histogram(s) [CompressList $errarr($p)]"
		    append msg " in constraints [CompressList $errarr1($p)]\n"
		}
	    }
	}
	incr row
	# put a spacer between each term
	grid [frame $top.spa$row -bd 8 -bg white] \
		-columnspan 16 -column 0 -row $row -sticky nsew
	grid rowconfig $top $row -minsize 2 -pad 2
	incr row
	set row1 $row
	# loop over the defined constraints
	for {set j 1} {$j <= $ncons} {incr j} {
	    set row0 $row
	    # get the constraint list
	    set conslist [constrinfo profile$i get $j]

	    # reformat the constraint info
	    set conslist [SortProfileConstraints $conslist]
	    # set the phase & histogram type from the first entry in the list
	    set item [lindex $conslist 0]
	    set h [lindex [lindex $item 1] 0]
	    # trap a bad histogram code -- don't know how this happens, though
	    if {$h == ""} continue
	    if {$h == "ALL"} {set h [lindex $expmap(powderlist) 0]}
	    set p [lindex [lindex $item 0] 0]
	    if {$p == "ALL"} {set p [lindex $expmap(phaselist_$h) 0]}
	    # profile type
	    set ptype [string trim [hapinfo $h $p proftype]]
	    # histogram type 
	    set htype [string range $expmap(htype_$h) 2 2]    
	    # get the profile term labels
	    set lbl [lindex "dummy [GetProfileTerms $p $h $ptype]" $i]
	    if {$lbl == ""} {set lbl ?}

	    foreach item $conslist {
		set col 6
		incr row
		grid [label $top.tn${row}-$col \
			-text [CompressList [lindex $item 0]]] \
			-column [incr col] -row $row
		grid [label $top.tn${row}-$col \
			-text [CompressList [lindex $item 1]]] \
			-column [incr col] -row $row
		grid [label $top.tn${row}-$col -text [lindex $item 2]] \
			-column [incr col] -row $row
		incr col
	    }
	    incr row
	    grid [label $top.ts$row0 -text $j] -column 4 \
		    -row $row0 -rowspan [expr $row - $row0]
	    if {[lsearch $errlist $j] != -1} {$top.ts$row0 config -fg red}
	    grid [label $top.tu$row0 -text "($lbl)"] -column 2 \
		-row $row0 -rowspan [expr $row - $row0]
	    grid [button $top.edit$row0 -text edit \
		    -command "EditProfileConstraint $i $j [list $conslist]" \
		    ] -column 5 -row $row0 -rowspan [expr $row - $row0]
	    set expcons(delete${i}_$j) 0
	    grid [checkbutton $top.del$row0 \
		    -variable expcons(delete${i}_$j)] -column 11 \
		    -row $row0 -rowspan [expr $row - $row0]
	    if {$j < $ncons} {
		# put a spacer between each term
		grid [frame $top.spb$row -bd 1 -bg white] \
			-columnspan 11 -column 3 -row $row -sticky nsew
		grid rowconfig $top $row -minsize 1 -pad 1
		incr row
	    }
	}
	grid [label $top.tt$row -text "#$i  "] -column 0 \
		-row $row1 -rowspan [expr $row - $row1]
    }
    # resize the canvas & scrollbar
    update idletasks
    set sizes [grid bbox $top]
    $expcons(profilemaster).canvas config -scrollregion $sizes
    set hgt [lindex $sizes 3]
    # set the maximum height for the canvas from the frame
    set maxheight [expr \
	    [winfo height [winfo parent $expgui(consFrame)]] - 130]

    # use the scroll for BIG constraint lists
    if {$hgt > $maxheight} {
	grid $expcons(profilemaster).scroll -sticky ns -column 2 -row 0
    } else {
	grid forget $expcons(profilemaster).scroll
    }
    $expcons(profilemaster).canvas config \
	    -height $maxheight \
	    -width [lindex $sizes 2]
    $expgui(consFrame).n compute_size
    donewait
    if {$msg != ""} {
	set msg "Error: a phase/histogram profile can appear in only one constraint. Here is a list of parameters that are referenced in more than one constraint:\n\n$msg"
	MyMessageBox -icon error -message $msg \
		-helplink "expgui6.html ProfileConstraintErr" \
		-parent [winfo toplevel $expgui(consFrame)] 
    }
}


# summarize profile constraints:
# group histograms that have the same phase & mult
proc SortProfileConstraints {conslist} {
    # grouped list
    set glist {}
    # previous phase
    set pp 0
    # phase list
    set pplist {}
    # sort list on phase (add a dummy element)
    foreach item "[lsort -index 0 $conslist] {0 0 0}" {
	set p [lindex $item 0]
	if {$p != $pp} {
	    # ok have a list containing only 1 phase
	    if {$pp != 0} {
		set mp 0
		set hl {}
		foreach item2 "[lsort -index 2 -decreasing -real $pplist] {0 0 0}" {
		    set m [lindex $item2 2]
		    if {$m != $mp} {
			# have a list containing 1 phase and the same multiplier
			if {$mp != 0} {
			    # do we another entry with the same multiplier
			    set hl [lsort $hl]
			    set i 0
			    foreach item3 $glist {
				if {[lindex $item3 1] == $hl && \
					[lindex $item3 2] == $mp} {
				    # got one that matches
				    # add the phase & replace it
				    set pp "[lindex $item3 0] $pp"
				    set glist [lreplace \
					    $glist $i $i \
					    "[list $pp] [list $hl] $mp"]
				    break
				}
				incr i
			    }
			    # we have looped all the way through
			    # not matched, so add it to the list
			    if {$i == [llength $glist]} {
				lappend glist "$pp [list $hl] $mp"
			    }
			}
			set mp $m
			set hl [lindex $item2 1]
		    } else {
			lappend hl [lindex $item2 1]
		    }
		}
	    }
	    set pp $p
	    set pplist [list $item]
	} else {
	    lappend pplist $item
	}
    }
    return $glist
}

# called to edit a single profile constraint set
proc EditProfileConstraint {term num conslist} {
    global expcons expmap expgui

    set top {.editcons}
    catch {toplevel $top}
    eval destroy [grid slaves $top]
    bind $top <Key-F1> "MakeWWWHelp expgui6.html EditProfileConstraints"

    if {$num != "add"} {
	# set the phase & histogram type from the first entry in the list
	set item [lindex $conslist 0]
	set h [lindex [lindex $item 1] 0]
	if {$h == "ALL"} {set h [lindex $expmap(powderlist) 0]}
	set p [lindex [lindex $item 0] 0]
	if {$p == "ALL"} {set p [lindex $expmap(phaselist_$h) 0]}
	# profile type
	set ptype [string trim [hapinfo $h $p proftype]]
	# histogram type 
	set htype [string range $expmap(htype_$h) 2 2]    
	set expcons(ProfileHistType) [string range $expmap(htype_$h) 2 2]    
    } else {
	set p $expcons(ProfilePhase)
	set ptype $expcons(ProfileFunction)
	set htype $expcons(ProfileHistType)
    }
    set lbls "dummy [GetProfileTerms $p $htype $ptype]"
    # get the cached copy of the profile term labels, when possible
    if {$num != "add"} {
	wm title $top "Constraint #$num for term $term"
	set lbl [lindex $lbls $term]
	if {$lbl == ""} {set lbl ?}
	set txt "Editing constraint #$num for term $term ($lbl)"
    } else {
	wm title $top "New constraint for term(s) [CompressList $term]"
	set txt "Editing new constraint for term(s) "
	set i 0
	foreach t $term {
	    set lbl [lindex $lbls $t]
	    if {$lbl == ""} {set lbl ?}
	    if {$i == 3 || $i == 10 || $i == 16 || $i == 22} {
		append txt ",\n"
	    } elseif {$i != 0} {
		append txt ", "
	    }
	    append txt "$t ($lbl)"
	    incr i
	}
    }
    grid [label $top.top -text $txt -anchor w] -column 0 -row 0 -columnspan 20

    if {$expcons(ProfileHistType) == "T"} {
	set type "TOF"
    } elseif {$expcons(ProfileHistType) == "C"} {
	set type "Constant Wavelength"
    } elseif {$expcons(ProfileHistType) == "E"} {
	set type "Energy Dispersive X-ray"
    }
    grid [label $top.typ -text "Histogram type: $type"] \
	    -column 0 -row 1 -columnspan 20
    grid [canvas $top.canvas \
	    -scrollregion {0 0 5000 500} -width 100 -height 50 \
	    -xscrollcommand "$top.scroll set"] \
	    -column 0 -row 2 -columnspan 4 -sticky nsew
    grid columnconfigure $top 3 -weight 1
    grid rowconfigure $top 2 -weight 1
    catch {destroy $top.scroll}
    scrollbar $top.scroll -orient horizontal \
	    -command "$top.canvas xview"
    #    grid $top.scroll -sticky ew -column 0 -row 2 -columnspan 4
    # create a scrollable frame inside the canvas
    set cfr [frame $top.canvas.fr -class HistList]
    $top.canvas create window 0 0 -anchor nw  -window $cfr

    grid [button $top.add -text "New Column" \
	    -command "NewProfileConstraintColumn $top $cfr" \
	    ] -column 0 -row 4  -columnspan 2 -sticky ew
    grid [button $top.done -text "Save" \
	    -command "SaveProfileConstraint $num [list $term] $top" \
	    ] -column 0 -row 5 -sticky ns
    grid [button $top.quit -text "Cancel\nChanges" \
	    -command "CancelEditProfileConstraint $top $num" \
	    ]  -column 1 -row 5
    grid [button $top.help -text Help -bg yellow \
	    -command "MakeWWWHelp expgui6.html EditProfileConstraints"] \
	    -column 2 -row 4 -columnspan 99 -rowspan 2 -sticky e

    set col 0
    set row 2
    # row headings
    grid rowconfigure $cfr 6 -weight 1
    foreach lbl {Phase(s) Histogram(s) Multiplier} {
	# row separator
	grid [frame $cfr.spd$row -bd 8 -bg white] \
		-columnspan 60 -column 0 -row [incr row] -sticky nsew
	grid rowconfig $cfr $row -minsize 2 -pad 2
	grid [label $cfr.t$row -text $lbl] -column $col -row [incr row]
    }

    # row separator
    grid [frame $cfr.spe$row -bd 8 -bg white] \
	    -columnspan 60 -column 0 -row [incr row] -sticky nsew
    grid rowconfig $cfr $row -minsize 2 -pad 2

    set ic 0
    set col 1
    foreach constr $conslist {
	incr ic
	MakeProfileConstraintColumn $cfr $ic $col
	FillProfileConstraintColumn $cfr $ic $col
	incr col 3
    }
    if {$conslist == ""} {NewProfileConstraintColumn $top $cfr}
    # resize the canvas & scrollbar
    update idletasks
    set sizes [grid bbox $cfr]
    $top.canvas config -scrollregion $sizes
    set width [lindex $sizes 2]
    # use the scroll for BIG constraints
    if {$width > 600} {
	set width 600
	grid $top.scroll -sticky ew -column 0 -row 3 -columnspan 4
    }
    $top.canvas config -height [lindex $sizes 3] -width $width
    set ic 0
    set col 1
    foreach constr $conslist {
	incr ic
	SelectProfileConstraintColumn $cfr $ic $col $constr
	incr col 3
	set expcons(mult$ic) [lindex $constr 2]
    }
    # force the window to stay on top
    putontop $top
    tkwait window $top
    afterputontop
}

# called when the "Cancel Changes" button is pressed
proc CancelEditProfileConstraint {top num} {
    global expcons
    if {$num == "add"} {destroy $top; return}
    set ans [MyMessageBox -type "{Abandon Changes} {Continue Edit}" \
	    -parent [winfo toplevel $top] -default "abandon changes" \
	    -helplink "expguierr.html AbandonEditConstraints" \
	    -icon warning -message  \
	    {Do you want to lose any changes made to this constraint?}]
    if {$ans == "abandon changes"} {destroy $top}
}

# called to make each column in the atom parameter dialog
proc MakeProfileConstraintColumn {cfr ic col} {
    global expmap expcons expgui
    set row 2
    # make column separator
    grid [frame $cfr.spc$col -bd 8 -bg white] \
	    -rowspan 7 -column $col -row $row -sticky nsew
    grid columnconfig $cfr $col -minsize 2 -pad 2
    set col1 [incr col]
    set col2 [incr col]
    # make the phase listbox
    set expcons(phaselistbox$ic) $cfr.lbp$ic
    grid [listbox $cfr.lbp$ic \
	    -height [llength $expmap(phaselist)] -width 12 \
	    -exportselection 0 -selectmode extended] \
	    -column $col1 -columnspan 2 -row [incr row 2] -sticky nsew
    bind $expcons(phaselistbox$ic) <Button-3> \
	    "$expcons(phaselistbox$ic) selection set 0 end"
    # make the histogram listbox
    set expcons(histlistbox$ic) $cfr.lbh$ic
    grid [listbox $cfr.lbh$ic -height 10 -width 12 \
	    -exportselection 0 -selectmode extended \
	    -yscrollcommand " $cfr.sbh$ic set"] \
	    -column $col1 -row [incr row 2] -sticky nse
    bind $expcons(histlistbox$ic) <Button-3> \
	    "$expcons(histlistbox$ic) selection set 0 end"
    grid [scrollbar $cfr.sbh$ic -command "$cfr.lbh$ic yview"] \
	    -column $col2 -row $row -sticky wns
    # multiplier
    grid [entry $cfr.c${col}$ic -width 10 \
	    -textvariable expcons(mult$ic)] \
	    -column $col1 -row [incr row 2] -columnspan 2
}


# called to fill the contents of each column in the atom parameter dialog
proc FillProfileConstraintColumn {cfr ic col "constr {}"} {
    global expmap expcons expgui
    # now insert the phases into the list
    set i 0
    foreach phase $expmap(phaselist) {
	$expcons(phaselistbox$ic) insert end "$phase  [phaseinfo $phase name]"
	incr i
    }
    # if there is only 1 choice, select it
    if {[llength $expmap(phaselist)] == 1} {
	$expcons(phaselistbox$ic) selection set 0
    }
    # now insert the histograms into the list
    set i 0
    foreach h $expmap(powderlist) {
	if {[string range $expmap(htype_$h) 2 2] == $expcons(ProfileHistType)} {
	    $expcons(histlistbox$ic) insert end [format "%2d %-67s" \
		    $h [string range [histinfo $h title] 0 66]]
	    incr i
	}
    }
    # if there is only 1 choice, select it
    if {[llength $expmap(powderlist)] == 1} {
	$expcons(histlistbox$ic) selection set 0
    }
}

# called to select the default values for each column in the atom parameter dialog
proc SelectProfileConstraintColumn {cfr ic col "constr {}"} {
    global expmap expcons expgui
    # now insert the phases into the list
    set i 0
    set selphase [lindex $constr 0]
    foreach phase $expmap(phaselist) {
	if {[lsearch $selphase $phase] != -1} {
	    $expcons(phaselistbox$ic) select set $i $i
	}
	incr i
    }
    if {[lsearch $selphase "ALL"] != -1} {
	$expcons(phaselistbox$ic) select set 0 end
    }
    # now insert the histograms into the list
    set i 0
    set selhist [lindex $constr 1]
    foreach h $expmap(powderlist) {
	if {[string range $expmap(htype_$h) 2 2] == $expcons(ProfileHistType)} {
	    if {[lsearch $selhist $h] != -1} {
		$expcons(histlistbox$ic) select set $i $i
		$expcons(histlistbox$ic) see $i
	    }
	    incr i
	}
    }
    if {[lsearch $selhist "ALL"] != -1} {
	$expcons(histlistbox$ic) select set 0 end
    }
}

# called when the "New column" button is pressed to add a new constraint
proc NewProfileConstraintColumn {top cfr} {
    global expcons
    set col -2
    set row 1
    for {set ic 1} {$ic < 27} {incr ic} {
	incr col 3
	if [winfo exists $cfr.lbp$ic] continue
	MakeProfileConstraintColumn $cfr $ic $col
	FillProfileConstraintColumn $cfr $ic $col
	# set the various variables to initial values
	set expcons(mult$ic) 1.0
	break
    }
    # resize the canvas & scrollbar
    update idletasks
    set sizes [grid bbox $cfr]
    $top.canvas config -scrollregion $sizes
    set width [lindex $sizes 2]
    # use the scroll for BIG constraints
    if {$width > 600} {
	set width 600
	grid $top.scroll -sticky ew -column 0 -row 3 -columnspan 4
    }
    $top.canvas config -height [lindex $sizes 3] -width $width
}

# called to delete profile constraints
proc DeleteProfileConstraints {} {
    global expgui expcons
    # get the constraints to delete
    set dellist {}
    # loop over used profile terms
    for {set i 1} {$i <= 36} {incr i} {
	set ncons [constrinfo profile$i get 0]
	# loop over the defined constraints
	for {set j 1} {$j <= $ncons} {incr j} {
	    if {$expcons(delete${i}_$j)} {lappend dellist [list $i $j]}
	}
    }
    # nothing to delete?
    if {$dellist == ""} return
    if {[MyMessageBox -message \
	    "Do you want to delete [llength $dellist] constraint(s)?" \
	    -parent [winfo toplevel $expcons(profilemaster)] \
	    -type {No Delete} -default no] == "no"} return
    foreach item [lsort -decreasing -integer -index 1 $dellist] {
	set i [lindex $item 0]
	constrinfo profile$i delete [lindex $item 1]
	RecordMacroEntry "constrinfo profile$i delete [lindex $item 1]" 0
	RecordMacroEntry "incr expgui(changed)" 0
	incr expgui(changed)
    }
    DisplayProfileConstraints
}


# take the info in the Edit Profile Constraint page and save it in
# the .EXP array
proc SaveProfileConstraint {num term top} {
    global expcons expmap expgui
    set conslist {}
    for {set ic 1} {$ic < 27} {incr ic} {
	set phases {}
	set hists {}
	if ![info exists expcons(phaselistbox$ic)] break
	if ![info exists expcons(histlistbox$ic)] break
	if ![winfo exists $expcons(phaselistbox$ic)] break
	if ![winfo exists $expcons(histlistbox$ic)] break
	set phases [$expcons(phaselistbox$ic) curselection]
	set hists [$expcons(histlistbox$ic) curselection]
	if {[llength $phases] == [llength $expmap(phaselist)]} {
	    set phases "ALL"
	}
	if {[llength $hists] == [llength $expmap(powderlist)]} {
	    set hists "ALL"
	}
	if {$hists == ""} {
	    MyMessageBox -icon warning -message \
		    "Please select at least one histogram before trying to save" \
		    -parent [winfo toplevel $expgui(consFrame)] 
	    return
	}
	if {$phases == ""} {
	    MyMessageBox -icon warning -message \
		    "Please select at least one phase before trying to save" \
		    -parent [winfo toplevel $expgui(consFrame)] 
	    return
	}
	foreach h $hists {
	    if {$h == "ALL"} {
		set hist "ALL"
	    } else {
		set hist [lindex [$expcons(histlistbox$ic) get $h] 0]
	    }
	    foreach p $phases {
		if {$p == "ALL"} {
		    set phase "ALL"
		} else {
		    set phase [lindex $expmap(phaselist) $p]
		}
		lappend conslist [list $phase $hist $expcons(mult$ic)]
	    }
	}
    }
    if {[llength $conslist] > 27} {
	MyMessageBox -icon warning \
		-message "Note: you have entered [llength $conslist] terms, only 27 can be used" \
		-helplink "expgui6.html ProfileConstraintsMax" \
		-parent [winfo toplevel $expgui(consFrame)] 
	return
    }
    foreach t $term {
	if {$num != "add"} {
	    constrinfo profile$t set $num $conslist
	    RecordMacroEntry "constrinfo profile$t set $num [list $conslist]" 0
	} else {
	    constrinfo profile$t add $num $conslist
	    RecordMacroEntry "constrinfo profile$t add $num [list $conslist]" 0
	}
	incr expgui(changed)
    }
    if {[llength $term] > 0} {RecordMacroEntry "incr expgui(changed)" 0}
    destroy $top
    DisplayProfileConstraints
}

# Called to create a new profile constraint. Works in two steps,
# 1st the profile type and terms are selected and 
# 2nd the constraint is defined using EditProfileConstraint
proc NewProfileConstraint {} {
    global expcons expmap expgui

    set top {.editcons}
    catch {toplevel $top}
    bind $top <Key-F1> "MakeWWWHelp expgui6.html NewProfileConstraints"
    eval destroy [grid slaves $top]

    wm title $top "New Profile Constraint"
    grid [label $top.top -text "Editing new profile constraint"] \
	    -column 0 -row 0 -columnspan 4
    grid [frame $top.fr1] -column 1 -row 1 -columnspan 3 -sticky w
    grid [frame $top.fr2] -column 1 -row 2 -columnspan 3 -sticky w
    grid [frame $top.fr3] -column 1 -row 3 -columnspan 3 -sticky w
    grid [frame $top.fr4 -relief groove -bd 2] \
	    -column 0 -row 4 -columnspan 4 -sticky w
    # need to get histogram type
    grid [label $top.fr1a -text "Choose histogram type:"] \
	    -column 0 -row 1 
    grid [radiobutton $top.fr1.b -value T -variable expcons(ProfileHistType) \
	    -command "ResetProfileHistogram $top.fr4"\
	    -text "TOF"] -column 1 -row 1
    grid [radiobutton $top.fr1.c -value C -variable expcons(ProfileHistType) \
	    -command "ResetProfileHistogram $top.fr4"\
	    -text "Constant Wavelength"] -column 2 -row 1
    grid [radiobutton $top.fr1.d -value E -variable expcons(ProfileHistType) \
	    -command "ResetProfileHistogram $top.fr4"\
	    -text "Energy Disp. X-ray"] -column 3 -row 1
    # 
    # need to get histogram type
    grid [label $top.fr2a -text "Choose profile function:"] \
	    -column 0 -row 2 
    foreach i {1 2 3 4 5} {
	grid [radiobutton $top.fr2.$i -value $i \
		-variable expcons(ProfileFunction) \
		-command "ResetProfileHistogram $top.fr4"\
		-text $i] -column $i -row 2
    }
    # and need to get phase # (for type 4 profile)
    grid [label $top.fr3a -text "Choose phase:"] \
	    -column 0 -row 3
    foreach i $expmap(phaselist) {
	grid [radiobutton $top.fr3.$i -value $i \
		-variable expcons(ProfilePhase) \
		-command "ResetProfileHistogram $top.fr4"\
		-text $i] -column $i -row 3
    }
    grid [set expcons(ProfileCreateContinueButton) [button $top.b1 \
	    -text Continue -command "set expcons(createflag) 1"]] \
	    -column 0 -row 5
    grid [button $top.b2 -text Cancel \
	    -command "set expcons(createflag) 0"] -sticky w -column 1 -row 5
    grid [button $top.help -text Help -bg yellow \
	    -command "MakeWWWHelp expgui6.html NewProfileConstraints"] \
	    -column 2 -row 5 -columnspan 99 -sticky e

    # default values by 1st histogram
    set h [lindex $expmap(powderlist) 0]
    # histogram type
    set expcons(ProfileHistType) [string range $expmap(htype_$h) 2 2]
    set p [lindex $expmap(phaselist_$h) 0]
    set expcons(ProfilePhase) $p
    # profile type
    set expcons(ProfileFunction) [string trim [hapinfo $h $p proftype]]
    ResetProfileHistogram $top.fr4

    # wait for a response
    putontop $top
    tkwait variable expcons(createflag)
    if $expcons(createflag) {
	eval destroy [winfo children $top]
    } else {
	destroy $top
	return
    }
    set p $expcons(ProfilePhase)
    set ptype $expcons(ProfileFunction)
    set htype $expcons(ProfileHistType)
    set termlist {}
    set i 0
    foreach lbl [GetProfileTerms $p $htype $ptype] {
	incr i
	if {$expcons(newcons$i)} {lappend termlist $i}
    }
    EditProfileConstraint $termlist add {}
    afterputontop
}

# setup a box with the defined profile constraint terms
proc ResetProfileHistogram {top} {
    global expcons
    set p $expcons(ProfilePhase)
    set ptype $expcons(ProfileFunction)
    set htype $expcons(ProfileHistType)
    eval destroy [winfo children $top]
    grid [label $top.0 -text "Choose profile terms to constrain:"] \
	    -column 0 -columnspan 4 -row 0 -sticky w
    # loop over profile term labels
    set i 0
    set row 0
    set col 0
    foreach lbl [GetProfileTerms $p $htype $ptype] {
	incr i
	incr row
	if {$row > 10} {
	    set row 1
	    incr col
	}
	grid [checkbutton $top.$i -text "#$i ($lbl)" \
		-variable expcons(newcons$i) -command DisableProfileContinue \
		] -column $col -row $row -sticky w
    }
    DisableProfileContinue
}

proc DisableProfileContinue {} {
    global expcons
    set p $expcons(ProfilePhase)
    set ptype $expcons(ProfileFunction)
    set htype $expcons(ProfileHistType)
    set termlist {}
    set i 0
    foreach lbl [GetProfileTerms $p $htype $ptype] {
	incr i
	if {$expcons(newcons$i)} {lappend termlist $i}
    }
    if {$termlist == ""} {
	$expcons(ProfileCreateContinueButton) config -state disabled
    } else {
	$expcons(ProfileCreateContinueButton) config -state normal
    }
}
