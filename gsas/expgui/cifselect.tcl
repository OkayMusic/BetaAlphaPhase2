# $Id: cifselect.tcl 1251 2014-03-10 22:17:29Z toby $

# implements CIFselect: set publication flags for distances and angles

# create a label for an atom
proc labelatom {phase atom} {
    global labelarr
    set a [lindex [split $atom _] 0]
    set suffix [lindex [split $atom _] 1]
    set label ${a}
    catch {
	set label $labelarr(${phase}P${a})
    }
    if {$suffix != ""} {
	append label _$suffix
    }
    return $label
}

# create a symmetry code number (a-zz for 1 to 702 [26*27])
proc codenumber {n} {
    set res {}
    while {$n > 0} {
	set c [format %c [expr {97 + ($n-1) % 26}]]
	set res "${c}${res}"
	set n [expr {($n - 1) / 26}]
    }
    return $res
}

# format numbers & errors in crystallographic notation
proc formatSU {num err} {
    # errors less or equal to t are expressed as 2 digits
    set T 19
    set lnT [expr { log10($T) }]  
    # error is zero
    if {$err == 0} {
	# is this an integer?
	if {int($num) == $num} {
	    return [format %d [expr int($num)]]
	}
	# allow six sig figs with a zero error (except for 0.0)
	set dec [expr int(5.999999-log10( abs($num) ))]
	if {$dec < -2 || $dec > 9} {
	    return [format %.5E $num]
	} elseif {$dec <= 0} {
	    return [format %d [expr int($num)]]
	} else {
	    return [format %.${dec}f $num]
	}
    } else {
	#set sigfigs [expr log10( abs(10) / abs(.012/$T) ) + 1]
	# should the number be expressed in scientific notation?
	if {$err > $T || abs($num) < 0.0001} {
	    # get the exponent
	    set exp [lindex [split [format %E $num] E] end]
	    # strip leading zeros
	    regsub {([-\+])0+} $exp {\1} exp
	    # number of decimals in exponetial notation
	    set dec [expr int($lnT - log10( abs($err) ) + $exp)]
	    # should the error be displayed?
	    if {$err < 0} {
		return [format "%.${dec}E" $num]
	    } else {
		# scale the error into a decimal number
		set serr [expr int(0.5 + $err * pow(10,$dec-$exp))]
		return [format "%.${dec}E(%d)" $num $serr]
	    }
	} else {
	    # number of digits
	    set dec [expr int($lnT - log10( abs($err) ))]
	    # should the error be displayed?
	    if {$err < 0} {
		return [format "%.${dec}f" $num]
	    } else {
		set serr [expr int(0.5 + $err * pow(10,$dec))]
		return [format "%.${dec}f(%d)" $num $serr]
	    }
	}
    }
}


