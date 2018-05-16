# define the information needed to list in the file menu
set action "MakeFoxBox"
set label "Fox XML"

# make a selection window for exporting to a Fox XML file
proc MakeFoxBox {} {
    catch {toplevel [set b .fox]}
    wm title $b "Export to FOX"
    eval destroy [winfo children $b]
    set row 0

    grid [frame $b.par -bd 2 -relief groove] \
	    -row [incr row] -column 0 -columnspan 2 -sticky w
    grid [label $b.par.1 -text "Dataset name:"] \
	    -row 0 -column 0
    global plot expnam hst
    set plot(projname) "$expnam H$hst"
    grid [entry $b.par.2 -textvariable plot(projname) -width 25] \
	    -row 0 -column 1 -columnspan 3 -sticky w
    if {[catch {set plot(lambda)}]} {set plot(lambda) 0}
    grid [label $b.par.3 -text "wavelength:"] \
	    -row 1 -column 0
    grid [entry $b.par.4 -textvariable plot(lambda) -width 9] \
	    -row 1 -column 1 -sticky w
    
    grid [label $b.par.5 -text "max:"] \
	    -row 2 -column 0
    if {[catch {set plot(sinthmax_type)}]} {set plot(sinthmax_type) 1}
    if {[catch {set plot(sinthmax)}]} {set plot(sinthmax) 10}
    grid [entry $b.par.6 -textvariable plot(sinthmax) -width 9] \
	    -row 2 -column 1  -sticky w
    grid [radiobutton $b.par.7 -variable plot(sinthmax_type) \
	    -text sin(th)/lam -value 1 \
	    -command {set plot(sinthmax) [expr $plot(sinthmax)/6.28]} \
	    ] -row 2 -column 2
    grid [radiobutton $b.par.8 -variable plot(sinthmax_type) \
	    -text Q -value 6.28\
	    -command {set plot(sinthmax) [expr $plot(sinthmax)*6.28]} \
	    ] -row 2 -column 3	
    grid [label $b.par.9 -text "# of Bkg points:"] \
	    -row 3 -column 0
    if {[catch {set plot(nbkg)}]} {set plot(nbkg) 20}
    grid [entry $b.par.10 -textvariable plot(nbkg) -width 3] \
	    -row 3 -column 1 -sticky w
    grid [frame $b.bot] \
	    -row [incr row] -column 0 -columnspan 2 -sticky w
    grid columnconfig $b.bot 0 -weight 1
    grid [label $b.bot.note -fg red -text ""] \
	    -row 0 -column 0 -columnspan 3
    grid [button $b.bot.b1 -text "Write" -command "MakeFoxfile $b"] \
	    -row 1 -column 0 -sticky w
    grid [button $b.bot.b2 -text "Close" -command "destroy $b"] \
	    -row 1 -column 1 -sticky w
}

