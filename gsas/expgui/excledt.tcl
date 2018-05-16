# $Id: excledt.tcl 1251 2014-03-10 22:17:29Z toby $

# create the main Excluded Region window
proc ExclReaddata {box} { 
    global expgui graph
#    if [catch {
	set loadtime [time {
	    ExclReaddata_hst $box
#	}]
	if $expgui(debug) {
	    tk_dialog $graph(exclbox).time "Timing info" \
		    "Histogram loading took $loadtime" "" 0 OK
	}
#    } errmsg] {
	if $expgui(debug) {
	    catch {console show}
	    error $errmsg
	}
#	$box config -title "Read error"
#	tk_dialog .err "Read Error" "Read Error -- $errmsg" \
#		error 0 OK
#	update
#    }
    $box element show [lsort -decreasing [$box element show]]
}
   
# get the data to plot using hstdump (tcldump does not show the excluded data)
proc ExclReaddata_hst {box} {
    global expgui reflns graph
    global peakinfo 
    update
    set hst $graph(hst)
    # parse the output of a file
    # use histdmp for histogram info
    set input [open excl$hst.inp w]
    puts $input "[file rootname [file tail $expgui(expfile)]]"
    puts $input "L"
    puts $input "$hst"
    puts $input "0"
    close $input
    # use hstdmp without an experiment name so that output 
    # is not sent to the .LST file
    exec [file join $expgui(gsasexe) hstdmp] < excl$hst.inp > excl$hst.out
    set input [open excl$hst.out r]
    catch {file delete excl$hst.inp}
    # initalize arrays
    set num -1
    set xlist {}
    set obslist {}
    set calclist {}
    set allxlist {}
    set graph(xcaption) {}
    set exclistx {}
    set exclistobs {}
    # define a list of reflection positions for each phase
    for {set i 1} {$i < 10} {incr i} {
	set reflns($i) {}
    }
    set i 0
    while {[gets $input line] >= 0} {
	incr i
	# run update every 200th line
	if {$i > 200} {set i 0; update}
	if [scan $line %d num] {
	    if {$num > 0} {
		set Ispec 0
		set X -999
		scan [string range $line 9 end] %e%e%e%e \
			X Iobs Icalc Ispec
		# eliminate excluded points
		if {$Ispec > 0.0 && $X >= 0} {
		    lappend allxlist $X
		    lappend xlist $X
		    lappend obslist $Iobs
		    lappend calclist $Icalc
		} elseif {$X != -999} {
		    lappend allxlist $X
		    lappend exclistx $X
		    lappend exclistobs $Iobs
		}
		if [regexp {[1-9]} [string range $line 6 7] ph] {
		    lappend reflns($ph) $X
		}
	    } 
	} else {
	    regexp {Time|Theta|keV} $line graph(xcaption)
	}
    }
    close $input
    if {$graph(xcaption) == "Theta"} {set graph(xcaption) "2-Theta"}
    # convert the x units, if requested
    if {$graph(xunits) == 1} {
	set xlist [tod $xlist $hst]
	set exclistx [tod $exclistx $hst]
	set graph(xcaption) d-space
    } elseif {$graph(xunits) == 2} {
	set xlist [toQ $xlist $hst]
	set exclistx [toQ $exclistx $hst]
	set graph(xcaption) Q
    }
    catch {file delete excl$hst.out}
    catch {
	if {[llength $allxlist] > 0} {
	    allxvec set $allxlist
	    xvec set $xlist
	    obsvec set $obslist
	    calcvec set $calclist
	    exxvec set $exclistx
	    exobsvec set $exclistobs 
	    foreach vec {obsvec calcvec} {
		# probably not needed with recent versions of BLT:
		global $vec
		# sometimes needed for latest version of BLT (2.4z)
		catch {$vec variable $vec}
	    }
	    set cmin [set calcvec(min)]
	    set omin [set obsvec(min)]
	    set cmax [set calcvec(max)]
	    set omax [set obsvec(max)]
	    foreach {expgui(min) expgui(max)} {0 0} {}
	    set expgui(min) [expr $omin < $cmin ? $omin : $cmin]
	    set expgui(max) [expr $omax > $cmax ? $omax : $cmax]
	}
	plotExclData
    }
}

# plot the pattern with the requested x-axis units & the excluded regions
proc plotExclData {args} {
    global peakinfo  reflns
    global graph expgui

    set hst $graph(hst)
    $graph(plot) config -title \
	    "[file tail $expgui(expfile)] cycle [expinfo cyclesrun] Hist $hst"
    $graph(plot) xaxis config -title $graph(xcaption)
    $graph(plot) yaxis config -title $graph(ycaption)
    setlegend $graph(plot) $graph(legend)
    # reconfigure the data display
    $graph(plot) element configure 3 \
	    -symbol $peakinfo(obssym) -color $graph(color_obs) \
	    -pixels [expr 0.125 * $peakinfo(obssize)]i
    $graph(plot) element config 2 -color $graph(color_calc)
    $graph(plot) element config 12 \
	    -symbol $peakinfo(exclsym) -color $graph(color_excl) \
	    -pixels [expr 0.125 * $peakinfo(exclsize)]i

    foreach vec {xvec obsvec calcvec exxvec exobsvec} {
	$vec notify now
    }
    # now deal with tick marks
    for {set i 1} {$i < 10} {incr i} {
	if {$expgui(autotick)} {
	    set div [expr ( $expgui(max) - $expgui(min) )/40.]
	    set ymin [expr $expgui(min) - ($i+1) * $div]
	    set ymax [expr $expgui(min) - $i * $div]
	} else {
	    set ymin $peakinfo(min$i)
	    set ymax $peakinfo(max$i)
	}
	set j 0
	if [set peakinfo(flag$i)] {
	    if {$graph(xunits) == 1} {
		set Xlist [tod $reflns($i) $hst]
	    } elseif {$graph(xunits) == 2} {
		set Xlist [toQ $reflns($i) $hst]
	    } else {
		set Xlist $reflns($i)
	    }
	    foreach X $Xlist {
		incr j
		catch {
		    $graph(plot) marker create line -name peaks${i}_$j 
		}
		$graph(plot) marker config peaks${i}_$j  -under 1 \
			-coords "$X $ymin $X $ymax" 
		catch {
		    $graph(plot) marker config peaks${i}_$j \
			    $graph(MarkerColorOpt) [list $peakinfo(color$i)]
		    if $peakinfo(dashes$i) {
			$graph(plot) marker config peaks${i}_$j -dashes "5 5"
		    }
		}
	    }
	    catch {$graph(plot) element create phase$i}
	    catch {
		$graph(plot) element config phase$i -color $peakinfo(color$i) 
	    }
	} else {
	    eval $graph(plot) marker delete [$graph(plot) marker names peaks${i}_*]
	    eval $graph(plot) element delete [$graph(plot) element names phase$i]
	}
    }
    # force an update of the plot as BLT may not
    $graph(plot) config -title [$graph(plot) cget -title]
    update
}

# show or hide the plot legend
proc setlegend {box legend} {
    global blt_version
    if {$blt_version >= 2.3 && $blt_version < 8.0} {
	if $legend {
	    $box legend config -hide no
	} else {
	    $box legend config -hide yes
	}
    } else {
	if $legend {
	    $box legend config -mapped yes
	} else {
	    $box legend config -mapped no
	}
    }
}

# show tickmark options
proc minioptionsbox {num} {
    global blt_version tcl_platform peakinfo expgui graph
    set bx $graph(exclbox).opt$num
    catch {destroy $bx}
    toplevel $bx
    wm iconname $bx "Phase $num options"
    wm title $bx "Phase $num options"

    set i $num
    pack [label $bx.0 -text "Phase $i reflns" ] -side top
    pack [checkbutton $bx.1 -text "Show reflections" \
	    -variable peakinfo(flag$i)] -side top
    # remove option that does not work
    if {$blt_version != 8.0 || $tcl_platform(platform) != "windows"} {
	pack [checkbutton $bx.2 -text "Use dashed line" \
		-variable peakinfo(dashes$i)] -side top 
    }
    if !$expgui(autotick) {
	pack [frame $bx.p$i -bd 2 -relief groove] -side top
	#	pack [checkbutton $bx.p$i.0 -text "Show phase $i reflns" \
		#		-variable peakinfo(flag$i)] -side left -anchor w
	pack [label $bx.p$i.1 -text "  Y min:"] -side left
	pack [entry $bx.p$i.2 -textvariable peakinfo(min$i) -width 5] \
		-side left
	pack [label $bx.p$i.3 -text "  Y max:"] -side left
	pack [entry $bx.p$i.4 -textvariable peakinfo(max$i) -width 5] \
		-side left
    }
    pack [frame $bx.c$i -bd 2 -relief groove] -side top
    
    pack [label $bx.c$i.5 -text " color:"] -side left
    pack [entry $bx.c$i.6 -textvariable peakinfo(color$i) -width 12] \
	    -side left
    pack [button $bx.c$i.2 -bg $peakinfo(color$i) -state disabled] -side left
    pack [button $bx.c$i.1 -text "Color\nmenu" \
	    -command "setcolor $i"] -side left
    pack [frame $bx.b] -side top
    pack [button $bx.b.4 -command "destroy $bx" -text Close ] -side right
}

proc setcolor {num} {
    global peakinfo
    set color [tk_chooseColor -initialcolor $peakinfo(color$num) -title "Choose color"]
    if {$color == ""} return
    set peakinfo(color$num) $color
}

proc MakePostscriptOut {{parent {}}} {
    global graph
    if !$graph(printout) {
	set out [open "| $graph(outcmd) >& plot.msg" w]
	catch {
	    puts $out [$graph(plot) postscript output -landscape 1 \
		-decorations no -height 7.i -width 9.5i]
	    close $out
	} msg
	catch {
	    set out [open plot.msg r]
	    if {$msg != ""} {append msg "\n"}
	    append msg [read $out]
	    close $out
	    catch {file delete plot.msg}
	}
	if {$msg != ""} {
	    tk_dialog $parent.msg "file created" \
		    "Postscript file processed with command \
		    $graph(outcmd). Result: $msg" "" 0 OK
	} else {
	    tk_dialog $parent.msg "file created" \
		    "Postscript file processed with command \
		    $graph(outcmd)" "" 0 OK
	}
    } else {
	$graph(plot) postscript output $graph(outname) -landscape 1 \
		-decorations no -height 7.i -width 9.5i    
	tk_dialog $parent.msg "file created" \
		"Postscript file $graph(outname) created" "" 0 OK
    }
}

proc setprintopt {page} {
    global graph
    if $graph(printout) { 
	$page.4.1 config -fg black
	$page.4.2 config -fg black -state normal
	$page.6.1 config -fg #888 
	$page.6.2 config -fg #888 -state disabled
    } else {
	$page.4.1 config -fg #888 
	$page.4.2 config -fg #888 -state disabled
	$page.6.1 config -fg black
	$page.6.2 config -fg black -state normal
    }
}

proc SetPostscriptOut {{parent ""}} {
    global graph tcl_platform
    set box ${parent}.out
    catch {destroy $box}
    toplevel $box
    wm title $box "Postscript options"
    focus $box
    pack [frame $box.4] -side top -anchor w -fill x
    pack [checkbutton $box.4.a -text "Write PostScript files" \
	    -variable graph(printout) -offvalue 0 -onvalue 1 \
	    -command "setprintopt $box"] -side left -anchor w
    pack [entry $box.4.2 -textvariable graph(outname)] -side right -anchor w
    pack [label $box.4.1 -text "PostScript file name:"] -side right -anchor w
    pack [frame $box.6] -side top -anchor w -fill x
    pack [checkbutton $box.6.a -text "Print PostScript files" \
	    -variable graph(printout) -offvalue 1 -onvalue 0 \
	    -command "setprintopt $box" ] -side left -anchor w
    pack [entry $box.6.2 -textvariable graph(outcmd)] -side right -anchor w
    pack [label $box.6.1 -text "Command to print files:"] -side right -anchor w

    pack [button $box.a -text "Close" -command "destroy $box"] -side top
    if {$tcl_platform(platform) == "windows"} {
	set graph(printout) 1
	$box.4.a config -state disabled
	$box.6.a config -fg #888 -state disabled
    }
    setprintopt $box
}

proc GetSymbolOpts {"sym obs" {parent ""}} {
    global expgui peakinfo
    set box $parent.out
    catch {destroy $box}
    toplevel $box
    focus $box
    wm title $box "Set $sym symbol"
    pack [frame $box.d] -side left -anchor n
    pack [label $box.d.t -text "Symbol type"] -side top
    set expgui(sym) $peakinfo(${sym}sym) 
    set expgui(size) $peakinfo(${sym}size) 
    foreach symbol {square circle diamond plus cross \
	    splus scross} \
	    symbol_name {square circle diamond plus cross \
	    thin-plus thin-cross} {
	pack [radiobutton $box.d.$symbol \
		-text $symbol_name -variable expgui(sym) \
		-value $symbol] -side top -anchor w
    }
    pack [frame $box.e] -side left -anchor n -fill y
    pack [label $box.e.l -text "Symbol Size"] -side top
    pack [scale $box.e.s -variable expgui(size) \
	    -from 0.1 -to 3 -resolution 0.05] -side top
    pack [frame $box.a] -side bottom
    pack [button $box.a.1 -text Change -command "setsymopts $sym"] -side left
    pack [button $box.a.2 -text Cancel -command "destroy $box"] -side left
}
proc setsymopts {sym} {
    global peakinfo expgui
    if {$peakinfo(${sym}sym) != $expgui(sym)} {set peakinfo(${sym}sym) $expgui(sym)}
    if {$peakinfo(${sym}size) != $expgui(size)} {set peakinfo(${sym}size) $expgui(size)}
}

proc updateplot {} {
    global env tcl_platform graph expgui
    set hst $graph(hst)
    $graph(plot) config -title "Please wait: loading histogram $hst"
    exxvec set {}
    exobsvec  set {}
    exxvec notify now
    exobsvec notify now
    eval $graph(plot) marker delete [$graph(plot) marker names]

    ExclReaddata $graph(plot)
    ShowExlMarks
    $graph(plot) element config 3 -color $graph(color_obs)
    $graph(plot) element config 2 -color $graph(color_calc)
    $graph(plot) element config 12 -color $graph(color_excl)
    foreach vec {xvec obsvec calcvec exxvec exobsvec} {
	$vec notify now
    }
    FillExclRegionBox
    $graph(plot) config -title \
	    "[file tail $expgui(expfile)] cycle [expinfo cyclesrun] Hist $hst"
}

# display the excluded regions with orange markers
proc ShowExlMarks {} {
    global graph
    eval $graph(plot) marker delete [$graph(plot) marker names excl*]
    set hst $graph(hst)
    set exclist [histinfo $hst excl]
    set i 0
    foreach rng $exclist {
	if {$graph(xunits) == 1} {
	    set rng [tod $rng $hst]
	} elseif {$graph(xunits) == 2} {
	    set rng [toQ $rng $hst]
	}
	set x1 [lindex [lsort -real $rng] 0]
	set x2 [lindex [lsort -real $rng] end]
	$graph(plot) marker create line -under 1 -name excl[incr i] \
		-coords "$x1 -Inf $x2 -Inf" \
		$graph(MarkerColorOpt) $graph(color_excl) -linewidth 3
	# copy any points that should be excluded
	set l [lsort -integer [xvec search $x1 $x2]]
	if {$l != ""} {
	    set n1 [lindex $l 0]
	    set n2 [lindex $l end]
	    exxvec append [xvec range $n1 $n2]
	    exobsvec append [obsvec range $n1 $n2]
	}
    }
}

# change the binding of the mouse, based on the selected mode
proc exclEditMode {b bb} {
    global zoom graph
    # save the zoom and unzoom commands
    if [catch {set zoom(in)}] {
	# get binding
	set zoom(bindtag) $graph(plot)
	catch {
	    if {[bind zoom-$graph(plot)] != ""} {
		set zoom(bindtag) zoom=$graph(plot)
	    } elseif {[bind bltZoomGraph] != ""} {
		set zoom(bindtag) bltZoomGraph
	    }
	}
	set zoom(in) [bind $zoom(bindtag) <1>]
	set zoom(out) [bind $zoom(bindtag) <3>]
	# check for really new BLT where binding is handled differently
	if {$zoom(in) == ""} {
	    foreach zoom(bindtag) [bindtags $graph(plot)] {
		set zoom(in) [bind $zoom(bindtag) <1>]
		set zoom(out) [bind $zoom(bindtag) <3>]
		if {$zoom(in) != ""} break
	    }
	}
    }
	
    foreach c {1 2 3} {
	if {$c == $b} {
	    $bb.l.b$c config -relief sunken
	} else {
	    $bb.l.b$c config -relief raised
	}
    }

    # reset previous mode; if in the middle
    if {[string trim [bind $graph(plot) <Motion>]] != ""} {
	if {[lindex [bind $graph(plot) <Motion>] 0] == "exclMove"} {
	    exclReset $zoom(bindtag)
	} else {
	    blt::ResetZoom $graph(plot)
	}
    }
    if {$b == 2} {
	bind $zoom(bindtag) <1> "exclAdd $zoom(bindtag) %x %y"
	$graph(plot) config -cursor arrow
    } elseif {$b == 3} {
	bind $zoom(bindtag) <1> "exclDel $zoom(bindtag) %x %y"
	$graph(plot) config -cursor circle
    } else {
	bind $zoom(bindtag) <1> $zoom(in)
	bind $zoom(bindtag) <3> $zoom(out)
	$graph(plot) config -cursor crosshair
    }
}

# called using the mouse to delete an excluded region
proc exclDel {bindtag x y} {
    global graph expgui
    set x1 [$graph(plot) xaxis invtransform $x]
    set hst $graph(hst)
    if {$graph(xunits) == 1} {
	set x1 [fromd $x1 $hst]
    } elseif {$graph(xunits) == 2} {
	set x1 [fromQ $x1 $hst]
    }
    set exclist [histinfo $hst excl]
    # don't delete the high or low ranges
    if {$x1 <= [lindex [lindex $exclist 0] 1] || \
	    $x1 >= [lindex [lindex $exclist end] 0]} {
	bell
	return
    }
    set newlist {}
    set msg ""
    foreach rng $exclist {
	if {$x1 < [lindex $rng 0] || $x1 > [lindex $rng 1]} {
	    lappend newlist $rng
	} else {
	    if {$graph(xunits) == 1} {
		set drng [tod $rng $hst]
		set msg "Delete excluded region from "
		append msg "[format %.5f [lindex $drng 1]] A "
		append msg "to [format %.5f [lindex $drng 0]] A?"
	    } elseif {$graph(xunits) == 2} {
		set qrng [toQ $rng $hst]
		set msg "Delete excluded region from "
		append msg "[format %.5f [lindex $qrng 0]] A-1 "
		append msg "to [format %.5f [lindex $qrng 1]] A-1?"
	    } else {
		set msg "Delete excluded region from [lindex $rng 0] to [lindex $rng 1]?"
	    }
	    global graph
	    if {$graph(exclPrompt)} {
		set ans [MyMessageBox -parent $graph(exclbox) -message $msg \
			-helplink "expguierr.html ExcludeRegion" \
			-title "Delete region" -type okcancel]
	    } else {
		set ans ok
	    }
	    if {$ans == "ok"} {
		incr expgui(changed)
	    } else {
		lappend newlist $rng
	    }
	}
    }
    if {[llength $newlist] == [llength $exclist]} {
	if {$msg == ""} bell
    } else {
	histinfo $hst excl set $newlist
	RecordMacroEntry "histinfo $hst excl set [list $newlist]" 0
	RecordMacroEntry "incr expgui(changed)" 0
	updateplot
    }
}

# called using the mouse to create a new excluded region
# once this is called, mouse motion causes a region to be highlighted
# using exclMove. Button 1 completes the region, by calling exclDone while
# button 3 resets the mode
proc exclAdd {bindtag x y} {
    global graph 
    bind $graph(plot) <Motion> "exclMove $bindtag %x %y"
    bind $bindtag <1> "exclDone $bindtag %x %y"
    bind $bindtag <3> "exclReset $bindtag"
    set graph(excl-x1) [$graph(plot) xaxis invtransform $x]
    $graph(plot) marker create text -name AddExclLbl -text "Adding\nRegion" \
	    -bg yellow -coords "+Inf +Inf" -anchor ne
}

# reset the "add region mode" (see exclAdd)
proc exclReset {bindtag} {
    global graph
    bind $graph(plot) <Motion> {}
    $graph(plot) marker delete exclShade
    bind $bindtag <1> "exclAdd $bindtag %x %y"
    $graph(plot) marker delete AddExclLbl
}

# highlight the potential excluded region (see exclAdd)
proc exclMove {bindtag x y} {
    global graph
    set x1 $graph(excl-x1)
    set x2 [$graph(plot) xaxis invtransform $x]
    if { ![$graph(plot) marker exists "exclShade"] } {
	$graph(plot) marker create polygon -name "exclShade" -under 1 -fill yellow
    }
    $graph(plot) marker configure "exclShade" \
	    -coords "$x1 -Inf $x1 +Inf $x2 +Inf $x2 -Inf"
}

# Called by a mouse click to complete a new excluded region (see exclAdd)
proc exclDone {bindtag x y} {
    global graph
    bind $graph(plot) <Motion> {}
    bind $bindtag <1> "exclAdd $bindtag %x %y"
    set x1 $graph(excl-x1)
    set x2 [$graph(plot) xaxis invtransform $x]
    set hst $graph(hst)
    if {$graph(xunits) == 1} {
	set x1 [fromd $x1 $hst]
	set x2 [fromd $x2 $hst]
    } elseif {$graph(xunits) == 2} {
	set x1 [fromQ $x1 $hst]
	set x2 [fromQ $x2 $hst]
    }
    catch {
	$graph(plot) marker delete "exclShade"
    }
    $graph(plot) marker delete AddExclLbl
    # get the points in the range
    set l [lsort -integer [allxvec search $x1 $x2]]
    if {[llength $l] == 0} return
    set p1 [allxvec index [set n1 [lindex $l 0]]]
    set p2 [allxvec index [set n2 [lindex $l end]]]
    if {$graph(xunits) == 1} {
	set d1 [tod $p1 $hst]
	set d2 [tod $p2 $hst]
	set msg "Exclude data from "
	append msg "[format %.5f $d2] A to [format %.5f $d1] A"
	append msg " ([expr $n2-$n1+1] points)?"
	set coords "$d2 -Inf $d1 -Inf"
	set l [lsort -integer [xvec search $d1 $d2]]
    } elseif {$graph(xunits) == 2} {
	set q1 [toQ $p1 $hst]
	set q2 [toQ $p2 $hst]
	set msg "Exclude data from "
	append msg "[format %.5f $q1] A-1 to [format %.5f $q2] A-1"
	append msg " ([expr $n2-$n1+1] points)?"
	set coords "$q1 -Inf $q2 -Inf"
	set l [lsort -integer [xvec search $q1 $q2]]
    } else {
	set msg "Exclude data from "
	append msg "[format %.5f $p1] to [format %.5f $p2]"
	append msg " ([expr $n2-$n1+1] points)?"
	set coords "$p1 -Inf $p2 -Inf"
	set l [lsort -integer [xvec search $x1 $x2]]
    }
    global graph
    if {$graph(exclPrompt)} {
	set ans [MyMessageBox -parent $graph(exclbox) -message $msg -title "Exclude?"\
		-type okcancel -helplink "expguierr.html ExcludeRegion"]
    } else {
	set ans ok
    }
    if {$ans != "ok"} {return}
    # make the change
    global expgui
    incr expgui(changed)
    set hst $graph(hst)
    set exclist [histinfo $hst excl]
    set oldtmin [lindex [lindex $exclist 0] 1]
    set oldtmax [lindex [lindex $exclist end] 0]
    # add the new excluded region at the end
    lappend exclist [list $p1 $p2]
    # sort and simplify the excluded region list
    CheckForOverlappingRegions $exclist
    CheckQmaxChanged $oldtmin $oldtmax
    # update the plot to change the color of the points that are now excluded
    exxvec append [xvec range [lindex $l 0] [lindex $l end]]
    exobsvec append [obsvec range [lindex $l 0] [lindex $l end]]
    exxvec notify now
    exobsvec notify now
    ShowExlMarks
    FillExclRegionBox
}

# sort the regions and then go through the list of excluded regions and 
# merge regions that overlap
proc CheckForOverlappingRegions {exclist} {
    global expgui graph
    set exclist [lsort -real -index 0 $exclist]
    set prvlow -1
    set prvhigh -1
    set i 0
    set ip -1
    foreach pair $exclist {
	set low [lindex $pair 0] 
	set high [lindex $pair 1] 
	# is there overlap with the previous range?
	if {$low < $prvhigh && $i != 0} {
	    set exclist [lreplace $exclist $ip $i [list $prvlow $high]]
	    incr expgui(changed)
	    set prvhigh $high
	    continue
	}
	# are there any points between the regions
	if {$i != 0} {
	    set x1 [expr {-.00001+$low}]
	    set x2 [expr {.00001+$prvhigh}]
	    if {$x1 < $x2} {
		set seppts [allxvec search $x1 $x2]
	    } else {
		set seppts [allxvec search $x2 $x1]
	    }
	    if {[llength $seppts] == 0} {
		set exclist [lreplace $exclist $ip $i [list $prvlow $high]]
		incr expgui(changed)
		set prvhigh $high
		continue
	    }
	}
	incr i; incr ip
	set prvlow $low
	set prvhigh $high
    }
    histinfo $graph(hst) excl set $exclist
    RecordMacroEntry "histinfo $graph(hst) excl set [list $exclist]" 0
    RecordMacroEntry "incr expgui(changed)" 0
}

# called in response to the File/"Set Min/Max Range" menu button
proc setminormax {} {
    global expmap graph expgui
    set hst $graph(hst)
    set box $graph(exclbox).limit
    if {[string trim [string range $expmap(htype_$hst) 3 3]] == "D"} {
	if {[string range $expmap(htype_$hst) 2 2] == "T"} {
	    set fac 1000.
	} elseif {[string range $expmap(htype_$hst) 2 2] == "E"} {
	    set fac 1.
	} else {
	    set fac 100.
	}
	set start [expr {[histinfo $hst dstart]/$fac}]
	set step  [expr {[histinfo $hst dstep]/$fac}]
	set points [histinfo $hst dpoints]
	set end [expr {$start + $points*$step}]
	SetDummyRangeBox $hst $start $end $step
	return
    }
    toplevel $box
    wm title $box "Set usable range"
    set link excledt.html
    grid [button $box.help -text Help -bg yellow \
	    -command "MakeWWWHelp $link"] -column 98 -row 0
    bind $box <Key-F1> "MakeWWWHelp $link"

    set hst $graph(hst)
    if {$graph(xunits) == 1} {
	set var d
	set unit A
    } elseif {$graph(xunits) == 2} {
	set var Q
	set unit A-1
    } elseif {[string range $expmap(htype_$hst) 2 2] == "T"} {
	set var TOF
	set unit ms
    } elseif {[string range $expmap(htype_$hst) 2 2] == "C"} {
	set var 2theta
	set unit deg
    } elseif {[string range $expmap(htype_$hst) 2 2] == "E"} {
	set var Energy
	set unit KeV
    } else {
	set var ?
	set unit ?
    }
    if {$graph(xunits) != 0} {
    }
    grid [label $box.t -text "Set usable data range, histogram $hst"] \
	    -column 0 -columnspan 4 -row 0
    grid [label $box.lu -text "($unit)"] -column 2 -row 1 -rowspan 2
    grid [label $box.lmn -text "$var minimum"] -column 0 -row 1
    grid [entry $box.emn -textvariable graph(tmin) -width 10] -column 1 -row 1
    grid [label $box.lmx -text "$var maximum"] -column 0 -row 2
    grid [entry $box.emx -textvariable graph(tmax) -width 10] -column 1 -row 2
    grid [frame $box.c] -column 0 -columnspan 99 -row 99
    grid [button $box.c.1 -text Change -command "destroy $box"\
	    ] -column 1 -row 0
    grid [button $box.c.2 -text Cancel \
	    -command "foreach i {min max} {set graph(\$i) {}}; destroy $box" \
	    ] -column 2 -row 0
    set exclist [histinfo $hst excl]
    set oldtmin [lindex [lindex $exclist 0] 1]
    set oldtmax [lindex [lindex $exclist end] 0]
    if {$graph(xunits) == 1} {
	set graph(tmax) [format %.4f [tod [lindex [lindex $exclist 0] 1] $hst]]
	set graph(tmin) [format %.4f [tod [lindex [lindex $exclist end] 0] $hst]]
    } elseif {$graph(xunits) == 2} {
	set graph(tmin) [format %.4f [toQ [lindex [lindex $exclist 0] 1] $hst]]
	set graph(tmax) [format %.4f [toQ [lindex [lindex $exclist end] 0] $hst]]
    } else {
	set graph(tmin) [lindex [lindex $exclist 0] 1]
	set graph(tmax) [lindex [lindex $exclist end] 0]
    }
    foreach v {tmin tmax} {set start($v) $graph($v)}
    bind $box <Return> "$box.c.1 invoke"
    putontop $box
    tkwait window $box
    # fix grab...
    afterputontop

    set highchange 0
    set startchanges $expgui(changed)
    catch {
	# did anything change?
	if {$graph(tmin) != $start(tmin)} {
	    incr expgui(changed)
	    if {$graph(xunits) == 1} {
		set tmax [fromd $graph(tmin) $hst]
		set exclist [lreplace $exclist end end \
			[list $tmax [lindex [lindex $exclist end] 1]]]
	    } elseif {$graph(xunits) == 2} {
		set tmin [fromQ $graph(tmin) $hst]
		set exclist [lreplace $exclist 0 0 \
			[list [lindex [lindex $exclist 0] 0] $tmin]]
	    } else {
		set exclist [lreplace $exclist 0 0 \
			[list [lindex [lindex $exclist 0] 0] $graph(tmin)]]
	    }
	}
    }
    catch {
	if {$graph(tmax) != $start(tmax)} {
	    incr expgui(changed)
	    if {$graph(xunits) == 1} {
		set tmin [fromd $graph(tmax) $hst]
		set exclist [lreplace $exclist 0 0 \
			[list [lindex [lindex $exclist 0] 0] $tmin]]
	    } elseif {$graph(xunits) == 2} {
		set tmax [fromQ $graph(tmax) $hst]
		set exclist [lreplace $exclist end end \
			[list $tmax [lindex [lindex $exclist end] 1]]]
	    } else {
		set exclist [lreplace $exclist end end \
			[list $graph(tmax) [lindex [lindex $exclist end] 1]]]
	    }
	}
    }
    if {$startchanges != $expgui(changed)} {
	CheckForOverlappingRegions $exclist
	CheckQmaxChanged $oldtmin $oldtmax
	updateplot
    } else {
	return
    }
}

# check to see if Qmax (2theta max or TOF min) has changed, 
# if so, other parts of the .EXP file must be changed
proc CheckQmaxChanged {oldtmin oldtmax} {
    global graph expmap
    set hst $graph(hst)
    set exclist [histinfo $hst excl]
    if {[string range $expmap(htype_$hst) 2 2] == "T"} {
	set tmin [lindex [lindex $exclist 0] 1]
	if {$oldtmin != $tmin} {
	    # edited minimum time -- reset d-min & set CHANS -- use EXPEDT
	    SetTminTOF $tmin $hst [winfo parent $graph(plot)]
	    # Qmax got bigger. Show the new data?
	    if {$tmin < $oldtmin} {QmaxIncreased}
	}
    } else {
	set tmax [lindex [lindex $exclist end] 0]
	if {$oldtmax != $tmax} {
	    # edited 2theta or Energy max -- reset d-min
	    histinfo $hst dmin set [tod $tmax $hst]
	    RecordMacroEntry "histinfo $hst dmin set [tod $tmax $hst]" 0
	    RecordMacroEntry "incr expgui(changed)" 0
	    if {$tmax > $oldtmax} {QmaxIncreased}
	}
    }
}

# if Qmax has changed, give the user the option to update now so that the
# new data may be seen in the plot
proc QmaxIncreased {} {
    global graph expgui expmap
    set hst $graph(hst)
    set msg "The high Q (low d-space) data limit has changed.\nYou must run POWPREF to "
    append msg "to see the full range of data displayed. Do you want to "
    append msg "run POWPREF (& possibly GENLES with zero cycles)?"
    set ans [MyMessageBox -parent $graph(exclbox) -message $msg -title "Process limits?"\
	    -helplink "expguierr.html ProcessRegions" \
	    -type {Skip {Run POWPREF} {Run POWPREF & GENLES}}]
    if {$ans == "skip"} {
	updateplot
	return
    } elseif {$ans == "run powpref"} {
	set cmd powpref
    } else {
	set cmd "powpref genles"
	expinfo cycles set 0
    }
    set auto $expgui(autoexpload)
    set expgui(autoexpload) 1
    #set expgui(autoiconify) 0
    runGSASwEXP $cmd
    set expgui(autoexpload) $auto
    updateplot
    if {[string range $expmap(htype_$hst) 2 2] != "T"} {CheckTmax}
}

# check the maximum 2theta/energy value against the excluded region
# and reset the limit if it is too high. This is because POWPREF & GENLES
# can be really slow when there are lots of extra reflections generated.
proc CheckTmax {} {
    global graph expgui
    # clone xvec
    xvec dup temp
    set hst $graph(hst)
    if {$graph(xunits) == 1} {
	temp sort
	set max [fromd [temp index 0] $hst]
	set step [expr abs($max - [fromd [temp index 1] $hst])]
    } elseif {$graph(xunits) == 2} {
	temp sort -reverse
	set max [fromQ [temp index 0] $hst]
	set step [expr abs($max - [fromQ [temp index 1] $hst])]
    } else {
	temp sort -reverse
	set max [temp index 0]
	set step [expr $max - [temp index 1]]
    }
    set exclist [histinfo $hst excl]
    if {[lindex [lindex $exclist end] 0] > $max + 10*$step} {
	if {$graph(xunits) == 1} {
	    set msg "The lower data limit ([tod [lindex [lindex $exclist end] 0] $hst] A) " 
	    set d [tod $max $hst]
	    append msg "is much smaller than the smallest data point ($d A)\n"
	    append msg "You are suggested to set the lower d limit to $d A\n"
	} elseif {$graph(xunits) == 2} {
	    set msg "The high Q data limit ([toQ [lindex [lindex $exclist end] 0] $hst] A-1) " 
	    set q [toQ $max $hst]
	    append msg "is much larger than the largest data point ($q A-1)\n"
	    append msg "You are suggested to set the upper Q limit to $q A-1\n"
	} else {
	    set msg "The high Q (low d) data limit ([lindex [lindex $exclist end] 0]) " 
	    append msg "is much larger than the largest data point ($max)\n"
	    append msg "You are suggested to set the limit to $max\n"
	}
	append msg "OK to make this change?"
	set ans [MyMessageBox -parent $graph(exclbox) -message $msg -title "Reset limits?"\
		-helplink "expguierr.html RegionTooBig" \
		-type {OK Cancel}]
	if {$ans == "ok"} {
	    set item [list [expr $max+$step] [lindex [lindex $exclist end] 1]]
	    incr expgui(changed)
	    set exclist [lreplace $exclist end end $item]
	    histinfo $hst excl set $exclist
	    RecordMacroEntry "histinfo $hst excl set [list $exclist]" 0
	    histinfo $hst dmin set [tod $max $hst]
	    RecordMacroEntry "histinfo $hst dmin set [tod $max $hst]" 0
	    RecordMacroEntry "incr expgui(changed)" 0
	    updateplot
	    return
	}
    }
}

# CheckChanges is called before "exiting" (closing the window) to make
# sure that POWPREF gets run before GENLES so that changes made here 
# take effect
proc CheckChanges {startchanges} {
    global expgui graph
    set hst $graph(hst)
    if {$expgui(changed) == $startchanges} return
    set expgui(needpowpref) 2
    set msg "Excluded regions/data range" 
    if {[string first $msg $expgui(needpowpref_why)] == -1} {
	append expgui(needpowpref_why) "\t$msg were changed\n"
    }
}

# called in response to pressing one of the excluded region buttons
# on the bottom bar
proc EditExclRegion {reg "msg {}"} {
    global graph expmap expgui
    set hst $graph(hst)
    set startchanges $expgui(changed)
    set exclist [histinfo $hst excl]
    set oldtmin [lindex [lindex $exclist 0] 1]
    set oldtmax [lindex [lindex $exclist end] 0]
    set i [expr {$reg -1}]
    set range [lindex $exclist $i]
    toplevel [set box $graph(exclbox).edit]
    wm title $box "Edit excluded region"
    set beg minimum
    set end maximum
    set graph(tmin) [format %.4f [lindex $range 0]]
    set graph(tmax) [format %.4f [lindex $range 1]]
    if {$msg != ""} {
	grid [label $box.0 -text $msg -fg red] \
		-column 1 -row 0 -columnspan 99
    }
    if {$graph(xunits) == 1} {
	set var d-space
	set unit A
	set beg maximum
	set end minimum
	set graph(tmin) [format %.4f [tod [lindex $range 0] $hst]]
	set graph(tmax) [format %.4f [tod [lindex $range 1] $hst]]
    } elseif {$graph(xunits) == 2} {
	set var Q
	set unit A-1
	set graph(tmin) [format %.4f [toQ [lindex $range 0] $hst]]
	set graph(tmax) [format %.4f [toQ [lindex $range 1] $hst]]
    } elseif {[string range $expmap(htype_$hst) 2 2] == "T"} {
	set var TOF
	set unit ms
    } elseif {[string range $expmap(htype_$hst) 2 2] == "C"} {
	set var 2theta
	set unit deg
    } elseif {[string range $expmap(htype_$hst) 2 2] == "E"} {
	set var Energy
	set unit KeV
    } else {
	set var ?
	set unit ?
    }
    if {$reg == 1} {
	grid [label $box.1 -text "Editing Data Limits ($unit)"] \
		-column 1 -row 1 -columnspan 99
	grid [label $box.2 -text "$beg $var "] \
		-column 1 -row 2
	grid [entry $box.3 -width 12 -textvariable graph(tmax)] \
		-column 2 -row 2
    } elseif {$reg == [llength $exclist]} {
	grid [label $box.1 -text "Editing Data Limits ($unit)"] \
		-column 1 -row 1 -columnspan 99
	grid [label $box.2 -text "$end $var "] \
		-column 1 -row 2
	grid [entry $box.3 -width 12 -textvariable graph(tmin)] \
		-column 2 -row 2
    } else {
	grid [label $box.1 -text "Editing excluded region #$reg in $var ($unit)"] \
		-column 1 -row 1 -columnspan 99
	grid [label $box.2 -text "$beg $var "] \
		-column 1 -row 2
	grid [entry $box.3 -width 12 -textvariable graph(tmin)] \
		-column 2 -row 2
	grid [label $box.4 -text "$end $var "] \
		-column 1 -row 3
	grid [entry $box.5 -width 12 -textvariable graph(tmax)] \
		-column 2 -row 3
    }
    # save starting values as tmin & tmax
    foreach v {tmin tmax} {
	set $v $graph($v)
    }
    bind $box <Return> "destroy $box"
    grid [frame $box.c] -column 1 -row 99 -columnspan 99
    grid [button $box.c.1 -text "OK" -command "destroy $box"] \
	    -column 1 -row 1
    grid [button $box.c.2 -text "Cancel" \
	    -command "set graph(tmin) $tmin; set graph(tmax) $tmax;destroy $box"] \
	    -column 2 -row 1
    putontop $box
    tkwait window $box
    afterputontop
    if {$tmin != $graph(tmin)} {
	if {[catch {
	    expr $graph(tmin)
	    if {$graph(xunits) == 1} {
		set tmin [fromd $graph(tmin) $hst]
	    } elseif {$graph(xunits) == 2} {
		set tmin [fromQ $graph(tmin) $hst]
	    } else {
		set tmin $graph(tmin)
	    }
	}]} {
	    # recursive call -- should not happen too many times
	    EditExclRegion $reg "Invalid value entered, try again"
	    return
	}
	set exclist [lreplace $exclist $i $i [lreplace $range 0 0 $tmin]]
	incr expgui(changed)
    }
    if {$tmax != $graph(tmax)} {
	if {[catch {
	    expr $graph(tmax)
	    if {$graph(xunits) == 1} {
		set tmax [fromd $graph(tmax) $hst]
	    } elseif {$graph(xunits) == 2} {
		set tmax [fromQ $graph(tmax) $hst]
	    } else {
		set tmax $graph(tmax)
	    }
	}]} {
	    # recursive call -- should not happen too many times
	    EditExclRegion $reg "Invalid value entered, try again"
	    return
	}
	set exclist [lreplace $exclist $i $i [lreplace $range 1 1 $tmax]]
	incr expgui(changed)
    }
    # did anything change?
    if {$expgui(changed) == $startchanges} {return}
    # check and save the changed regions
    CheckForOverlappingRegions $exclist
    CheckQmaxChanged $oldtmin $oldtmax
    updateplot
}

# this is done in response to a change in the window size (<Configure>)
# the change is done only when idle and only gets done once.
proc scheduleFillExclRegionBox {} {
    global graph
    # is an update pending?
    if {$graph(FillExclRegionBox)} return
    set graph(FillExclRegionBox) 1
    after idle FillExclRegionBox
}

# put the background regions into buttons and resize the slider
proc FillExclRegionBox {} {
    global graph expmap
    set hst $graph(hst)
    set can $graph(ExclCanvas)
    set scroll $graph(ExclScroll)
    
    catch {destroy [set top $can.fr]}
    frame $top -class SmallFont
    $can create window 0 0 -anchor nw -window $top
    set exclist [histinfo $hst excl]
    set col 0
    if {[string trim [string range $expmap(htype_$graph(hst)) 3 3]] == "D"} {
	$graph(bbox).bl.1 config -text "Dummy\nHistogram"	
	foreach c {2 3} {
	    $graph(bbox).l.b$c config -state disabled
	}
	if {[string range $expmap(htype_$graph(hst)) 2 2] == "T"} {
	    set fac 1000.
	} elseif {[string range $expmap(htype_$graph(hst)) 2 2] == "E"} {
	    set fac 1.
	} else {
	    set fac 100.
	}	    
	set start [expr {[histinfo $graph(hst) dstart]/$fac}]
	set step  [expr {[histinfo $graph(hst) dstep]/$fac}]
	set points [histinfo $graph(hst) dpoints]
	set end [expr {$start + $points*$step}]
	grid [label $top.$col -text "Range:" \
		    -padx 0 -pady 1 -bd 4] \
		    -row 0 -column $col
	incr col
	if {$graph(xunits) == 1} {
	    foreach i {min max} \
		    v [lsort -real [tod [list $start $end] $graph(hst)]] {
		grid [label $top.$col -text "$i\n[format %.4f $v]" \
			-padx 3 -pady 1 -bd 2 -relief groove] \
			-row 0 -column $col -sticky ns
		incr col
	    }
	    grid [label $top.$col -text "\xc5" \
		    -padx 0 -pady 1 -bd 4] \
		    -row 0 -column $col -sticky nsw -ipadx 5
	    incr col
	    grid [label $top.$col -text "points\n$points" \
		    -padx 3 -pady 1 -bd 2 -relief groove] \
		    -row 0 -column $col -sticky ns
	    incr col
	} elseif {$graph(xunits) == 2} {
	    foreach i {min max} \
		    v [lsort -real [toQ [list $start $end] $graph(hst)]] {
		grid [label $top.$col -text "$i\n[format %.3f $v]" \
			-padx 3 -pady 1 -bd 2 -relief groove] -row 0 -column $col -sticky ns
		incr col
	    }
	    grid [label $top.$col -text "\xc5" \
		    -padx 0 -pady 1] \
		    -row 0 -column $col
	    incr col
	    grid [label $top.$col -text "-1\n" \
		    -padx 0 -pady 0] \
		    -row 0 -column $col -sticky nsw -ipadx 5
	    incr col
	    grid [label $top.$col -text "points\n$points" \
		    -padx 3 -pady 1 -bd 2 -relief groove] -row 0 -column $col -sticky ns
	    incr col
	} else {
	    foreach i {start step end} {
		grid [label $top.$col -text "$i\n[set $i]" \
			-padx 3 -pady 1 -bd 2 -relief groove] \
			-row 0 -column $col -sticky ns
		incr col
	    }
	}
	grid [button $top.b$col -text Continue \
		-command "SetDummyRangeBox $graph(hst) $start $end $step"] \
		-sticky ns -row 0 -column $col
    } else {
	$graph(bbox).bl.1 config -text "Excluded\nRegions"
	foreach c {2 3} {
	    $graph(bbox).l.b$c config -state normal
	}
	foreach rng $exclist {
	    if {$graph(xunits) == 1} {
		set rng [tod $rng $hst]
		if {$col == 0} {
		    set lbl "<[format %.4f [lindex $rng 1]]"
		} else {
		    set lbl "[format %.4f [lindex $rng 0]]\nto [format %.4f [lindex $rng 1]]"
		}
		incr col
		if {$col == [llength $exclist]} {
		    set lbl ">[format %.4f [lindex $rng 0]]"
		}
	    } else {
		if {$graph(xunits) == 2} {
		    set rng [toQ $rng $hst]
		}
		if {$col == 0} {
		    set lbl "<[format %.3f [lindex $rng 1]]"
		} else {
		    set lbl "[format %.3f [lindex $rng 0]]\nto [format %.3f [lindex $rng 1]]"
		}
		incr col
		if {$col == [llength $exclist]} {
		    set lbl ">[format %.3f [lindex $rng 0]]"
		}
	    }
	    grid [button $top.$col -text $lbl -command "EditExclRegion $col" \
		    -padx 1 -pady 1] -row 0 -column $col -sticky  ns
	}
    }
    update idletasks
    set sizes [grid bbox $top]
    $can config -scrollregion $sizes -height [lindex $sizes 3]
    if {[lindex $sizes 2] <= [winfo width $can]} {
	grid forget $scroll
    } else {
	grid $graph(ExclScroll) -column 1 -row 4 -columnspan 5 -sticky nsew
    }
    # clear flag
    set graph(FillExclRegionBox) 0
}

# manual zoom option
proc BLTplotManualZoom {} {
    global graph
    set parent [winfo parent graph(plot)]
    if {$parent == "."} {set parent ""}
    set box ${parent}.zoom
    catch {toplevel $box}
    wm title $box "Manual zoom"
    eval destroy [grid slaves $box]
    raise $box
    wm title $box {Manual Scaling}
    grid [label $box.l1 -text minimum] -row 1 -column 2 
    grid [label $box.l2 -text maximum] -row 1 -column 3 
    grid [label $box.l3 -text x] -row 2 -column 1 
    grid [label $box.l4 -text y] -row 3 -column 1 
    grid [entry $box.xmin -textvariable graph(xmin) -width 10] -row 2 -column 2 
    grid [entry $box.xmax -textvariable graph(xmax) -width 10] -row 2 -column 3 
    grid [entry $box.ymin -textvariable graph(ymin) -width 10] -row 3 -column 2 
    grid [entry $box.ymax -textvariable graph(ymax) -width 10] -row 3 -column 3 
    grid [frame $box.b] -row 4 -column 1 -columnspan 3
    grid [button $box.b.1 -text "Set Scaling" \
	     -command "SetManualZoom set"]  -row 4 -column 1 -columnspan 2
    grid [button $box.b.2 -text Reset \
	    -command "SetManualZoom clear"] -row 4 -column 3
    grid [button $box.b.3 -text Close -command "destroy $box"] -row 4 -column 4 
    grid rowconfigure $box 1 -weight 1 -pad 5
    grid rowconfigure $box 2 -weight 1 -pad 5
    grid rowconfigure $box 3 -weight 1 -pad 5
    grid rowconfigure $box 4 -weight 0 -pad 5
    grid columnconfigure $box 1 -weight 1 -pad 20
    grid columnconfigure $box 1 -weight 1 
    grid columnconfigure $box 3 -weight 1 -pad 10
    foreach item {min min max max} \
	    format {3   2   3   2} \
	    axis   {x   y   x   y} {
	set val [$graph(plot) ${axis}axis cget -${item}]
	set graph(${axis}${item}) {(auto)}
	catch {set graph(${axis}${item}) [format %.${format}f $val]}
    }
    putontop $box
    tkwait window $box
    afterputontop    
}

proc SetManualZoom {mode} {
    global graph
    if {$mode == "clear"} {
	foreach item {xmin ymin xmax ymax} {
	    set graph($item) {(auto)}
	}
    }
    foreach item {xmin ymin xmax ymax} {
	if {[catch {expr $graph($item)}]} {
	    set $item ""
	} else {
	    set $item $graph($item)
	}
    }
    # reset the zoomstack
    catch {Blt_ZoomStack $graph(plot)}
    catch {$graph(plot) xaxis config -min $xmin -max $xmax}
    catch {$graph(plot) yaxis config -min $ymin -max $ymax}
}

# move the zoom region around
proc ScanZoom {box key frac} {
    foreach var  {xl xh yl yh} axis {xaxis  xaxis  yaxis  yaxis} \
	    flg  {-min -max -min -max} {
	set $var [$box $axis cget $flg]
	if {$var == ""} return
    }
    catch {
	switch -- $key {
	    Right {set a x; set l $xl; set h $xh; set d [expr {$frac*($h-$l)}]}
	    Left {set a x; set l $xl; set h $xh; set d [expr {-$frac*($h-$l)}]}
	    Up   {set a y; set l $yl; set h $yh; set d [expr {$frac*($h-$l)}]}
	    Down {set a y; set l $yl; set h $yh; set d [expr {-$frac*($h-$l)}]}
	}
	$box ${a}axis configure -min [expr {$l + $d}] -max [expr {$h + $d}]
    }
}

# code to create the EXCLEDT box
proc ShowExcl {} {
    global graph peakinfo expgui expmap
    # save the starting number of cycles & starting point
    set cycsav [expinfo cycles]
    set startchanges $expgui(changed)
    set graph(hst) [lindex $expgui(curhist) 0]
    if {[llength $expgui(curhist)] == 0} {
	set graph(hst) [lindex $expmap(powderlist) 0]
    } else {
	set graph(hst) [lindex $expmap(powderlist) $graph(hst)]
    }    
    set graph(exclbox) .excl
    catch {toplevel $graph(exclbox)}
    wm title $graph(exclbox) "Excluded Region/Data Range Edit"
    eval destroy [winfo children $graph(exclbox)]
    # create the graph
    if [catch {
	set graph(plot) [graph $graph(exclbox).g -plotbackground white]
    } errmsg] {
	set msg "BLT Setup Error: could not create a graph" 
	append msg "\n(error msg: $errmsg)."
	append msg "\nThere is a problem with the setup of BLT on your system."
	append msg "\nSee the expgui.html file for more info."
	MyMessageBox -parent $graph(exclbox) -title "BLT Error" \
	    -message $msg \
	    -helplink "expgui.html blt" \
	-icon warning -type Skip -default "skip" 
	destroy $graph(exclbox)
	return
    }
    if [catch {
	Blt_ZoomStack $graph(plot)
    } errmsg] {
	set msg "BLT Setup Error: could not access a Blt_ routine"
	append msg "\nBLT Setup Error: "
	append msg "\n(error msg: $errmsg)."
	append msg "\nSee the expgui.html file for more info."
	append msg "\nThe pkgIndex.tcl is probably not loading bltGraph.tcl."
	append msg "\nSee the expgui.html file for more info."
	MyMessageBox -parent $graph(exclbox) -title "BLT Error" \
	    -message $msg \
	    -helplink "expgui.html blt" \
	    -icon warning -type {"Limp Ahead"} -default "limp Ahead" 
    }
    $graph(plot) element create 3 -color black -linewidth 0 -label Obs \
	    -symbol $peakinfo(obssym) -color $graph(color_obs) \
	    -pixels [expr 0.125 * $peakinfo(obssize)]i
    $graph(plot) element create 2 -label Calc -color $graph(color_calc) \
	    -symbol none  
    $graph(plot) element create 12 -line 0 -label "Excl" \
	    -color $graph(color_excl) \
	    -symbol $peakinfo(exclsym) \
	    -pixels [expr 0.15 * $peakinfo(exclsize)]i
    $graph(plot) element show "3 2 12 1"
    $graph(plot) element config 3 -xdata xvec -ydata obsvec
    $graph(plot) element config 2 -xdata xvec -ydata calcvec
    $graph(plot) element config 12 -xdata exxvec -ydata exobsvec

    $graph(plot) yaxis config -title {} 
    setlegend $graph(plot) $graph(legend)

    set graph(exclmenu) [frame $graph(exclbox).a -bd 3 -relief groove]
    pack [menubutton $graph(exclmenu).file -text File -underline 0 \
	    -menu $graph(exclmenu).file.menu] -side left
    menu $graph(exclmenu).file.menu
    $graph(exclmenu).file.menu add cascade -label Tickmarks \
	    -menu $graph(exclmenu).file.menu.tick
    menu $graph(exclmenu).file.menu.tick

    $graph(exclmenu).file.menu add cascade -label Histogram \
	    -menu $graph(exclmenu).file.menu.hist -state disabled

    $graph(exclmenu).file.menu add command \
	    -label "Set Min/Max Range" -command setminormax
    $graph(exclmenu).file.menu add command \
	    -label "Update Plot" -command "CheckChanges $startchanges;updateplot"
    $graph(exclmenu).file.menu add command \
	    -label "Make PostScript" -command "MakePostscriptOut $graph(exclbox)"
    $graph(exclmenu).file.menu add command \
	    -label Finish -command "CheckChanges $startchanges;destroy $graph(exclbox)"

    pack [menubutton $graph(exclmenu).options -text Options -underline 0 \
	    -menu $graph(exclmenu).options.menu] \
	    -side left    
    menu $graph(exclmenu).options.menu
    $graph(exclmenu).options.menu add cascade -label "Configure Tickmarks" \
	    -menu $graph(exclmenu).options.menu.tick
    menu $graph(exclmenu).options.menu.tick
    $graph(exclmenu).options.menu.tick add radiobutton \
	    -label "Manual Placement" \
	    -value 0 -variable expgui(autotick) -command plotExclData
    $graph(exclmenu).options.menu.tick add radiobutton \
	    -label "Auto locate" \
	    -value 1 -variable expgui(autotick) -command plotExclData
    $graph(exclmenu).options.menu.tick add separator

    $graph(exclmenu).options.menu add cascade -label "Symbol Type" \
	    -menu $graph(exclmenu).options.menu.sym
    menu $graph(exclmenu).options.menu.sym
    foreach var {excl obs} lbl {Excluded Observed} {
	$graph(exclmenu).options.menu.sym add command -label $lbl \
		-command "GetSymbolOpts $var $graph(exclbox)"
    }

    $graph(exclmenu).options.menu add cascade -label "Symbol color" \
	    -menu $graph(exclmenu).options.menu.color
    menu $graph(exclmenu).options.menu.color
    foreach var {excl calc obs} lbl {Excluded Calculated Observed} {
	$graph(exclmenu).options.menu.color add command -label $lbl \
		-command "set graph(color_$var) \[tk_chooseColor -initialcolor \$graph(color_$var) -title \"Choose \$lbl color\"]; plotExclData"
    }
    $graph(exclmenu).options.menu add cascade -label "X units" \
	    -menu $graph(exclmenu).options.menu.xunits
    menu $graph(exclmenu).options.menu.xunits
    $graph(exclmenu).options.menu.xunits add radiobutton \
	    -label "As collected" \
	    -variable graph(xunits) -value 0 \
	    -command updateplot
    $graph(exclmenu).options.menu.xunits add radiobutton -label "d-space" \
	    -variable graph(xunits) -value 1 \
	    -command updateplot
    $graph(exclmenu).options.menu.xunits add radiobutton -label "Q" \
	    -variable graph(xunits) -value 2 \
	    -command updateplot

    $graph(exclmenu).options.menu add checkbutton -label "Include legend" \
	    -variable graph(legend) \
	    -command {setlegend $graph(plot) $graph(legend)}
    $graph(exclmenu).options.menu add checkbutton -label "Prompt on add/del" \
	    -variable graph(exclPrompt)
    $graph(exclmenu).options.menu add command -label "Set PS output" \
	    -command "SetPostscriptOut $graph(exclbox)"
    # phase options
    set box $graph(plot)
    set win [winfo toplevel $graph(plot)]
    foreach num $expmap(phaselist) {
	$graph(exclmenu).file.menu.tick add checkbutton -label "Phase $num" \
		-variable peakinfo(flag$num)
	bind $win <Key-$num> \
		"set peakinfo(flag$num) \[expr !\$peakinfo(flag$num)\]"
	$graph(exclmenu).options.menu.tick add command -label "Phase $num" \
		-command "minioptionsbox $num"
    }
    bind $win <Key-Up> "ScanZoom $box %K 0.1"
    bind $win <Key-Left> "ScanZoom $box %K 0.1"
    bind $win <Key-Right> "ScanZoom $box %K 0.1"
    bind $win <Key-Down> "ScanZoom $box %K 0.1"
    bind $win <Control-Key-Up> "ScanZoom $box %K 1.0"
    bind $win <Control-Key-Left> "ScanZoom $box %K 1.0"
    bind $win <Control-Key-Right> "ScanZoom $box %K 1.0"
    bind $win <Control-Key-Down> "ScanZoom $box %K 1.0"

    set graph(bbox) [set bb $graph(exclbox).b]
    catch {pack [frame $bb -bd 3 -relief sunken] -side bottom -fill both}
    grid [label $bb.top -text "Excluded Region Editing"] \
	    -column 0 -row 0 -columnspan 4
    grid [button $bb.help -text Help -bg yellow \
	    -command "MakeWWWHelp excledt.html"] \
	    -column 5 -row 0 -rowspan 1 -sticky ne
    
    grid [frame $bb.l -bd 3 -relief groove] \
	    -column 0 -row 1 -columnspan 2 -sticky nse
    grid [label $bb.l.1 -text "Mouse click\naction"] -column 0 -row 0
    foreach c {1 2 3} l {zoom "Add\nregion" "Delete\nregion"} {
	grid [button $graph(bbox).l.b$c -text $l -command "exclEditMode $c $bb"] \
		-column $c -row 0 -sticky ns
    }
    exclEditMode 1 $bb

    grid [frame $bb.bl] \
	    -column 0 -row 3 -rowspan 2 -sticky nsew
    grid [label $graph(bbox).bl.1 -text "Excluded\nRegions"] -column 0 -row 0 
    grid [canvas [set graph(ExclCanvas) $bb.bc] \
	    -scrollregion {0 0 5000 500} -width 0 -height 0 \
	    -xscrollcommand "$bb.bs set"] \
	    -column 1 -row 3 -columnspan 5 -sticky nsew
    grid [scrollbar [set  graph(ExclScroll) $bb.bs] -command "$bb.bc xview" \
	    -orient horizontal] \
	    -column 1 -row 4 -columnspan 5 -sticky nsew
    grid [button $bb.cw -text "Save &\nFinish" \
	    -command "CheckChanges $startchanges;destroy $graph(exclbox)"] \
	-column 4 -row 1 -columnspan 2 -sticky ns

    grid columnconfigure $bb 1 -weight 1
    grid columnconfigure $bb 5 -weight 1
    grid rowconfigure $bb 3 -weight 1
    grid rowconfigure $bb 5 -weight 1
    
    pack $graph(exclmenu) -side top -fill both
    pack $graph(plot) -fill both -expand yes

    # fill the histogram menu
    if {[llength $expmap(powderlist)] > 15} {
	set expgui(plotlist) {}
	$graph(exclmenu).file.menu entryconfigure Histogram -state normal
	menu $graph(exclmenu).file.menu.hist
	set i 0
	foreach num [lsort -integer $expmap(powderlist)] {
	    incr i
	    lappend expgui(plotlist) $num
	    if {$i == 1} {
		set num1 $num
		menu $graph(exclmenu).file.menu.hist.$num1
	    }
	    $graph(exclmenu).file.menu.hist.$num1 add radiobutton \
		    -label $num -value $num \
		    -variable graph(hst) \
		    -command updateplot
	    if {$i >= 10} {
		set i 0
		$graph(exclmenu).file.menu.hist add cascade \
			-label "$num1-$num" \
			-menu $graph(exclmenu).file.menu.hist.$num1
	    }
	}
	if {$i != 0} {
	    $graph(exclmenu).file.menu.hist add cascade \
		    -label "$num1-$num" \
		    -menu $graph(exclmenu).file.menu.hist.$num1
	}
    } elseif {[llength $expmap(powderlist)] > 1} {
	$graph(exclmenu).file.menu entryconfigure Histogram -state normal
	menu $graph(exclmenu).file.menu.hist
	set i 0
	foreach num [lsort -integer $expmap(powderlist)] {
	    foreach num [lsort -integer $expmap(powderlist)] {
		lappend expgui(plotlist) $num
		$graph(exclmenu).file.menu.hist add radiobutton \
			-label $num -value $num \
			-variable graph(hst) \
			-command updateplot
	    }
	}
    } else {
	set expgui(plotlist) [lindex $expmap(powderlist) 0]
    }

    # N = load next histogram
    bind $graph(exclbox) <Key-n> {
	global expgui graph
	set i [lsearch $expgui(plotlist) $graph(hst)]
	incr i
	if {$i >= [llength $expgui(plotlist)]} {set i 0}
	set graph(hst) [lindex $expgui(plotlist) $i]
	updateplot
    }
    bind $graph(exclbox) <Key-N> {
	global expgui graph
	set i [lsearch $expgui(plotlist) $graph(hst)]
	incr i
	if {$i >= [llength $expgui(plotlist)]} {set i 0}
	set graph(hst) [lindex $expgui(plotlist) $i]
	set cycle [getcycle];readdata .g
    }
    bind $graph(exclbox) <Key-z> {BLTplotManualZoom}
    bind $graph(exclbox) <Key-Z> {BLTplotManualZoom}
    updateplot
    trace variable peakinfo w plotExclData

    # catch exits -- launch POWPREF; if changes non-zero
    wm protocol $graph(exclbox) WM_DELETE_WINDOW "CheckChanges $startchanges;destroy $graph(exclbox)"
    # respond to resize events & control C (except on Windows)
    if {$::tcl_platform(platform) != "windows"} {
	bind $graph(exclbox) <Configure> scheduleFillExclRegionBox
	bind all <Control-KeyPress-c> "CheckChanges $startchanges;destroy $graph(exclbox)"
    }
    #putontop $graph(exclbox)
    wm deiconify $graph(exclbox)
    wm iconify .
    update
    tkwait window $graph(exclbox)
    #afterputontop
    wm deiconify .
    if {$::tcl_platform(platform) != "windows"} {
	bind all <Control-c> catchQuit
    }

    # reset the number of cycles if they have changed
    if {$cycsav != [expinfo cycles]} {
	global entryvar
	set entryvar(cycles) $cycsav
    }
}

proc SetDummyRangeBox {hst tmin tmax tstep} {
    global newhist expmap graph
    if {[histinfo $hst dtype] != "CONST"} {
	MyMessageBox -parent $graph(exclbox) -title  "Change Range Error" \
		-message "This histogram (#$hst) does not have constant steps. The range must be changed in EXPEDT." \
		-icon error -type ok -default ok \
		-helplink "excledt.html editdummy"
	return
    }
    catch {toplevel [set np "$graph(exclbox).dummy"]}
    wm title $np "Dummy Histogram Range"
    eval destroy [winfo children $np]
    # delete old traces, if any
    foreach var {tmin tmax tstep} {
	foreach v [ trace vinfo newhist($var)] {
	    eval trace vdelete newhist($var) $v
	}
    }
    # set defaults to current values
    foreach v {tmin tmax tstep} {set newhist($v) [set $v]}
    trace variable newhist(tmin) w "ValidateDummyRange $np $hst"
    trace variable newhist(tmax) w "ValidateDummyRange $np $hst"
    trace variable newhist(tstep) w "ValidateDummyRange $np $hst"
    pack [frame $np.d1]
    grid [label $np.d1.l1 -text min] -column 1 -row 1
    grid [label $np.d1.l2 -text max] -column 2 -row 1
    grid [label $np.d1.l3 -text step] -column 3 -row 1
    grid [label $np.d1.lu -text ""] -column 4 -row 1 -rowspan 2
    grid [entry $np.d1.e1 -width 10 -textvariable newhist(tmin)] -column 1 -row 2
    grid [entry $np.d1.e2 -width 10 -textvariable newhist(tmax)] -column 2 -row 2
    grid [entry $np.d1.e3 -width 10 -textvariable newhist(tstep)] -column 3 -row 2
    grid [label $np.d1.m1 -anchor w -padx 5] -column 1 -row 3 -sticky ew
    grid [label $np.d1.m2 -anchor w -padx 5] -column 2 -row 3 -sticky ew
    label $np.dl1 -text "Data range:"
    label $np.dl2 -text "Allowed"
    label $np.dl3 -text "\n" -justify left -fg blue
    grid [frame $np.f6] -column 0 -row 99 -columnspan 5 -sticky ew 
    grid [button $np.f6.b6a -text Change \
	    -command "SetDummyRange $np $hst"] -column 0 -row 0
    bind $np <Return> "SetDummyRange $np $hst"
    grid [button $np.f6.b6b -text Cancel \
	    -command "destroy $np"] -column 1 -row 0
    set link "excledt.html editdummy"
    bind $np <Key-F1> "MakeWWWHelp $link"
    grid [button $np.f6.help -text Help -bg yellow \
	    -command "MakeWWWHelp $link"] \
	    -column 2 -row 0 -sticky e
    grid columnconfigure $np.f6 2 -weight 1

    $np.d1.m1 config -text {}
    $np.d1.m2 config -text {}
    grid $np.dl1 -column 0 -row 8
    grid $np.d1 -column 1 -row 8 -rowspan 2 -columnspan 4 -sticky e
    grid $np.dl3 -column 0 -columnspan 99 -row 10 -sticky ew
    grid [label $np.l1 -text "Set range for dummy histogram $hst" \
	    -justify center -anchor center -bg beige] \
	    -row 0 -column 0 -columnspan 5 -sticky ew
    if {[string range $expmap(htype_$hst) 2 2] == "T"} {
	$np.dl1 config -text "Data range:\n(TOF)"
	$np.d1.lu config -text millisec
	grid $np.dl2 -column 0 -row 9
	catch {
	    set line [histinfo $hst ITYP]
	    $np.d1.m1 config -text [lindex $line 1]
	    $np.d1.m2 config -text [lindex $line 2]
	}
    } elseif {[string range $expmap(htype_$hst) 2 2] == "C"} {
	$np.dl1 config -text "Data range:\n(2Theta)"
	$np.d1.lu config -text degrees
	$np.d1.m1 config -text >0.
	$np.d1.m2 config -text <180.
    } elseif {[string range $expmap(htype_$hst) 2 2] == "E"} {
	$np.dl1 config -text "Data range:\n(Energy)"
	$np.d1.lu config -text KeV
	$np.d1.m1 config -text 1.
	$np.d1.m2 config -text 200.
	grid $np.dl2 -column 0 -row 9
    }
    ValidateDummyRange $np $hst
    putontop $np
    grab $np
    tkwait window $np
    afterputontop    
}

proc ValidateDummyRange {np hst args} {
    # validate input
    global newhist expmap
    set msg {}
    $np.dl3 config -text "\n"
    foreach e {e1 e2 e3} v {tmin tmax tstep} {
	if [catch {expr $newhist($v)}] {
	    $np.d1.$e config -fg red
	    append msg "Value of $newhist($v) is invalid for $v\n"
	} else {
	    $np.d1.$e config -fg black
	}
    }
    if {$newhist(tmax) <= $newhist(tmin)} {
	$np.d1.e1 config -fg red
	$np.d1.e2 config -fg red
	return "Tmax <= Tmin\n"
    }


    set dmin -1
    set dmax -1
    if {[string range $expmap(htype_$hst) 2 2] == "T"} {
	catch {
	    set line [histinfo $hst ITYP]
	    set tmin [lindex $line 1]
	    set tmax [lindex $line 2]
	    if {$newhist(tmin) <$tmin } {
		$np.d1.e1 config -fg red
		append msg "Min value of $newhist(tmin) msec is invalid.\n"
	    }
	    if {$newhist(tmax) >$tmax } {
		$np.d1.e2 config -fg red
		append msg "Max value of $newhist(tmax) msec is invalid.\n"
	    }
	    set difc [histinfo $hst difc]
	    set dmin [expr {1000. * $newhist(tmin) / $difc}]
	    set dmax [expr {1000. * $newhist(tmax) / $difc}]
	}
    } elseif {[string range $expmap(htype_$hst) 2 2] == "C"} {
	if {$newhist(tmin) <= 0 } {
	    $np.d1.e1 config -fg red
	    append msg "Min value of $newhist(tmin) degrees is invalid.\n"
	}
	if {$newhist(tmax) >=180 } {
	    $np.d1.e2 config -fg red
	    append msg "Max value of $newhist(tmax) degrees is invalid.\n"
	}
	catch {
	    set lam [histinfo $hst lam1]
	    set dmin [expr {$lam * 0.5 / sin(acos(0.)*$newhist(tmax)/180.)}]
	    set dmax [expr {$lam * 0.5 / sin(acos(0.)*$newhist(tmin)/180.)}]
	}
    } else {
	if {$newhist(tmin) <1 } {
	    $np.d1.e1 config -fg red
	    append msg "Min value of $newhist(tmin) KeV is invalid.\n"
	}
	if {$newhist(tmax) >200 } {
	    $np.d1.e2 config -fg red
	    append msg "Max value of $newhist(tmax) KeV is invalid.\n"
	}
	catch {
	    set ang [histinfo $hst lam1]
	    set dmin [expr {12.398/ (2.0*sin($ang*acos(0.)/180) * \
		    $newhist(tmax))}]
	    set dmax [expr {12.398/ (2.0*sin($ang*acos(0.)/180) * \
		    $newhist(tmin))}]
	}
    }
    if {$msg != ""} {return $msg}
    set pnts -1
    catch {
	set pnts [expr {1+int(($newhist(tmax) - $newhist(tmin))/$newhist(tstep))}]
	set qmin [expr {4.*acos(0)/$dmax}]
	set qmax [expr {4.*acos(0)/$dmin}]
    }
    if {$pnts <= 0} {
	$np.d1.e3 config -fg red
	append msg "Step value of $newhist(tstep) is invalid.\n"
    }
    if {$pnts >20000} {
	$np.d1.e3 config -fg red
	append msg "Step value of $newhist(tstep) is too small (>20000 points).\n"
    }
    if {$msg != ""} {return $msg}
    if {$dmin > 0 && $dmax > 0} {
	catch {
	    set msg [format \
		    "  %d points.%s  D-space range: %.2f-%.2f \xc5,  Q: %.2f-%.2f/\xc5" \
		    $pnts "\n" $dmin $dmax $qmin $qmax]
	    $np.dl3 config -text $msg
	}
    }
    if {$msg != ""} {return ""}
    $np.dl3 config -text [format {  %d points.%s  Range: ?} $pnts "\n"]
    return "Invalid data range -- something is wrong!"
}

proc SetDummyRange {np hst} {
    global newhist expmap
    # validate last time
    set msg [ValidateDummyRange $np $hst]
    if {$msg != ""} {
	MyMessageBox -parent $np -title  "Change Range Error" \
		-message "The following error(s) were found in your input:\n$msg" \
		-icon error -type ok -default ok \
		-helplink "excledt.html editdummy"
	return
    }
    set pnts [expr {1+int(($newhist(tmax) - $newhist(tmin))/$newhist(tstep))}]

    if {[string range $expmap(htype_$hst) 2 2] == "T"} {
	lappend exclist "0 [expr {$newhist(tmin)-$newhist(tstep)}]" \
		"[expr {$newhist(tmax)+$newhist(tstep)}] 1000."
	histinfo $hst excl set $exclist
	histinfo $hst dpoints set $pnts
	histinfo $hst dstart  set [expr {$newhist(tmin)*1000.}]
	histinfo $hst dstep   set [expr {$newhist(tstep)*1000.}]
	histinfo $hst dmin set [tod $newhist(tmin) $hst]
	RecordMacroEntry "histinfo $hst excl set [list $exclist]" 0
	RecordMacroEntry "histinfo $hst dpoints set $pnts" 0
	RecordMacroEntry "histinfo $hst dstart  set [expr {$newhist(tmin)*1000.}]" 0
	RecordMacroEntry "histinfo $hst dstep   set [expr {$newhist(tstep)*1000.}]" 0
	RecordMacroEntry "histinfo $hst dmin set [tod $newhist(tmin) $hst]" 0
    } elseif {[string range $expmap(htype_$hst) 2 2] == "C"} {
	lappend exclist "0 [expr {$newhist(tmin)-$newhist(tstep)}]" \
		"[expr {$newhist(tmax)+$newhist(tstep)}] 1000."
	histinfo $hst excl set $exclist
	histinfo $hst dpoints set $pnts
	histinfo $hst dstart  set [expr {$newhist(tmin)*100.}]
	histinfo $hst dstep   set [expr {$newhist(tstep)*100.}]
	histinfo $hst dmin set [tod $newhist(tmax) $hst]
	RecordMacroEntry "histinfo $hst excl set [list $exclist]" 0
	RecordMacroEntry "histinfo $hst dpoints set $pnts" 0
	RecordMacroEntry "histinfo $hst dstart  set [expr {$newhist(tmin)*100.}]" 0
	RecordMacroEntry "histinfo $hst dstep   set [expr {$newhist(tstep)*100.}]" 0
	RecordMacroEntry "histinfo $hst dmin set [tod $newhist(tmin) $hst]" 0
    } else {
	lappend exclist "0 [expr {$newhist(tmin)-$newhist(tstep)}]" \
		"[expr {$newhist(tmax)+$newhist(tstep)}] 1000."
	histinfo $hst excl set $exclist
	histinfo $hst dpoints set $pnts
	histinfo $hst dstart  set $newhist(tmin)
	histinfo $hst dstep   set $newhist(tstep)
	histinfo $hst dmin set [tod $newhist(tmax) $hst]
	RecordMacroEntry "histinfo $hst excl set [list $exclist]" 0
	RecordMacroEntry "histinfo $hst dpoints set $pnts" 0
	RecordMacroEntry "histinfo $hst dstart  set $newhist(tmin)" 0
	RecordMacroEntry "histinfo $hst dstep   set $newhist(tstep)" 0
	RecordMacroEntry "histinfo $hst dmin set [tod $newhist(tmin) $hst]" 0
    }
    global expgui
    incr expgui(changed) 5
    RecordMacroEntry "incr expgui(changed)" 0
    destroy $np
    updateplot
}

# set the minimum tof/d-space using the EXPEDT program
proc SetTminTOF {tmin hst parent} {
    global expgui

    set errmsg [runSetTminTOF $tmin $hst]
    # save call to Macro file
    RecordMacroEntry "runSetTminTOF $tmin $hst" 0
    RecordMacroEntry "incr expgui(changed)" 0

    if {$expgui(showexptool) || $errmsg != ""} {
	if {$errmsg != ""} {
	    set err 1
	    append errmsg "\n" $expgui(exptoolout) 
	} else {
	    set err 0
	    set errmsg $expgui(exptoolout) 
	}
	set msg "Please review the result from listing the phase." 
	if {$errmsg != ""} {append msg "\nIt appears an error occurred!"}
	ShowBigMessage $parent.msg $msg $errmsg OK "" $err
    }
}
proc runSetTminTOF {tmin hst} {
    global expgui tcl_platform
    set input [open excl$hst.inp w]
    puts $input "Y"
    puts $input "p h e $hst"
    puts $input "T"
    puts $input "$tmin"
    puts $input "/"
    puts $input "x x x"
    puts $input "x"
    close $input
    # Save the current exp file
    savearchiveexp
    # disable the file changed monitor
    set expgui(expModifiedLast) 0
    set expnam [file root [file tail $expgui(expfile)]]
    set err [catch {
	if {$tcl_platform(platform) == "windows"} {
	    exec [file join $expgui(gsasexe) expedt.exe] $expnam < excl$hst.inp >& excl$hst.out
	} else {
	    exec [file join $expgui(gsasexe) expedt] $expnam < excl$hst.inp >& excl$hst.out
	}
    } errmsg]
    set fp [open excl$hst.out r]
    set expgui(exptoolout) [read $fp]
    close $fp
    loadexp $expgui(expfile)
    catch {file delete excl$hst.inp excl$hst.out}
    if {$err} {
	return $errmsg
    } else {
	return ""
    }
}