# fill a frame with distances and angles as a trianglar matrix
proc FillDistAngMatrix {phase atom} {
    global disarr dislist disflag angarr angflag widget CIFselect
    catch {unset widget}
    set frame $CIFselect(seldisplay)
    eval destroy [winfo children $frame]
    set width 0

    # overall heading
    grid [frame $frame.head] \
	    -row 0 -column 0 -columnspan 99 -sticky ew
    grid [label $frame.head.l -textvariable CIFselect(boxhead)\
	    -anchor center] \
	    -row 0 -column 0 -sticky ew
    set CIFselect(boxhead) "Select an atom for distance and angle display"
    grid columnconfigure $frame.head 0 -weight 1 -pad 10
    grid [button $frame.head.help -text Help -bg yellow \
	    -command "MakeWWWHelp gsas2cif.html cifselect"] \
	    -column 1 -row 0 -sticky e

    if {$phase == "" || $atom == ""} return

    # make a list of atoms involved in angles
    set alist {}
    foreach a [array names angarr ${phase}P${atom}:*] {
	foreach {c i j} [split $a :] {}
	if {[lsearch $alist $i] == -1} {lappend alist $i}
	if {[lsearch $alist $j] == -1} {lappend alist $j}
    }
    set alist [lsort $alist]
    # make a list of atoms in distances
    set dlist $dislist(${phase}P$atom)
    
    # set overall heading
    set CIFselect(boxhead) \
	    "Distances and angles around atom [labelatom $phase $atom]"

    grid [frame $frame.a] -row 1 -column 0 -columnspan 99
    foreach {tbox bbox sbox cbox} [MakeScrollTable $frame.a] {}
    [winfo parent $bbox] config -width 550 -height 300
    
    # column labels
    set row 0
    grid [label $tbox.$row-2 -text distance \
		-width $width] -row $row -column 2
    set col 3
    foreach l $alist {
	# skip last entry
	if {$l == [lindex $alist end]} continue
	incr col 
	grid [label $tbox.$row-$col -text [labelatom $phase $l] \
		-width $width] -row $row -column $col
	incr col
    }

    # angle/distance entries
    set i -1
    set row -1
    foreach l $alist {
	incr row
	set col 0
	grid [label $sbox.$row-l -text [labelatom $phase $l]] \
		-row $row -column $col
	incr col 2
	set dist [eval formatSU $disarr(${phase}P${atom}:$l)]
	grid [label $bbox.$row-d -text $dist -width $width] \
		-row $row -column $col -sticky ew
	ColorWidget $bbox.$row-d $disflag(${phase}P${atom}:$l)
	set widget($bbox.$row-d) ${phase}P${atom}:$l
	
	foreach a [lrange $alist 0 $i] {
	    set angle {}
	    catch {
		set angle $angarr(${phase}P${atom}:$l:$a)
		set index ${phase}P${atom}:$l:$a
	    }
	    catch {
		set angle $angarr(${phase}P${atom}:$a:$l)
		set index ${phase}P${atom}:$a:$l
	    }
	    if {$angle != ""} {
		set atxt [eval formatSU $angle]
		incr col 2
		grid [label $bbox.$row-$col -text $atxt -width $width] \
			-row $row -column $col -sticky ew
		ColorWidget $bbox.$row-$col $angflag($index)
		set widget($bbox.$row-$col) $index
	    } else {
		incr col
	    }
	}
	incr i
    }
    foreach l [lsort $dlist] {
	if {[lsearch $alist $l] != -1} continue
	incr row
	set col 0
	grid [label $sbox.$row-l -text [labelatom $phase $l]] \
		-row $row -column $col
	set dist [eval formatSU $disarr(${phase}P${atom}:$l)]
	incr col 2
	grid [label $bbox.$row-d -text $dist -width $width] \
		-row $row -column $col -sticky ew
	ColorWidget $bbox.$row-d $disflag(${phase}P${atom}:$l)
	set widget($bbox.$row-d) ${phase}P${atom}:$l
    }
    foreach n [array names widget] {
	bind $n <1> {SetWidgetFlag %W}
    }

    #grid columnconfigure $bbox 1 -minsize 5
    #grid columnconfigure $tbox 1 -minsize 5
    set col 3
    foreach l $alist {
	# skip last entry
	if {$l == [lindex $alist end]} continue
	grid columnconfigure $bbox $col -minsize 5
	grid columnconfigure $tbox $col -minsize 5
	incr col 2
    }
    update
    ResizeScrollTable $frame.a
    update
    ExpandScrollTable $frame.a
}

# create a file with all distances and angles as a trianglar matrix
proc ExportDistAngMatrix {} {
    global disarr dislist disflag angarr angflag widget CIFselect expmap
    set phase $CIFselect(phase)
    if {$phase == ""} return

    set file [tk_getSaveFile \
	    -filetypes {{spreadsheet .csv}} -defaultextension .csv \
	    -parent .]
    if {$file == ""} return
    set fp [open $file w]
    # overall heading
    puts $fp "Distances and angles around atoms in phase $phase"

    foreach atom $expmap(atomlist_$phase) {

	# make a list of atoms involved in angles
	set alist {}
	foreach a [array names angarr ${phase}P${atom}:*] {
	    foreach {c i j} [split $a :] {}
	    if {[lsearch $alist $i] == -1} {lappend alist $i}
	    if {[lsearch $alist $j] == -1} {lappend alist $j}
	}
	set alist [lsort $alist]
	# make a list of atoms in distances
	set dlist $dislist(${phase}P$atom)
    
	# atom heading
	puts $fp "\nDistances and angles around atom [labelatom $phase $atom]"

	# column labels
	puts -nonewline $fp ",distance"
	foreach l $alist {
	    # skip last entry
	    if {$l == [lindex $alist end]} continue
	    puts -nonewline $fp ",[labelatom $phase $l]"
	}
	puts $fp ""
	
	# angle/distance entries
	set i -1
	foreach l $alist {
	    set dist [eval formatSU $disarr(${phase}P${atom}:$l)]
	    puts -nonewline $fp "[labelatom $phase $l],$dist"
	    foreach a [lrange $alist 0 $i] {
		set angle {}
		catch {
		    set angle $angarr(${phase}P${atom}:$l:$a)
		}
		catch {
		    set angle $angarr(${phase}P${atom}:$a:$l)
		}
		if {$angle != ""} {
		    set atxt [eval formatSU $angle]
		    puts -nonewline $fp ",$atxt"
		}
	    }
	    puts $fp ""
	    incr i
	}
    }

    foreach l [lsort $dlist] {
	if {[lsearch $alist $l] != -1} continue
	set dist [eval formatSU $disarr(${phase}P${atom}:$l)]
	puts $fp "[labelatom $phase $l],$dist"
    }
    close $fp
}

