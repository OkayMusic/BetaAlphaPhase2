#----------------------------------------------------------------------
#---  initial values for variables
#----------------------------------------------------------------------
global CIF
# Maximum CIF size is set by this variable:
set CIF(maxvalues) 100000
# don't show overridden definitions by default
set CIF(ShowDictDups) 0
set CIF(editmode) 0
# configuration tests
set OK 1
if {$::tcl_version < 8.2} {
    # "Sorry, the CIF Browser requires version 8.2 or later of the Tcl/Tk package. This is $::tcl_version"
    set OK 0
}

if {[catch {
    source [file join $::expgui(scriptdir) browsecif.tcl]
}]} {set OK 0}

if {$OK} {
    proc ReadCIF4GSAS {parent} {
	global command CIF
	set CIF(parent) $parent
	# load the browser, etc but this does not import any data 
	# data import is done in ReadCIFWriteFXYE
	if {$::tcl_platform(platform) == "windows"} {
	    set typelist {
		{"CIF data" ".CIF"}
		{"IUCr Rietveld CIF" ".RTV"}
	    }
	} else {
	    set typelist {
		{"CIF data" ".cif"}
		{"IUCr Rietveld CIF" ".rtv"}
		{"CIF data" ".CIF"}
		{"IUCr Rietveld CIF" ".RTV"}
		{"CIF data" ".Cif"}
	    }
	}
	set filename [tk_getOpenFile \
			  -title "Select CIF to import from\nor press Cancel." \
			  -parent $parent -defaultextension EXP \
			  -filetypes $typelist]
	if {$filename == ""} {return}
	set CIF(CIFfile) $filename
	makeReadCIFwindow
	CIFOpenBrowser $CIF(BrowserWin)
	ReadCIFfile $filename
	CIFBrowser $CIF(txt) $CIF(blocklist) 0 $CIF(BrowserWin)
	ReadCIFScan4GSAS $filename
	tkwait window $CIF(parent).cif
	validaterawfile $parent $::newhist(rawfile)
    }



    # create the windows used by the CIF parser/browser
    proc makeReadCIFwindow {} {
	global CIF
	# create window/text widget for CIF file
	catch {destroy [set filew $CIF(parent).cif]}
	toplevel $filew
	wm title $filew "CIF file contents"
	#wm protocol $filew WM_DELETE_WINDOW exit
	set CIF(txt) $filew.t
	set CIF(txtscroll) $filew.s
	grid [text $CIF(txt) -height 10 -width 80 -yscrollcommand "$CIF(txtscroll) set" -wrap none] \
	    -column 0 -row 0 -sticky news
	grid [scrollbar $CIF(txtscroll) -command "$CIF(txt) yview"] -column 1 -row 0 -sticky ns
	grid columnconfig $filew 0 -weight 1
	grid rowconfig $filew 0 -weight 1

	# create window/text widget for the CIF definition
	catch {destroy [set defw $filew.def]}
	toplevel $defw
	wm title $defw "CIF definitions"
	wm protocol $defw WM_DELETE_WINDOW exit
	set CIF(defBox) $defw.t
	grid [text $CIF(defBox) -width 45 -height 18 -xscrollcommand "$defw.x set" \
		  -yscrollcommand "$defw.y set" -wrap word] -column 0 -row 0 -sticky news
	grid [scrollbar $defw.y -command "$CIF(defBox) yview"] -column 1 -row 0 -sticky ns
	grid [scrollbar $defw.x -command "$CIF(defBox) xview" \
		  -orient horizontal] -column 0 -row 1 -sticky ew
	grid columnconfig $defw 0 -weight 1
	grid rowconfig $defw 0 -weight 1
	# hide it
	wm withdraw $defw

	# make window for the CIF browser
	set CIF(BrowserWin) $filew.browser
	catch {destroy $CIF(BrowserWin)}
	toplevel $CIF(BrowserWin) 
	wm title $CIF(BrowserWin) "CIF Browser"
	grid [frame $CIF(BrowserWin).box] -column 0 -row 2 -sticky ew
	grid [button $CIF(BrowserWin).box.c -text Close] -column 0 -row 1 -sticky w
	grid columnconfig $CIF(BrowserWin).box 0 -weight 1
	grid columnconfig $CIF(BrowserWin).box 2 -weight 1
	wm withdraw $CIF(BrowserWin)
	
	# make a window to select a block
	set CIF(BlockChooser) $filew.choose
	catch {destroy $CIF(BlockChooser)}
	toplevel $CIF(BlockChooser)
	grid [label $CIF(BlockChooser).top -text "Select a block to import from"] \
	    -column 1 -row 0  -sticky nsew 
	grid columnconf $CIF(BlockChooser) 1 -weight 1
	grid [canvas $CIF(BlockChooser).canvas \
		  -scrollregion {0 0 5000 1000} -width 400 -height 250 \
		  -xscrollcommand "$CIF(BlockChooser).xscroll set" \
		  -yscrollcommand "$CIF(BlockChooser).yscroll set"] \
	    -column 1 -row 1  -sticky nsew 
	grid [scrollbar $CIF(BlockChooser).xscroll -orient horizontal \
		  -command "$CIF(BlockChooser).canvas xview"] \
	    -row 2 -column 1 -sticky ew
	grid [scrollbar $CIF(BlockChooser).yscroll \
		  -command "$CIF(BlockChooser).canvas yview"] \
	    -row 1 -column 2 -sticky ns
	grid columnconfigure $CIF(BlockChooser) 1 -weight 0
	grid rowconfigure $CIF(BlockChooser) 1 -weight 1
	grid rowconfigure $CIF(BlockChooser) 2 -pad 5
	set blockbox [frame $CIF(BlockChooser).canvas.fr]
	$CIF(BlockChooser).canvas create window 0 0 -anchor nw -window $blockbox
	
	grid [frame $CIF(BlockChooser).box] -column 1 -columnspan 3 -row 3 -sticky ew
	#grid [button $CIF(BlockChooser).box.d -text "Show CIF Definitions" \
	    #-command "ShowDefWindow $CIF(BlockChooser).box.d $defw"] \
	    #-column 2 -row 1 -sticky w
	grid [button $CIF(BlockChooser).box.q -text Quit \
		  -command "destroy [winfo parent $CIF(BlockChooser)]" \
		 ] -column 1 -row 1 -sticky w
	grid [button $CIF(BlockChooser).box.c -text "Show CIF browser" \
		  -command "ShowCIFWindow $CIF(BlockChooser).box.c $CIF(BrowserWin) browser"] \
	    -column 6 -row 1 -sticky w
	grid [button $CIF(BlockChooser).box.d -text "Show CIF contents" \
		  -command "ShowCIFWindow $CIF(BlockChooser).box.d [winfo parent $CIF(txt)] contents"] \
	    -column 7 -row 1 -sticky w

	#wm protocol $CIF(BlockChooser) WM_DELETE_WINDOW exit
	grid columnconfig $CIF(BlockChooser).box 3 -weight 1

	wm withdraw $CIF(BlockChooser)
	wm protocol $CIF(BrowserWin) WM_DELETE_WINDOW \
	    "ShowCIFWindow $CIF(BlockChooser).box.c $CIF(BrowserWin) browser"
	$CIF(BrowserWin).box.c config -command "ShowCIFWindow $CIF(BlockChooser).box.c $CIF(BrowserWin) browser"
	wm protocol [winfo parent $CIF(txt)] WM_DELETE_WINDOW \
	    "ShowCIFWindow $CIF(BlockChooser).box.d [winfo parent $CIF(txt)] contents"

	update
	# center the CIF text window
	wm withdraw $filew
	set x [expr {[winfo screenwidth $filew]/2 - [winfo reqwidth $filew]/2}]
	set y [expr {[winfo screenheight $filew]/2 - [winfo reqheight $filew]/2}]
	wm geometry $filew +$x+$y
	wm deiconify $filew
	update
    }

    proc ReadCIFfile {startfile} {
	global CIF
	set filew [winfo toplevel $CIF(txt)]

	# quit command needs some work
	set CIF(QuitParse) 0
	
	pleasewait "while loading CIF file" CIF(status) $filew {Quit "set CIF(QuitParse) 1"}
	update idletasks

	# destroy the text box as that is faster than deleting the contents
	destroy $CIF(txt) 
	grid [text $CIF(txt) -height 10 -width 80 -yscrollcommand "$CIF(txtscroll) set"] \
	    -column 0 -row 0 -sticky news

	set CIF(maxblocks) [ParseCIF $CIF(txt) $startfile]


	# did we quit out?
	if {$CIF(QuitParse)} {
	    donewait
	    destroy $filew
	} else {
	    set CIF(blocklist) {}
	    if {[array names block0] != ""} {
		set i 0
	    } else {
		set i 1
	    }
	    for {} {$i <= $CIF(maxblocks)} {incr i} {
		lappend CIF(blocklist) $i
		#    if {![catch {set block${i}(errors)} errmsg]} {
		#	puts "Block $i ([set block${i}(data_)]) errors:"
		#	puts "[set block${i}(errors)]"
		#    }
	    }
	    donewait
	}
    }

    # classify the diffraction data in block
    #   if checkonly == 0 (default) the data are copied into arrays xdata, ydata...
    #   if checkonly == 1 the arrays xdata, ydata are defined but are empty
    proc readCIFclassify4GSAS {block "checkonly 0"} {
	global CIF $block plot
	foreach array {xdata xesd ydata yesd ymoddata} {
	    global $array
	    catch {unset $array}
	}
	
	set xlist {
	    {_pd_meas_2theta_range_min _pd_meas_2theta_range_max _pd_meas_2theta_range_inc}
	    {_pd_proc_2theta_range_min _pd_proc_2theta_range_max _pd_proc_2theta_range_inc}
	    _pd_meas_2theta_scan
	    _pd_meas_time_of_flight
	    _pd_proc_2theta_corrected
	    _pd_proc_d_spacing
	    _pd_proc_energy_incident
	    _pd_proc_energy_detection
	    _pd_proc_recip_len_Q
	    _pd_proc_wavelength
	}

	set ylist {
	    _pd_meas_counts_total
	    _pd_meas_intensity_total
	    _pd_proc_intensity_net
	    _pd_proc_intensity_total
	}
	# removed since does not make sense for GSAS input
	#	_pd_meas_counts_background
	#	_pd_proc_intensity_bkg_calc
	#	_pd_proc_intensity_bkg_fix
	#	_pd_meas_intensity_background
	#	_pd_meas_intensity_container
	#	_pd_meas_counts_container
	#	_pd_calc_intensity_net
	#	_pd_calc_intensity_total
	
	set ymod {
	    _pd_meas_step_count_time
	    _pd_meas_counts_monitor
	    _pd_meas_intensity_monitor
	    _pd_proc_intensity_norm
	    _pd_proc_intensity_incident
	    _pd_proc_ls_weight
	}
	
	foreach item $xlist {
	    if {[llength $item] == 1} {
		set marks {}
		catch {
		    set marks [set ${block}($item)]
		}
		if {[llength $marks] > 1} {
		    if {$checkonly} {
			set xdata($item) {}
			continue
		    }
		    set l {}
		    set esdlist {}
		    foreach m $marks {
			set val [StripQuotes [$CIF(txt) get $m.l $m.r]]
			foreach {val esd} [ParseSU $val] {}
			lappend l $val
			if {$esd != ""} {lappend esdlist $esd}
		    }
		    set xdata($item) $l
		    if {[llength $l] == [llength $esdlist]} {
			set xesd($item) $esdlist
		    }
		}
	    } else {
		catch {
		    foreach i $item var {min max step} {
			set m [set ${block}($i)]
			set $var [StripQuotes [$CIF(txt) get $m.l $m.r]]
		    }
		    set l {}
		    set i -1
		    regsub _min [lindex $item 0] _ itm
		    if {$checkonly} {
			set xdata($itm) {}
			continue
		    }
		    if {$step > 0.0} {
			while {[set T [expr {$min+([incr i]*$step)}]] <= $max+$step/100.} {
			    lappend l $T
			}
		    } else {
			while {[set T [expr {$min+([incr i]*$step)}]] >= $max+$step/100.} {
			    lappend l $T
			}
		    }
		    set xdata($itm) $l
		}
	    }
	}
	# process the wavelength, if present
	set item _diffrn_radiation_wavelength
	set marks {}
	catch {
	    set marks [set ${block}(_diffrn_radiation_wavelength)]
	}
	set l {}
	foreach m $marks {
	    set val [StripQuotes [$CIF(txt) get $m.l $m.r]]
	    foreach {val esd} [ParseSU $val] {}
	    lappend l $val
	}
	if {$l != ""} {set xdata(_diffrn_radiation_wavelength) $l}

	foreach item $ylist {
	    set marks {}
	    catch {
		set marks [set ${block}($item)]
	    }
	    if {[llength $marks] > 1} {
		if {$checkonly} {
		    set ydata($item) {}
		    continue
		}
		set l {}
		set esdlist {}
		foreach m $marks {
		    set val [StripQuotes [$CIF(txt) get $m.l $m.r]]
		    foreach {val esd} [ParseSU $val] {}
		    lappend l $val
		    if {$esd != ""} {lappend esdlist $esd}
		}
		set ydata($item) $l
		if {[llength $l] == [llength $esdlist]} {
		    set yesd($item) $esdlist
		}
	    }
	}
	
	if {$checkonly} {return}

	foreach item $ymod {
	    set marks {}
	    catch {
		set marks [set ${block}($item)]
	    }
	    if {[llength $marks] > 1} {
		set l {}
		foreach m $marks {
		    lappend l [StripQuotes [$CIF(txt) get $m.l $m.r]]
		}
		set ymoddata($item) $l
	    }
	}
    }

    proc OpenOneNode {block} {
	global CIF plot
	catch {
	    foreach n $plot(blocklist) {
		$CIF(tree) closetree $n
	    }
	    $CIF(tree) itemconfigure $block -open 1
	}
    }

    proc ReadCIFSelectBlock {block} {
	OpenOneNode $block
	global CIF
	pleasewait "interpreting contents of $block" "" $CIF(BlockChooser)

	readCIFclassify4GSAS $block
	donewait
	MakeCIFReadImportBox
	set CIF(loaded_block) $block
	return {}
    }

    # show or hide the CIF browser window
    proc ShowCIFWindow {button window txt} {
	if {[lindex [$button cget -text] 0] == "Show"} {
	    $button config -text "Hide CIF $txt"
	    wm deiconify $window
	} else {
	    $button config -text "Show CIF $txt"
	    wm withdraw $window
	}
    }

    proc ReadCIFScan4GSAS {filename} {
	global plot xdata ydata CIF

	set blcksel $CIF(BlockChooser) 
	set BrowserWin $CIF(BrowserWin)
	wm title $blcksel "pdCIF import: file [file tail $filename]"
	wm title $BrowserWin "pdCIF import: file $filename"
	set blockbox $blcksel.canvas.fr
	eval destroy [winfo children $blcksel.canvas.fr]
	set row 0
	set col 0
	set i 0
	set readable 0; # number of blocks with powder data
	foreach j $CIF(blocklist) {
	    set n block$j
	    global $n
	    incr i
	    set blockname [set ${n}(data_)]
	    readCIFclassify4GSAS $n 1
	    if {[llength [array names xdata]] > 0 && \
		    [llength [array names ydata]]> 0} {
		set state normal
		incr readable
	    } else {
		set state disabled
	    }
	    grid [radiobutton $blockbox.$i -text "$n $blockname" \
		      -value $n -variable CIF(SelectedBlock) \
		      -state $state -command "ReadCIFSelectBlock $n"] \
		-sticky w -row [incr row] -column $col
	    if {$row > 15} {
		incr col
		set row 0
	    }
	}
	set  CIF(SelectedBlock) ""
	#    Disableplotting 1
	update idletasks
	set sizes [grid bbox $blockbox]
	$blcksel.canvas config -scrollregion $sizes -width 400 -height 250
	if {[lindex $sizes 3] < [$blcksel.canvas cget -height]} {
	    grid forget $blcksel.yscroll
	    $blcksel.canvas config -height [lindex $sizes 3]
	} else {
	    grid $blcksel.yscroll -row 1 -column 2 -sticky ns
	}
	if {[lindex $sizes 2] < [$blcksel.canvas cget -width]} {
	    grid forget $blcksel.xscroll
	    #$blcksel.canvas config -width [lindex $sizes 2]
	} else {
	    grid $blcksel.xscroll -row 2 -column 1 -sticky ew
	}
	update idletasks
	# pull the file window; post the chooser
	wm withdraw [winfo parent $CIF(txt)]
	wm deiconify $blcksel
	if {$readable == 0} {
	    set ans [MyMessageBox -parent $blcksel -title "No Data" \
			 -message "File \"$filename\" does not contain any powder diffraction data. Nothing to plot." \
			 -icon warning -type {Continue "Browse CIF"} -default "continue"]
	    if {$ans == "browse cif"} {ShowCIFWindow $CIF(BlockChooser).box.c $CIF(BrowserWin) browser}
	}
	if {[llength $CIF(blocklist)] == 1} {
	    set CIF(SelectedBlock) $n
	    ReadCIFSelectBlock $n
	} 
    }

    # make a selection window to choose data items
    proc MakeCIFReadImportBox {} {
	global xdata ydata ymoddata yesd
	global CIF
	set blcksel $CIF(BlockChooser) 
	set blockbox $blcksel.canvas.fr
	set box $CIF(BlockChooser).canvas.fr
	eval destroy [winfo children $box]
	$CIF(BlockChooser).top config -text "Select CIF data items to extract"
	catch {destroy $CIF(BlockChooser).box.i};     # destroy old button during debug
	grid [button $CIF(BlockChooser).box.i -text Import \
		  -command ReadCIFWriteFXYE \
		 ] -column 0 -row 1 -sticky w

	# variables for possible use on xaxis
	global xaxisvars
	array set xaxisvars {
	    _pd_meas_2theta_range_     2Theta
	    _pd_proc_2theta_range_     "corrected 2Theta"
	    _pd_meas_2theta_scan       2Theta
	    _pd_meas_time_of_flight   "TOF, ms"
	    _pd_proc_2theta_corrected "corrected 2Theta"
	    _pd_proc_energy_incident  "energy, eV"
	    _pd_proc_wavelength       "wavelength, A"
	    _pd_proc_d_spacing        "d-space, A"
	    _pd_proc_recip_len_Q      "Q, 1/A"
	    _pd_meas_position         "linear position, mm"
	}
	array set yvars {
	    _pd_meas_counts_total     Counts
	    _pd_meas_intensity_total  Intensity
	    _pd_proc_intensity_net    "Corrected Intensity"
	    _pd_proc_intensity_total  "Corrected Intensity"
	    _pd_meas_counts_background     Background
	    _pd_meas_counts_container      Container
	    _pd_meas_intensity_background  Background
	    _pd_meas_intensity_container   Container
	    _pd_proc_intensity_bkg_calc    "Fitted background"
	    _pd_proc_intensity_bkg_fix     "Fixed background"
	    _pd_calc_intensity_net         "Corrected Intensity"
	    _pd_calc_intensity_total       "Computed Intensity"
	}

	# generate a list of numbers of data points
	set nl {}
	foreach v [array names xdata] {
	    set len [llength $xdata($v)]
	    if {[lsearch $nl $len] == -1} {lappend nl $len}
	}
	set nl [lsort -integer $nl]

	set j 0
	set row 0
	set CIF(YaxisList) {}
	foreach n $nl {
	    if {$n == 1} continue
	    incr j

	    # what data items are available with the current number of points?
	    set xlist {}
	    foreach item [array names xdata] {
		if {$n != [llength $xdata($item)]} continue
		if {[lsearch [array names xaxisvars] $item] != -1} {
		    lappend xlist $item
		}
	    }
	    #if {$xlist == ""} continue

	    set ylist {}
	    foreach item [array names ydata] {
		if {$n != [llength $ydata($item)]} continue
		if {[lsearch [array names yvars] $item] != -1} {
		    lappend ylist $item
		}
	    }
	    #if {$ylist == ""} continue

	    #set yesdlist {}
	    #foreach item [array names yesd] {
	    #    if {$n != [llength $yesd($item)]} continue
	    #    if {[lsearch [array names yesdvars] $item] != -1} {
	    #	lappend yesdlist $item
	    #    }
	    #}
	    grid [frame $box.$j -bd 2 -relief groove] \
		-column 1 -row [incr row] -sticky ew
	    grid [label $box.$j.t -text "Set $j: $n points" -anchor center] \
		-column 1 -row 0 -columnspan 3 -sticky ew
	    set r 2
	    set xbuttonlist {}
	    set ybuttonlist {}
	    foreach x $xlist {
		set txt $x
		catch {append txt \n ($xaxisvars($x))}
		grid [radiobutton $box.$j.x$r -text $txt -value $x -justify left \
			  -variable CIF(xaxisvar)] \
		    -column 1 -row [incr r] -sticky w
		lappend xbuttonlist $x
	    }
	    # add some easy to generate x values
	    set wavelengths 0 
	    catch {set wavelengths [llength $xdata(_diffrn_radiation_wavelength)]}
	    if {[lsearch $xlist _pd_proc_recip_len_Q] == -1} {
		if {[lsearch $xlist _pd_proc_d_spacing] != -1} {
		    # conversion from d-space is easy
		    grid [radiobutton $box.$j.x$r \
			      -text "Q (1/A) from\n_pd_proc_d_spacing" \
			      -value "Q _pd_proc_d_spacing" -justify left \
			      -variable CIF(xaxisvar)] \
			-column 1 -row [incr r] -sticky w
		    lappend xbuttonlist "Q _pd_proc_d_spacing"
		} elseif {$wavelengths == 1} {
		    # conversion from 2theta is easy, too
		    foreach item {
			_pd_proc_2theta_corrected
			_pd_proc_2theta_range_
			_pd_meas_2theta_range_
			_pd_meas_2theta_scan
		    } {
			if {[lsearch $xlist $item] != -1} {
			    grid [radiobutton $box.$j.x$r -text "Q (1/A) from\n$item" \
				      -value "Q $item" -justify left \
				      -variable CIF(xaxisvar)] \
				-column 1 -row [incr r] -sticky w
			    lappend xbuttonlist $
			    break
			}
		    }
		}
	    }
	    if {[lsearch $xlist _pd_proc_d_spacing] == -1} {
		if {[lsearch $xlist _pd_proc_recip_len_Q] != -1} {
		    grid [radiobutton $box.$j.x$r \
			      -text "D-space (A) from\n_pd_proc_recip_len_Q"\
			      -value "d-space _pd_proc_recip_len_Q"  \
			      -justify left -variable CIF(xaxisvar)] \
			-column 1 -row [incr r] -sticky w
		    lappend xbuttonlist "d-space _pd_proc_recip_len_Q"
		    $xaxis add radiobutton -variable plot(xaxis) \
			-value  \
			-label 
		} elseif {$wavelengths > 0} {
		    # conversion from 2theta is easy, too
		    foreach item {
			_pd_proc_2theta_corrected
			_pd_proc_2theta_range_
			_pd_meas_2theta_range_
			_pd_meas_2theta_scan
		    } {
			if {[lsearch $xlist $item] != -1} {
			    grid [radiobutton $box.$j.x$r -text "D-space (A) from\n$item" \
				      -value "d-space $item" -justify left \
				      -variable CIF(xaxisvar)] \
				-column 1 -row [incr r] -sticky w
			    lappend xbuttonlist "d-space $item"
			    break
			}
		    }
		}
	    }
	    if {[llength $xbuttonlist] == 1} {
		set CIF(xaxisvar) $xbuttonlist
	    }

	    set r 2
	    foreach y $ylist {
		set txt $y
		catch {append txt \n ($yvars($y))}
		grid [checkbutton $box.$j.y$r -text $txt -justify left \
			  -variable CIF(yaxis_$y)] \
		    -column 2 -row [incr r] -sticky w
		lappend CIF(YaxisList) $y
		lappend ybuttonlist CIF(yaxis_$y)
	    }
	    if {[llength $ybuttonlist] == 1} {
		set $ybuttonlist 1
	    }
	    grid columnconfigure $box.$j 1 -minsize 248
	    grid columnconfigure $box.$j 2 -minsize 248
	}
	update idletasks
	set sizes [grid bbox $blockbox]
	$blcksel.canvas config -scrollregion $sizes -width 510 -height 250
	if {[lindex $sizes 3] < [$blcksel.canvas cget -height]} {
	    grid forget $blcksel.yscroll
	    $blcksel.canvas config -height [lindex $sizes 3]
	} else {
	    grid $blcksel.yscroll -row 1 -column 2 -sticky ns
	}
	if {[lindex $sizes 2] < [$blcksel.canvas cget -width]} {
	    grid forget $blcksel.xscroll
	    #$blcksel.canvas config -width [lindex $sizes 2]
	} else {
	    grid $blcksel.xscroll -row 2 -column 1 -sticky ew
	}
	# this appears to be needed by OSX
	update
	wm geom $blcksel [winfo reqwidth $blcksel]x[winfo reqheight $blcksel]
	# center the window
	set w $CIF(BlockChooser)
	wm withdraw $w
	update idletasks
	# get the parent window of the parent window 
	set wpt [winfo toplevel [winfo parent $w]]
	set wpt [winfo toplevel [winfo parent $wpt]]
	# center the new window in the middle of the parent's parent
	set x [expr [winfo x $wpt] + [winfo width $wpt]/2 - \
		[winfo reqwidth $w]/2 - [winfo vrootx $wpt]]
	if {$x < 0} {set x 0}
	set xborder 10
	if {$x+[winfo reqwidth $w] +$xborder > [winfo screenwidth $w]} {
	    incr x [expr [winfo screenwidth $w] - \
		    ($x+[winfo reqwidth $w] + $xborder)]
	}
	set y [expr [winfo y $wpt] + [winfo height $wpt]/2 - \
		[winfo reqheight $w]/2 - [winfo vrooty $wpt]]
	if {$y < 0} {set y 0}
	set yborder 25
	if {$y+[winfo reqheight $w] +$yborder > [winfo screenheight $w]} {
	    incr y [expr [winfo screenheight $w] - \
		    ($y+[winfo reqheight $w] + $yborder)]
	}
	wm geometry $w +$x+$y
	wm deiconify $w
	raise $blcksel
	update idletasks
    }

    proc ReadCIFWriteFXYE {} {
	global CIF xdata ydata yesd ymoddata
	# get the x-coordinate info
	set item $CIF(xaxisvar)
	if {[llength $item] == 1} {
	    set conv {}
	    set xkey $item
	} else {
	    foreach {conv xkey} $item {}
	}
	# get number of points
	if {[catch {set nl [llength $xdata($xkey)]}]} {
	    MyMessageBox -parent $CIF(BlockChooser) -title "No Data" \
		-message "Problem: No x-values were selected to extract." \
		-icon warning -type {"Try again"} -default "try again"
	    return
	}
	# loop over yaxis keys
	set ylist {}
	set warnings {}
	foreach ykey $CIF(YaxisList) {
	    if {$CIF(yaxis_$ykey)} {
		if {$nl != [llength $ydata($ykey)]} {
		    lappend warnings $ykey
		} else {
		    lappend ylist $ykey
		}
	    }
	}
	if {$ylist == "" && $warnings == ""} {
	    MyMessageBox -parent $CIF(BlockChooser) -title "No Data" \
		-message "Problem: No y-values were selected to extract." \
		-icon warning -type {"Try again"} -default "try again"
	    return
	} elseif {$ylist == ""} {
	    MyMessageBox -parent $CIF(BlockChooser) -title "No Data" \
		-message "Note: data item(s) $warnings do not have the same number of points as $xkey ($nl) and cannot be loaded." \
		-icon warning -type {"Try again"} -default "try again"
	    return
	} elseif {$warnings != ""} {
	    MyMessageBox -parent $CIF(BlockChooser) -title "No Data" \
		-message "Note: data item(s) $warnings do not have the same number of points as $xkey ($nl) and will be ignored." \
		-type Continue -default continue
	}
	# do any y values not have su's?
	# do we have least-squares weights?
	set useWeights 0
	if {[array names ymoddata _pd_proc_ls_weight] != ""} {
	    if {$nl == [llength $ymoddata(_pd_proc_ls_weight)]} {
		set nosulist {}
		foreach ykey $ylist {
		    if {$ykey == "_pd_meas_counts_total"} continue
		    if {[array names yesd $ykey] != ""} continue
		    lappend nosulist $ykey
		}
		set ans [MyMessageBox -parent $CIF(BlockChooser) -title "No s.u.'s" \
			     -message "Data item(s)\n$nosulist\nhave no associated uncertainties. Use the least-squares weights reported in the CIF to generate them?" \
			     -type {Yes No} -default "no"]
		if {$ans == "yes"} {set useWeights 1}
	    }
	}

	pleasewait "while importing" "" $CIF(BlockChooser)
	# process the x-axis list
	set xvals  {}
	set lambda {}
	catch {
	    set lambda [lindex $xdata(_diffrn_radiation_wavelength) 0]
	}
	if {$conv == "Q"} {
	    global xaxisvars
	    set xlbl "Q, 1/A"
	    set xunit "A-1"
	    foreach x $xdata($xkey) {
		set Q .
		catch {
		    switch $xkey {
			_pd_proc_d_spacing {
			    set Q [expr {8*atan(1) / $x}]
			}
			_pd_proc_recip_len_Q {set Q $x}
			_pd_proc_2theta_corrected {-}
			_pd_proc_2theta_range_ {-}
			_pd_meas_2theta_range_ {-}
			_pd_meas_2theta_scan {
			    set Q [expr {16*atan(1) \
					     * sin($x * atan(1)/90. ) / $lambda}]
			}
		    }
		}
		lappend xvals $Q
	    }
	} elseif {$conv == "d-space"} {
	    set xlbl "d-space, A"
	    set xunit "A"
	    foreach x $xdata($xkey) {
		set d .
		catch {
		    switch $xkey {
			_pd_proc_d_spacing {set d $x}
			_pd_proc_recip_len_Q {
			    set d [expr {8*atan(1) / $x}]
			}
			_pd_proc_2theta_corrected {-}
			_pd_proc_2theta_range_ {-}
			_pd_meas_2theta_range_ {-}
			_pd_meas_2theta_scan {
			    set d [expr {0.5 * $lambda / \
					     sin($x * atan(1)/90.)}]
			}
		    }
		}
		lappend xvals $d
	    }
	} else {
	    global xaxisvars
	    set xlbl $xaxisvars($xkey)
	    # remove comma & remainder
	    set xunit [lindex [split $xlbl ,] end]
	    set xvals $xdata($xkey)
	}
	# OK, got the x-axis data -- start writing the data
	set filename [file join [pwd]  [file root [file tail $CIF(CIFfile)]].fxye]
	set filename [tk_getSaveFile -title "Select output file" -parent $CIF(parent) \
			  -initialdir [file dirname $filename] \
			  -initialfile [file tail $filename]]
	if {[string trim $filename] == ""} return

	if {$useWeights} {
	    set list {}
	    catch {set list $ymoddata(_pd_proc_ls_weight)}
	    foreach w $list {
		set val .
		catch {set val [expr {1./sqrt($w)}]}
		lappend siglist $val
	    }
	}
	# now start looping over the selected y data
	foreach ykey $ylist {
	    # get the y data
	    set yvals $ydata($ykey)
	    # get error estimates
	    set suvals {}
	    if {$ykey == "_pd_meas_counts_total"} {
		# counts
		foreach y $yvals {
		    set val .
		    catch {set val [expr {sqrt($y)}]}
		    lappend suvals $val
		}
	    } elseif {[array names yesd $ykey] != ""} {
		set suvals $yesd($ykey)
	    } elseif {$useWeights} {
		set suvals $siglist
	    }
	    set fil [open $filename w]
	    # write a data file in a gsas format
	    puts $fil "Automatically generated GSAS FXYE file from $CIF(CIFfile)"
	    set ibank 1
	    # total number of data points
	    set nchan [llength $yvals]
	    # starting angle in centi degrees
	    set bcoef1 [expr {100.0 * [lindex $xvals 0]} ]
	    # step size
	    set bcoef2 [expr {100.0 * ([lindex $xvals 1] -  [lindex $xvals 0])} ]
	    # place holder used twice in BANK lin
	    set bcoef3 0
	    set bnk "BANK"
	    set const "CONS"
	    set endd "FXYE"
	    # BANK line format
	    set line [format "%s %2d %8d%8d %s %10.2f%10.2f%2d%2d %s"  \
			  $bnk $ibank $nchan $nchan $const $bcoef1 $bcoef2 $bcoef3 $bcoef3 $endd ]
	    puts $fil "$line"
	    # print out line by line the position, intensity and esd.
	    foreach x $xvals y $yvals su $suvals {
		if {[catch {expr $su}]} {set su 0}
		if {$x != "." && $x != "?" && $y != "."} {
		    puts $fil [format \
				   "%15.6g %15.6g% 12.4g" \
				   [expr {100.*$x}] $y $su
			      ]
		}
	    }
	    close $fil
	}
	donewait
	catch {destroy $CIF(parent).cif}
	set ::newhist(rawfile) $filename
	return {}
    }
}