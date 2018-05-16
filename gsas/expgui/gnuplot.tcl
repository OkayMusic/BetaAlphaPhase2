proc Graph2CSV {graph_name csvname  {initialComment 1}} {
    if { [catch {set fp [open $csvname w]}] } {
	if { [file isfile $csvname] } {
	    MyMessageBox -parent . -title "Cannot write to file" \
		-message  "Write access to $csvname is denied.  File may be opened by another program, or directory may be write protected.  Try closing programs, or changing your current working directory" \
	    -type OK -default ok
	} else {
	    MyMessageBox -parent . -title "No write access" \
		-message "This directory does not have write access, you much change your current working directory" \
		-type OK -default ok
	}
	return 1
    }
    set commas {}
    set element_list [$graph_name element show] 

    set heading "" 
    set num 0
    catch {unset data_list}
    set max 0
    foreach element_name $element_list {
        set element_cmd "$graph_name element cget $element_name"
        # get xy data for this element
        set data_list($num) [eval $element_cmd -data]
        #if there is no data, skip this set
        set pts [llength $data_list($num)]
        if {$pts > $max} {set max $pts}
        if {[llength $data_list($num)] == 0} continue
        incr num
	if {$heading != ""} {append heading ","}
	append heading  [$graph_name axis cget x -title]
	append heading ","
	append heading $element_name
    }
    #For Gnuplot exports, the column labels need to be commented out
    if {$initialComment} {
	puts $fp "#$heading"
    } else {
	puts $fp $heading
    }
    for {set i 0} {$i < $max} {incr i 2} {
        set line ""
        for {set n 0} {$n < $num} {incr n} {
        # get xy data for this element
            foreach {x y} [lrange $data_list($n) $i [expr {$i + 1}]] {}
            append line "$x,$y,"
        }
        puts $fp $line
    }
    close $fp
    return 0
}

