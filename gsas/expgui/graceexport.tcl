# tcl code that attempts to duplicate a BLT graph in XMGRACE
# (see http://plasma-gate.weizmann.ac.il/Grace/)
# this was written by John Cowgill and later hacked by Brian Toby
# to deal with un-recognized colors, export markers, warn on old BLT versions
# & brace expressions (seems faster?)

proc output_grace { graph_name "title {}" "subtitle {}"} {
    global blt_version
    # trap pre 2.4 BLT versions, where options have different names
    # but beware, really old versions of blt don't have a version number
    if [catch {set blt_version}] {set blt_version 0}
    if {$blt_version <= 2.3 || $blt_version == 8.0} {
	# version 8.0 is ~same as 2.3
	tk_dialog .tooOld "Old BLT" \
		"Sorry, you are using a version of BLT that is too old for this routine" \
		"" 0 OK
	return
    }
    set element_count 0

    # define translation tables
    array set grace_colormap {
	black 1 red 2 green 3 blue 4 yellow 5 brown 6 gray 7 purple 8 \
		cyan 9 magenta 10 orange 11
    }
    array set grace_symbols {
	none 0 circle 1 square 2 diamond 3 triangle 4 arrow 6 plus 8 splus 8 \
		cross 9 scross 9
    }
    
    # general header stuff
    set output_string "# Grace project file\n#\n@version 50010\n"
    
    # loop through each element in the graph but reverse order, so that
    # elements on the bottom are done first
    set element_list [$graph_name element names] 
    set index [llength $element_list]
    while {[incr index -1] >= 0} {
	set element_name [lindex $element_list $index]
	set element_cmd "$graph_name element cget $element_name"
	
	# get xy data for this element
	set data_list [eval $element_cmd -data]
	
	#if there is no data, skip this set as Grace does not like null sets
	if {[llength $data_list] == 0} continue

	# write the legend name for this element
	append output_string "@s$element_count legend \"" \
		[eval $element_cmd -label] "\"\n"

	# get the color and symbol type for this element
	set color_data 1
	catch {
	    set color_data $grace_colormap([eval $element_cmd -color])
	}
	append output_string "@s$element_count line color $color_data\n" \
		"@s$element_count errorbar color $color_data\n" \
		"@s$element_count symbol color $color_data\n"
	set symbol_data 1
	catch {
	    set symbol_data $grace_symbols([eval $element_cmd -symbol])
	}
	append output_string "@s$element_count symbol $symbol_data\n"
	# fill defaults to symbol color
	catch {
	    set color_data $grace_colormap([eval $element_cmd -fill])
	}
	append output_string "@s$element_count symbol fill color $color_data\n"

	# get element symbol/line width/size settings
	set size_data [eval $element_cmd -linewidth]
	append output_string \
		"@s$element_count linewidth $size_data\n" \
		"@s$element_count symbol linewidth $size_data\n"
	# turn off the line, if the width is zero
	if {$size_data == 0} {
	    append output_string \
		    "@s$element_count line type 0\n" 
	}

	# approximate the BLT size in grace
	set size_data 1
	catch {
	    set size_data [expr {[eval $element_cmd -pixels]/15.0}]
	}
	append output_string "@s$element_count symbol size $size_data\n" \
		"@s$element_count symbol fill pattern 1\n"

	# check if this element is hidden or not
	set hidden_data [eval $element_cmd -hide]
	if {[string compare "1" $hidden_data] == 0} {
	    append output_string "@s$element_count hidden true\n"
	} else {
	    append output_string "@s$element_count hidden false\n"
	}

	# check to see if there is -edata defined for this element
	# should work for versions of BLT that do not support -edata
	if {[catch \
		"$graph_name element configure $element_name -edata" edata_list] || \
		[string compare "" [lindex $edata_list 4]] == 0} {
	    # no error data present, just use xy data
	    append output_string "@s$element_count errorbar off\n@type xy\n"
	    set max [expr {[llength $data_list] / 2}]
	    for {set i 0} {$i < $max} {incr i} {
		append output_string [lindex $data_list [expr {2*$i}]] " " \
			[lindex $data_list [expr {2*$i + 1}]] "\n"
	    }
	} else {
	    # error data present, check for error vector
	    set edata_list [lindex $edata_list 4]
	    if {[llength $edata_list] == 1} {
		# found a vector name instead of a list, so get the values
		set edata_list [$edata_list range 0 end]
	    }
	    # get xy data for this element
	    set data_list [eval $element_cmd -data]
	    set max [expr {[llength $data_list] / 2}]
	    if {[llength $edata_list] >= [expr {[llength $data_list] * 2}]} {
		append output_string \
			"@s$element_count errorbar on\n@type xydxdxdydy\n"
		for {set i 0} {$i < $max} {incr i} {
		    append output_string [lindex $data_list  [expr {2*$i + 0}]] " " \
			    [lindex $data_list  [expr {2*$i + 1}]] " " \
			    [lindex $edata_list [expr {4*$i + 2}]] " " \
			    [lindex $edata_list [expr {4*$i + 3}]] " " \
			    [lindex $edata_list [expr {4*$i + 0}]] " " \
			    [lindex $edata_list [expr {4*$i + 1}]] "\n"
		}
	    } else {
		append output_string \
			"@s$element_count errorbar on\n@type xydy\n"
		for {set i 0} {$i < $max} {incr i} {
		    append output_string [lindex $data_list [expr {2*$i}]] " " \
			    [lindex $data_list [expr {2*$i + 1}]] " " \
			    [lindex $edata_list $i] "\n"
		}
	    }
	}
	append output_string "&\n"
	incr element_count
    }

    # general graph header stuff
    append output_string "@with g0\n"
    
    # get x and y axis limits
    foreach v {x y} {
	set limit_data [$graph_name ${v}axis limits]
	set ${v}min [lindex $limit_data 0]
	set ${v}max [lindex $limit_data 1]
	append output_string "@world ${v}min [set ${v}min]\n"
	append output_string "@world ${v}max [set ${v}max]\n"
    }
    
    # get legend information from graph
    set legend_data [lindex [$graph_name legend configure -hide] 4]
    if {[string compare "1" $legend_data] == 0} {
	append output_string "@legend off\n"
    } else {
	append output_string "@legend on\n"
    }

    # get title of graph
    if {$title == ""} {
	set title [$graph_name cget -title]
    }
    append output_string \
	    "@title \"$title\"\n" \
	    "@subtitle \"$subtitle\"\n"
    
    # get labels for x and y axes
    foreach z {x y} {
	set axistitle [$graph_name ${z}axis cget -title]
	set ticklist [$graph_name ${z}axis cget -majorticks]
	set tickspace [expr {[lindex $ticklist 1] - [lindex $ticklist 0]}]
	set minorticks [expr {$tickspace / (1 + \
		[llength [$graph_name ${z}axis cget -minorticks]])}]
	append output_string \
		"@${z}axis label \"$axistitle\"\n" \
		"@${z}axis tick major $tickspace\n" \
		"@${z}axis tick minor $minorticks\n"
    }
    
    # check for log scale on either axis
    set log_data [lindex [$graph_name xaxis configure -logscale] 4]
    if {[string compare "1" $log_data] == 0} {
	append output_string "@xaxes scale Logarithmic\n"
    }
    set log_data [lindex [$graph_name yaxis configure -logscale] 4]
    if {[string compare "1" $log_data] == 0} {
	append output_string "@yaxes scale Logarithmic\n"
    }

    # now get graph markers
    foreach m [$graph_name marker names] {
	if {[$graph_name marker type $m] == "line" || \
		[$graph_name marker type $m] == "LineMarker"} {
	    set coords [$graph_name marker cget $m -coords]
	    if {[$graph_name marker cget $m -dashes] == {}} {
		set linestyle 1
	    } else {
		set linestyle 3
	    }
	    set color_data 1
	    catch {
		set color_data $grace_colormap([$graph_name marker cget $m -outline])
	    }

	    if {[lindex $coords 0] < $xmin || [lindex $coords 0] > $xmax} \
		    continue 
	    regsub -all -- "\\+Inf" $coords $ymax coords
	    regsub -all -- "-Inf" $coords $ymin coords
	    while {[llength $coords] >= 4} {
		set c [lindex $coords 0]
		foreach c1 [lrange $coords 1 3] {append c ", $c1"}
		append output_string \
			"@with line\n" \
			"@ line on\n@ line loctype world\n@ line g0\n" \
			"@ line $c\n" \
			"@ line linewidth 1.0\n@ line linestyle $linestyle\n" \
			"@ line color $color_data\n@ line arrow 0\n" \
			"@line def\n"
		set coords [lrange $coords 2 end]
	    }
	} elseif {[$graph_name marker type $m] == "text" || \
		      [$graph_name marker type $m] == "TextMarker"} {
	    set coords [$graph_name marker cget $m -coords]
	    # leave a 5% margin for markers on plot limits
	    set aymax [expr {$ymax - 0.05 * ($ymax - $ymin)}]
	    set aymin [expr {$ymin + 0.05 * ($ymax - $ymin)}]
	    regsub -all -- "\\+Inf" $coords $aymax coords
	    regsub -all -- "-Inf" $coords $aymin coords	
	    set c "[lindex $coords 0], [lindex $coords 1]"
	    set text [$graph_name marker cget $m -text]
	    set just [$graph_name marker cget $m -anchor]
	    if {[string range $just 0 0] == "c"} {
		set center 2
	    } elseif {[string range $just 0 0] == "n"} {
		set center 10
	    } elseif {[string range $just 0 0] == "e"} {
		# is this correct? 
		set center 1
	    } else {
		set center 0
	    }
	    set color_data 1
	    catch {
		set color_data $grace_colormap([$graph_name marker cget $m -fg])
	    }
	    set angle [$graph_name marker cget $m -rotate]

	    append output_string \
		    "@with string\n" \
		    "@ string on\n@ string loctype world\n@ string g0\n" \
		    "@ string color $color_data\n@ string rot $angle\n" \
		    "@ string just $center\n" \
		    "@ string $c\n@ string def \"$text\"\n"
	}
    }    
    return $output_string
}