# set the color for a distance/angle entry
proc ColorWidget {widget flag} {
    if {$flag} {
	$widget config -bg yellow
    } else {
	$widget config -bg white
    }
}

# respond to a mouse click on a distance or angle label
proc SetWidgetFlag {W} {
    global widget CIFselect angflag disflag
    set index $widget($W)
    # angle or distance?
    incr CIFselect(changes)
    if {[regexp {[0-9]P[0-9]+:.+:.+} $index]} {
	# angle
	if {$CIFselect(click) == "set"} {
	    set angflag($index) 1
	} elseif {$CIFselect(click) == "clear"} {
	    set angflag($index) 0
	} else {
	    set angflag($index) [expr ! $angflag($index)]
	}
	ColorWidget $W $angflag($index)
    } else {
	# distance
	if {$CIFselect(click) == "set"} {
	    set disflag($index) 1
	} elseif {$CIFselect(click) == "clear"} {
	    set disflag($index) 0
	} else {
	    set disflag($index) [expr ! $disflag($index)]
	}
	ColorWidget $W $disflag($index)
	if {$CIFselect(select) == "yes"} {
	    # get atom 
	    set atom [lindex [split $index :] end]
	    foreach n [array names widget] {
		set aindex $widget($n)
		foreach {c i j} [split $aindex :] {}
		# reject distances
		if {$j == ""} continue
		if {$i == $atom || $j == $atom} {
		    if {$disflag(${c}:$j) && $disflag(${c}:$i)} {
			set angflag($aindex) 1
			ColorWidget $n 1
		    } else {
			set angflag($aindex) 0
			ColorWidget $n 0
		    }
		}
	    }
	}
    }
}

# respond to a selection of a phase
proc SelectPhase {} {
    global CIFselect expmap
    $CIFselect(atomlist) delete 0 end
    foreach atom $expmap(atomlist_$CIFselect(phase)) {
	$CIFselect(atomlist) insert end [atominfo $CIFselect(phase) $atom label]
    }
    FillDistAngMatrix "" "" 
}

# respond to the selection of an angle
proc SelectAtom {} {
    global CIFselect expmap
    # get selected atom
    set atomnum [lindex $expmap(atomlist_$CIFselect(phase)) \
	    [$CIFselect(atomlist) curselection]]
    FillDistAngMatrix $CIFselect(phase) $atomnum
}

# resize the window 
proc ConfigureCommand {win frame} {
    set cmd [bind $win <Configure>]
    if {$cmd == ""} return
    bind $win <Configure> {}
    update
    if {[winfo exists $frame]} {ExpandScrollTable $frame}
    update idletasks
    after idle "bind $win <Configure> [list $cmd]"
}