# write the FOX XML file
proc MakeFoxfile {parent} {
    global xunits weightlist plot
    if {$plot(lambda) <= 0 || [catch {expr $plot(lambda)}]} {
	MyMessageBox -parent $parent -title "Wrong wavelength" \
		-message "The wavelength is invalid, please fix." \
		-icon warning -type Sorry -default sorry
	return
    }
    if {$xunits != "2Theta"} {
	MyMessageBox -parent $parent -title "Wrong units" \
		-message "The units for this plot are $xunits not 2Theta. Fox needs 2theta values." \
		-icon warning -type Sorry -default sorry
	return
    }
    if {[llength $weightlist] == 0} {
	MyMessageBox -parent $parent -title "No weights" \
		-message "Note that weights were not read. Uncertainties will be SQRT(I)." \
		-icon warning -type {"Limp ahead"} -default "limp ahead"
    }
    set file [tk_getSaveFile -title "Select output file" -parent $parent \
	    -defaultextension .xml -filetypes {{"FOX XML file" .xml}}]
    if {$file == ""} return
    if {[catch {
	set fp [open $file w]
    } errmsg]} {
	MyMessageBox -parent $parent -title "Export Error" \
		-message "An error occured during the export: $errmsg" \
		-icon error -type Ignore -default ignore
	return
    }
    pleasewait "while computing values" 
    set xlist  [xvec range 0 end]
    set yobslist  [obsvec range 0 end]
    global program
    if {$program == "bkgedit"}  {
	global termlist expgui
	set ybcklist  [BkgEval $termlist $expgui(FitFunction) \
		[xvec range 0 end] $expgui(RadiiList)]
    } else {
	set ybcklist  [bckvec range 0 end]
    }
    if {[llength $weightlist] == 0} {
	set siglist {}
	foreach y yobslist {
	    set sigy 1e10
	    catch {set sigy [expr {sqrt($y)}]}
	    lappend siglist $sigy
	}
    } else {
	set siglist {}
	foreach w $weightlist {
	    set sigy 1e10
	    catch {set sigy [expr {1/sqrt($w)}]}
	    lappend siglist $sigy
	}
    }
    set utc [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%S%Z"]
    puts $fp "<ObjCryst Date=\"$utc\">"
    puts $fp "  <PowderPattern Name=\"${plot(projname)}\">"
    FoxXMLputpar $fp 2ThetaZero 
    FoxXMLputpar $fp 2ThetaDisplacement
    FoxXMLputpar $fp 2ThetaTransparency
    puts $fp "  <Radiation>"
    FoxXMLputopt $fp Radiation Neutron
    FoxXMLputopt $fp Spectrum Monochromatic
    FoxXMLputpar $fp Wavelength $plot(lambda) \
	    [expr 0.9*$plot(lambda)]  [expr 1.1*$plot(lambda)]
    #  <LinearPolarRate>2.8026e-45</LinearPolarRate>
    puts $fp "  </Radiation>"
    puts $fp "  <MaxSinThetaOvLambda>[expr $plot(sinthmax)/$plot(sinthmax_type)]</MaxSinThetaOvLambda>"

    # process the x-axis
    set list {}

    puts $fp "   <PowderPatternBackground Name=\"\" Interpolation=\"Linear\">"
    puts $fp "\t<TThetaIntensityList>"
     set incr [expr {[set npts [llength $xlist]] / $plot(nbkg)}]
    for {set i 0} {$i < $npts} {incr i $incr} {
	puts $fp "\t[lindex $xlist $i] [lindex $ybcklist $i] 0"
    }
    puts $fp "\t</TThetaIntensityList>"
    puts $fp "   </PowderPatternBackground>"
    puts $fp {<PowderPatternComponent Scale="1" Name=""/>}

    set datalist {}
    foreach x $xlist y $yobslist sigy $siglist {
	lappend datalist [list $x $y $sigy]
    }
    set datalist [lsort -index 0 -real $datalist]
    set xmin [lindex [lindex $datalist 0] 0]
    set xmax [lindex [lindex $datalist end] 0]
    set xstepavg [expr {($xmax - $xmin) / ([llength $datalist]-1)}]
    # look for missing data points and insert dummy values
    set i -1
    set xprev {}
    set datalist1 $datalist
    foreach item $datalist1 {
	incr i
	foreach {x y sigy} $item {}
	if {$xprev != ""} {
	    set xstep [expr {$x - $xprev}]
	    if {$xstep > 1.9*$xstepavg} {
		set xstep [expr ($x - $xprev)/int(0.5 + ($x - $xprev)/$xstepavg)]
		for {set xs [expr $xprev + $xstep]} \
			{$xs < $x - 0.5*$xstepavg} \
			{set xs [expr $xs + $xstep]} {
		    set datalist [linsert $datalist $i [list $xs 0 1e10]]
		    incr i
		}
	    }
	}
	set xprev $x
    }
    set xstepavg [expr {($xmax - $xmin) / ([llength $datalist]-1)}]
    puts $fp "    <IobsSigmaWeightList TThetaMin=\"${xmin}\" TThetaStep=\"${xstepavg}\">"
    set xsmin [set xsmax $xstepavg]
    set xprev ""
    foreach item $datalist {
	foreach {x y sigy} $item {}
	if {$xprev != ""} {
	    set xstep [expr {$x - $xprev}]
	    if {$xstep > $xsmax} {set xsmax $xstep}
	    if {$xstep < $xsmin} {set xsmin $xstep}
	}
	set xprev $x
	# make sure we have valid numbers
	if {[catch {expr $y}]} {set y 0; set sigy 1e10}
	if {[catch {expr $sigy}]} {set sigy 1e10}
	set w 1e-20
	catch {set w [expr {1./($sigy*$sigy)}]}
	puts $fp "\t${y} ${sigy} $w"
    }
    puts $fp "    </IobsSigmaWeightList>"
    puts $fp "  </PowderPattern>"
    puts $fp "</ObjCryst>"
    close $fp
    donewait
    if {$xstepavg/50. < ($xsmax-$xsmin)} {
	MyMessageBox -parent $parent -title "Not Fixed Step" \
		-message "File $file created.\n\nWarning, step sizes range from $xsmin to $xsmax.\nFOX requires fixed step size data. Using the approximate step size of $xstepavg" \
		-icon warning -type Continue -default continue
    } else {
	MyMessageBox -parent $parent -title "OK" \
		-message "File $file created" \
		-type OK -default ok
    }
}

proc FoxXMLputpar {fp name "value 0" "min -2.86479" "max 2.86479" "refine 0"} {
    puts $fp "\t<Par Refined=\"${refine}\" Limited=\"1\" Min=\"${min}\" Max=\"${max}\" Name=\"${name}\">${value}</Par>"
}
proc FoxXMLputopt {fp name choicename "choice 0"} {
    puts $fp "\t<Option Name=\"${name}\" Choice=\"${choice}\" ChoiceName=\"${choicename}\"/>"
}