proc Graph2Gnuplot {graph_name gplotname psname csvname "legendplace 1"} {
    if {[Graph2CSV $graph_name $csvname]} {return 1}
    if { [catch {set gplotfp [open $gplotname w]}] } {
	MyMessageBox -parent . -title "Cannot write to file" \
	    -message  "Write access to $gplotname is denied.  File may be opened by another program, or directory may be write protected.  Try closing programs, or changing your current working directory" \
	    -type OK -default ok
	return 1
    }
    puts $gplotfp "set datafile separator \",\"\n"
    puts $gplotfp "set terminal postscript"
    puts $gplotfp "set output \"$psname\""
    
    # use the title font size throughout
    set fontsize [lindex [$graph_name cget -font] 1]
    if {$fontsize != ""} {
        if {$fontsize < 0} {
            set fontsize ",[expr {-$fontsize}] "
        } else {
            set fontsize ",$fontsize "
        }
    }

    if {$::tcl_platform(platform) != "windows"} { 
	set font "\"Helvetica$fontsize\""
    } else { 
	set font "font \"Arial$fontsize\"" 
    }
    puts $gplotfp "set term postscript landscape color solid $font size 10.5in,7.5in enhanced\n"
    puts $gplotfp "set xtics border out \nset ytics border out"
    puts $gplotfp "set mxtics 5\nset mytics 5\n"
    
    #turns out that an opaque key is brand new in the gnuplot dev version 4.5.  This is what Windows ships with, but for now, unix systems will have to do without.  Too bad
    if {$::tcl_platform(platform) == "windows"} { puts $gplotfp "set key opaque" }
    if {$legendplace == 0 } { puts $gplotfp "set key out" }
    if {[$graph_name legend cget -hide]} {puts $gplotfp "set key off\n" }

    set title [$graph_name cget -title]
    if { $title != "" } {
	regsub -all "\"" $title "\\\"" thetitle
	puts $gplotfp "set title \"$thetitle\""
    }
	
    set xlab [$graph_name axis cget x -title]
    if {[string match -nocase $xlab "2theta"]} {set xlab "2{/Symbol q}"}
    puts $gplotfp "\nset xlabel \"$xlab\""
    puts $gplotfp "set ylabel \"[$graph_name axis cget y -title]\""
	
    puts $gplotfp "\nset origin -0.05,0.025"

    foreach {xmin xmax} [$graph_name xaxis limits] {}
    foreach {ymin ymax} [$graph_name yaxis limits] {}
    puts $gplotfp "set xrange \[ ${xmin}:${xmax} \]"
	
    set yoff [expr ($ymax-$ymin)*0.02]
    set yminauto [expr $ymin-$yoff]
    set ymaxauto [expr $ymax+$yoff]
	
    set line "set yrange \[";
    if {[$graph_name yaxis cget -min] == "" } { 
	append line "$yminauto:" 
    } else { 
	append line "$ymin:" 
    }
    if {[$graph_name yaxis cget -max] == "" } { 
	append line "$ymaxauto\]\n" 
    } else { 
	append line "$ymax\]\n" 
    }	
    puts $gplotfp $line

    puts $gplotfp "set style line 1 lt 1 lw 2" 
    # it would be nice to control this for each figure
    puts $gplotfp "set pointsize 1.75" 

    set plotline "plot "
    set i 0
    set element_list [$graph_name element show]

    set heading "" 
    foreach element_name $element_list {
        set element_cmd "$graph_name element cget $element_name"
        #if there is no data, skip this set
        if {[llength [eval $element_cmd -data]] == 0} continue
        if {$plotline != "plot "} { append plotline "\\\n   , " }

	# get line info from plot -- not currently used
	set lw [eval $element_cmd -linewidth]
	set symbol  [eval $element_cmd -symbol]
	set size  [eval $element_cmd -pixels]
	set dash  [eval $element_cmd -dashes]
	#puts "$element_name $symbol"
	if {$lw >= 1 && $symbol == "none"} {
	    append plotline "\"$csvname\" using [expr 2*$i+1]:[expr 2*$i+2] with lines ls 1 lc rgbcolor "
	} elseif {$lw >= 1 && $symbol != "none"}  {
	    # don't know how to control symbol type or size line by line
	    append plotline "\"$csvname\" using [expr 2*$i+1]:[expr 2*$i+2] with linespoints ls 1 lc rgbcolor "
	} else {
	    append plotline "\"$csvname\" using [expr 2*$i+1]:[expr 2*$i+2] with points ls 1 lc rgbcolor "	}
	# get color
	set linecolor [eval $element_cmd -color]
	# convert 16 bit color to 3x8 bit digit RGB value
	set str "#"
	foreach rgb [winfo rgb . $linecolor] {
	    append str [format "%02X" [expr {$rgb / 256}]]
	}
	append plotline {"} $str {"}

	append plotline " title \""
	set plotlbl [eval $element_cmd -label]
	#if {$plotlbl == ""} {set plotlbl $element_name}
	regsub -all "\"" [string trim $plotlbl] "\\\"" thetitle
	append plotline $thetitle;
	append plotline "\""
	incr i
    }

    # loop over markers
    foreach mrk [$graph_name marker names] {
	set type [$graph_name marker type $mrk]
	if {$type == "TextMarker"} {
	    set txt [$graph_name marker cget $mrk -text]
	    set angle [$graph_name marker cget $mrk -rotate]
	    set coords [$graph_name marker cget $mrk -coords]
	    set justify [$graph_name marker cget $mrk -justify]
	    set anchor [$graph_name marker cget $mrk -anchor]
	    set color [$graph_name marker cget $mrk -foreground]
	    # convert 16 bit color to 3x8 bit digit RGB value
	    set str "#"
	    foreach rgb [winfo rgb . $color] {
		append str [format "%02X" [expr {$rgb / 256}]]
	    }
	    # deal with text placement -- anchor/justify not quite mapped
	    set place "left"
	    if {$anchor == "center"} {
                set place "center"
            } elseif {[string first "w" $anchor]} {
                set place "right"
            }

	    # text rotation
	    set rot {}
	    if {$angle != 0.0 && $angle != ""} {
		set rot "rotate by $angle" 
	    }
	    # text location
	    foreach val $coords var {x1 y1} \
		min [list $xmin $ymin] max [list $xmax $ymax] {
		    if {$val == "+Inf"} {
			set $var $max
		    } elseif {$val == "-Inf"} {
			set $var $min
		    } else {
			set $var $val
		    }
		}
            if {$x1 < $xmin || $x1 > $xmax} {continue}
	    # replace newlines
	    regsub -all "\n" $txt {\n} txt
	    puts $gplotfp "set label \"$txt\" at first $x1,$y1 tc rgbcolor \"$str\" $place $rot" 
	} elseif {$type == "LineMarker"} {
	    set coords [$graph_name marker cget $mrk -coords]
	    #set lw [$graph_name marker cget $mrk -linewidth]
	    #set dashes [$graph_name marker cget $mrk -dashes]
	    set linecolor [$graph_name marker cget $mrk -outline]
	    # convert 16 bit color to 3x8 bit digit RGB value
	    set str "#"
	    foreach rgb [winfo rgb . $linecolor] {
		append str [format "%02X" [expr {$rgb / 256}]]
	    }
	    foreach val $coords var {x1 y1 x2 y2} \
		min [list $xmin $ymin $xmin $ymin] max [list $xmax $ymax $xmax $ymax] {
		    if {$val == "+Inf"} {
			set $var $max
		    } elseif {$val == "-Inf"} {
			set $var $min
		    } else {
			set $var $val
		    }
		}
            if {$x1 < $xmin || $x2 > $xmax} {continue}
	    puts $gplotfp "set arrow from first $x1,$y1 to first $x2,$y2 nohead lc rgbcolor \"$str\"" 
	} else {
	    puts "unable to process marker $mrk of type $type"
	}
    }
    # last item, do plot command
    puts $gplotfp $plotline
    close $gplotfp
    return 0
}
set gnuplotexport "loaded"