# write the distance & angle flags to a file
proc SaveFlags {expnam} {
    global symlist disflag angflag CIFselect    
    file rename -force ${expnam}.DISAGL ${expnam}.DISold
    set fp [open ${expnam}.DISold r]
    set out [open ${expnam}.DISAGL w]
    gets $fp line
    puts $out $line
    while {[gets $fp line] >= 0} {
	set phase [lindex $line 1]
	if {[lindex $line 2] == 0} {
	    # distance 
	    set center [lindex $line 5]
	    set a1 [lindex $line 6]
	    set a1l ${phase}P$a1
	    set sym [lindex $line 7]_[lindex $line 8]
	    set i [lsearch $symlist($a1l) $sym]
	    incr i
	    set atom1 ${a1}_[codenumber $i]
	    catch {
		if {$disflag(${phase}P${center}:$atom1)} {
		    set line [string replace $line 0 0 Y]
		} else {
		    set line [string replace $line 0 0 N]
		}
	    }
	} elseif {[lindex $line 2] == 1} {
	    # angle
	    set center [lindex $line 6]
	    set a1 [lindex $line 5]
	    set a1l ${phase}P$a1
	    set a2 [lindex $line 7]
	    set a2l ${phase}P$a2
	    set sym1 [lindex $line 8]_[lindex $line 9]
	    set sym2 [lindex $line 10]_[lindex $line 11]
	    set i [lsearch $symlist($a1l) $sym1]
	    incr i
	    set atom1 ${a1}_[codenumber $i]
	    set i [lsearch $symlist($a2l) $sym2]
	    incr i
	    set atom2 ${a2}_[codenumber $i]
	    catch {
		if {$angflag(${phase}P${center}:${atom1}:${atom2})} {
		    set line [string replace $line 0 0 Y]
		} else {
		    set line [string replace $line 0 0 N]
		}
	    }
	}
	puts $out $line
    }
    close $fp
    close $out
}

# respond to the Exit button
proc SaveAndExit {expnam} {
    global CIFselect
    if {$CIFselect(changes) > 0} {
	set ans [MyMessageBox -parent . -title "Save?" \
		-message "You have made $CIFselect(changes) changes to publication flags. Do you want to save them and exit; quit without saving; or cancel the exit request?" \
		-icon question -type {Save Quit Cancel} -default Save]
	if {[string tolower $ans] == "cancel"} return
	if {[string tolower $ans] == "save"} {SaveFlags $expnam}
    }
    destroy $CIFselect(seltop)
    destroy $CIFselect(seldisplay)
    wm deiconify .
}

