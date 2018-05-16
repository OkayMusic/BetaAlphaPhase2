package require Tk
catch {
    package require tkcon
    tkcon show
}
set job(rows) 3
set job(cols) 5
set job(edit) 1
set job(win) .a

proc makeTop {} {
    global job
    catch {destroy $job(win)}
    toplevel $job(win)
    
    grid [canvas $job(win).c -scrollregion {0 0 500 500} -width 100 -height 100 \
	      -xscrollcommand "$job(win).x set" \
	      -yscrollcommand "$job(win).y set"] \
	-column 1 -row 1 -sticky news
    bind $job(win).c <Configure> ResizeWin

    grid columnconfigure $job(win) 1 -weight 1
    grid rowconfigure $job(win) 1 -weight 1
    
    grid [scrollbar $job(win).x -orient horizontal \
	      -takefocus 0 -command "$job(win).c xview"] \
	-column 1 -row 2 -sticky ew
    grid [scrollbar $job(win).y -takefocus 0 \
	      -command "$job(win).c yview"] -column 2 -row 1 -sticky ns

    frame [set job(frame) $job(win).c.fr]
    $job(win).c create window 0 0 -anchor nw -window $job(frame)
    grid [frame $job(win).f] -column 1 -row 3 -sticky w
    set col 0
    grid [label $job(win).f.c1 -text "Columns:"] \
	-column [incr col] -row 3
    grid [entry $job(win).f.c2 -textvariable job(cols) -width 4 -takefocus 0] \
	-column [incr col] -row 3
    bind $job(win).f.c2 <Return> makeWin
    grid [scrollbar $job(win).f.c3 -command "NewsizeWin cols "] \
	-column [incr col] -row 3
    grid [label $job(win).f.r1 -text "Rows:"] \
	-column [incr col] -row 3
    grid [entry $job(win).f.r2 -textvariable job(rows) -width 4 -takefocus 0] \
	-column [incr col] -row 3
    bind $job(win).f.r2 <Return> makeWin
    grid [scrollbar $job(win).f.r3 -command "NewsizeWin rows "] \
	-column [incr col] -row 3
    grid [button $job(win).f.b1 -text "Resize" -command makeWin -takefocus 0] \
	-column [incr col] -row 3
    grid [button $job(win).f.b2 -text "Copy\nDown" -command CopyDown -takefocus 0] \
	-column [incr col] -row 3
    grid [frame $job(win).f.f] -column [incr col] -row 3
    grid [radiobutton $job(win).f.f.a -text "Edit entries" -command makeWin -value 1 \
	      -variable job(edit)  -takefocus 0] -column 1 -row 1 -sticky w
    grid [radiobutton $job(win).f.f.b -text "Show values" -command makeWin -value 0 \
	      -variable job(edit) -takefocus 0] -column 1 -row 2 -sticky w
}

proc NewsizeWin {var dir} {
    global job
    #puts job($var)
    if {$dir == -1} {
	incr job($var)
    } else {
	incr job($var) -1
    }
    makeWin
}

proc CopyDown {} {
    global job
    set w [focus]
    set frame ""    
    set b ""
    set c ""
    regexp {(.*fr)\.([0-9]+)_(.*)} $w junk frame b c
    if {$frame == "" || $b == "" || $c == ""} {
	bell
	return
    }
    set val [$w get]
    for {set r $b} {$r <= $job(rows)} {incr r} {
	$frame.${r}_$c delete 0 end
	$frame.${r}_$c insert 0 $val
    }
}

proc DupRow {w args} {
    global job
    set val [$w get]
    regexp {(.*)\.([0-9]+)_(.*)} $w junk frame b c
    for {set r $b} {$r <= $job(rows)} {incr r} {
	$frame.${r}_$c delete 0 end
	$frame.${r}_$c insert 0 $val
    }
}

proc makeWin {args} {
    global job
    eval destroy [winfo children $job(frame)]
    grid [label $job(frame).0_0 -text "\$j" -width 3] -column 0 -row 0
    grid [label $job(frame).0_d -text "done" -width 3] -column 1 -row 0
    grid [label $job(frame).0_e -text "GSAS .raw file"] -column 3 -row 0
    grid [label $job(frame).0_f -text "Starting .EXP file"] -column 4 -row 0
    for {set c 1} {$c <= $job(cols)} {incr c} {
	set col [expr {$c+4}]
	set i [expr {($c-1) % 26}]
	set char [string range "ABCDEFGHIJKLMNOPQRSTUVWXYZ" $i $i]
	grid [label $job(frame).0_$c -text $char -width 3] -column $col -row 0
    }
    for {set r 1} {$r <= $job(rows)} {incr r} {
	set j $r
	grid [label $job(frame).${r}_0 -text $r -width 3] -column 0 -row $r
	grid [checkbutton $job(frame).${r}_d -variable job(done$r)] -column 1 -row $r
	#bind $job(frame).${r}_d <Control-c> "DupRow %W"
	bind $job(frame).${r}_d <3> "DupRow %W"
	#grid [entry $job(frame).${r}_e -width 15 \
	#	  -textvariable job(raw$r)] -column 2 -row $r
	#bind $job(frame).${r}_e <Control-c> "DupRow %W"
	#bind $job(frame).${r}_e <3> "DupRow %W"
	#grid [entry $job(frame).${r}_f -width 15 \
	#	  -textvariable job(exp$r)] -column 3 -row $r
	#bind $job(frame).${r}_f <Control-c> "DupRow %W"
	#bind $job(frame).${r}_f <3> "DupRow %W"
	for {set c -1} {$c <= $job(cols)} {incr c} {
	    if {$c == -1} {
		set suffix ${r}_e
		set width 15
	    } elseif {$c == 0} {
		set suffix ${r}_f
		set width 15
	    } else {
		set suffix ${r}_$c
		set width 8
	    }
	    set col [expr {$c+4}]
	    if $job(edit) {
		grid [entry $job(frame).$suffix -width $width \
			  -textvariable job(val$suffix)] -column $col -row $r
		bind $job(frame).$suffix <Control-c> "DupRow %W"
		#puts "\n$suffix $job(val$suffix)"
	    } else {
		set val ?
		if {[regexp { *\$([A-Za-z0-9])+ *= *(.*)} \
			 $job(val$suffix) junk a b]} {
		    catch {set val [subst $b]}
		    catch {set val [expr $val]}
		    puts "$a = $val"
		    set $a $val
		} else {
		    #catch {set val [expr $val]}
		    #puts "val=$val"
		    catch {set val [subst $job(val$suffix)]}
		}
		set len [string length $val]
		if {$len < $width} {set len $width}
		grid [label $job(frame).$suffix -width $len -relief raised \
			  -text $val] -column $col -row $r
	    }
	}
    }
    ResizeWin
}

proc ResizeWin {} {
    global job
    # resize & show the scroll bars for the canvas
    update idletasks
    set bx $job(win)
    set bbox [grid bbox $bx.c.fr]
    set w [lindex $bbox 2]
    set h [lindex $bbox 3]
    $bx.c config -scrollregion $bbox -width $w -height $h
    update idletasks
    # show the scrolls when needed
    if {[lindex $bbox 3] > [winfo height $bx.c]} {
	grid $bx.y -sticky ns -column 2 -row 1
    } else {
	grid forget $bx.y 
    }
    if {[lindex $bbox 2] > [winfo width $bx.c]} {
	grid $bx.x -sticky ew -column 1 -row 2
    } else {
	grid forget $bx.x
    }
}

makeTop
makeWin