# start the CIFselect procedure to select distances and angles
proc CIFselect {expfile} {
    # check if file exists
    set expnam [file root $expfile]
    if {![file exists ${expnam}.DISAGL]} {
	MyMessageBox -parent . -title "No DISAGL file" \
		-message "No distances/angles to select: file ${expnam}.DISAGL was not found. Have you run DISAGL?" \
		-icon warning -type Quit -default Quit
	return
    }
    
    global expmap labelarr symlist disarr dislist angarr disflag angflag CIFselect
    catch {
	unset labelarr
	unset symlist
	unset disarr
	unset dislist
	unset angarr
	unset disflag
	unset angflag
    }

    foreach phase $expmap(phaselist) {
	foreach atom $expmap(atomlist_$phase) {
	    set labelarr(${phase}P${atom}) [atominfo $phase $atom label]
	}
    }
    
    # open file & skip 1st line
    set fp [open ${expnam}.DISAGL r]
    gets $fp line
    # process the rest
    while {[gets $fp line] >= 0} {
	set phase [lindex $line 1]
	if {[lindex $line 2] == 0} {
	    # distance 
	    set center [lindex $line 5]
	    set a1 [lindex $line 6]
	    set a1l ${phase}P$a1
	    set sym [lindex $line 7]_[lindex $line 8]
	    if {[catch {set symlist($a1l)}]} {set symlist($a1l) $sym}
	    if {[lsearch $symlist($a1l) $sym] == -1} {
		lappend symlist($a1l) $sym
	    }
	    set i [lsearch $symlist($a1l) $sym]
	    incr i
	    set atom1 ${a1}_[codenumber $i]
	    lappend dislist(${phase}P${center}) $atom1
	    set disarr(${phase}P${center}:$atom1) [lrange $line 3 4]
	    if {[string tolower [lindex $line 0]] =="y"} {
		set disflag(${phase}P${center}:$atom1) 1
	    } else {
		set disflag(${phase}P${center}:$atom1) 0
	    }
	} elseif {[lindex $line 2] == 1} {
	    # angle
	    set center [lindex $line 6]
	    set a1 [lindex $line 5]
	    set a1l ${phase}P$a1
	    set a2 [lindex $line 7]
	    set a2l ${phase}P$a2
	    set sym1 [lindex $line 8]_[lindex $line 9]
	    set sym2 [lindex $line 10]_[lindex $line 11]
	    foreach sym [list $sym1 $sym2] {
		if {[catch {set symlist($a1l)}]} {set symlist($a1l) $sym}
		if {[lsearch $symlist($a1l) $sym] == -1} {
		    lappend symlist($a1l) $sym
		}
	    }
	    set i [lsearch $symlist($a1l) $sym1]
	    incr i
	    set atom1 ${a1}_[codenumber $i]
	    set i [lsearch $symlist($a2l) $sym2]
	    incr i
	    set atom2 ${a2}_[codenumber $i]
	    set angarr(${phase}P${center}:${atom1}:${atom2}) [lrange $line 3 4]
	    if {[string tolower [lindex $line 0]] =="y"} {
		set angflag(${phase}P${center}:${atom1}:${atom2}) 1
	    } else {
		set angflag(${phase}P${center}:${atom1}:${atom2}) 0
	    }
	}
    }
    close $fp
    # no changes yet
    set CIFselect(changes) 0

    # create the GUI
    set top .seldis
    set CIFselect(seltop) $top
    catch {destroy $top}
    toplevel $top
    wm title $top "Selection modes"
    bind $top <Key-F1> "MakeWWWHelp gsas2cif.html cifselect"

    grid [frame $top.mode -bd 4 -relief groove] -row 1 -column 1 -sticky news
    grid [label $top.mode.l -text "Response to Mouse click:"] \
	    -row 1 -column 0 -columnspan 99 
    set col 1
    foreach val {Toggle Set Clear} {
	grid [radiobutton $top.mode.r$col -text $val \
		-variable CIFselect(click) \
		-value [string tolower $val]] -row 2 -column $col
	incr col
    }
    
    grid [frame $top.sel -bd 4 -relief groove] -row 2 -column 1 -sticky news
    grid [label $top.sel.l -text "Distance selection: select matching angles?"] \
	    -row 1 -column 1 -columnspan 3
    set col 1
    foreach val {Yes No} {
	grid [radiobutton $top.sel.r$col -text $val \
		-variable CIFselect(select) \
		-value [string tolower $val]] -row 2 -column $col
	incr col
    }
    
    grid [frame $top.ph -bd 4 -relief groove] -row 1 -column 0 -sticky news
    grid [label $top.ph.h -text "Select phase"] -row 1 -column 0 -columnspan 99
    set col 0
    foreach phase $expmap(phaselist) {
	grid [radiobutton $top.ph.r$col -text $phase \
		-variable CIFselect(phase) \
		-command SelectPhase \
		-value $phase] -row 2 -column $col
	incr col
    }
    grid columnconfigure $top 0 -weight 1
    grid rowconfigure $top 3 -weight 1

    grid [frame $top.atom -bd 4 -relief groove] \
	    -row 2 -rowspan 2 -column 0 -sticky news
    grid [label $top.atom.h -text "Select atom"] -row 1 -column 0 -columnspan 99
    set CIFselect(atomlist) $top.atom.lbox
    grid columnconfigure $top.atom 0 -weight 1
    grid rowconfigure $top.atom 2 -weight 1
    grid [listbox $top.atom.lbox -height 4 -width 10 \
	    -exportselection 0 -yscrollcommand " $top.atom.rscr set"\
	    ] -row 2 -column 0 -sticky news
    grid [scrollbar $top.atom.rscr  -command "$top.atom.lbox yview" \
	    ] -row 2 -column 1 -sticky ns
    bind $top.atom.lbox <<ListboxSelect>> SelectAtom
    
    grid [frame $top.bt] -row 3 -column 1 -sticky news
    button $top.bt.save -command "SaveFlags $expnam" -text Save
    button $top.bt.export -command ExportDistAngMatrix -text "Export Tables"
    button $top.bt.exit -command "SaveAndExit $expnam" -text Exit
    grid $top.bt.save $top.bt.export $top.bt.exit -pad 5 -sticky s
    grid columnconfig $top.bt 1 -weight 1
    grid rowconfig $top.bt 0 -weight 1

    set CIFselect(seldisplay) .selshow
    catch {destroy $CIFselect(seldisplay)}
    toplevel $CIFselect(seldisplay)
    wm title $CIFselect(seldisplay) "Distance & Angle Table"
    bind $CIFselect(seldisplay) <Key-F1> "MakeWWWHelp gsas2cif.html cifselect"
    FillDistAngMatrix "" ""
    
    bind $CIFselect(seldisplay) <Configure> {
	ConfigureCommand %W $CIFselect(seldisplay).a
    }
    
    wm iconify .
    # select the first phase
    set CIFselect(phase) [lindex $expmap(phaselist) 0]
    SelectPhase
}

set CIFselect(click) set
set CIFselect(select) yes

