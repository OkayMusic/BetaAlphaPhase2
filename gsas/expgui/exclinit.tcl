# $Id: exclinit.tcl 1251 2014-03-10 22:17:29Z toby $

# excledt stuff to be read in at initialization time

# default values
set graph(legend) 1
set graph(exclPrompt) 1
set graph(outname) out.ps
set graph(outcmd) lpr
set graph(color_excl) orange
set graph(color_calc) red
set graph(color_obs) black
set graph(xcaption) {}
set graph(ycaption) {}
set graph(xunits) 0
set graph(yunits) 0
set graph(autoraise) 1
set graph(FillExclRegionBox) 1
set expgui(autotick) 0

set peakinfo(obssym) scross
set peakinfo(obssize) 1.0
set peakinfo(exclsym) scross
set peakinfo(exclsize) 1.2
# create a set of markers for each phase
for {set i 1} {$i < 10} {incr i} {
    set peakinfo(flag$i) 0
    set peakinfo(max$i) Inf
    set peakinfo(min$i) -Inf
    set peakinfo(dashes$i) 1
}
# define colors
array set peakinfo {
    color1 magenta 
    color2 cyan 
    color3 yellow 
    color4 sienna 
    color5 orange 
    color6 DarkViolet 
    color7 HotPink 
    color8 salmon 
    color9 LimeGreen
}
if {$tcl_platform(platform) == "windows"} {
    set graph(printout) 1
} else {
    set graph(printout) 0
}

proc StartExcl {} {
    global graph
    # has this been run?
    set init ""
    catch {set init $graph(InitExcl)}
    if {$init != ""} {
	ShowExcl
	return
    }
    if [catch {package require BLT} errmsg] {
	MyMessageBox -parent . -title "BLT Error" \
		-message "Error -- Unable to load the BLT package; cannot run EXCLEDT" \
		-helplink "expgui.html blt" \
		-icon error -type Skip -default skip
	return 0
    }
    # handle Tcl/Tk v8+ where BLT is in a namespace
    #  use the command so that it is loaded
    catch {blt::graph}
    catch {
	namespace import blt::graph
	namespace import blt::vector
    }
    # old versions of blt don't report a version number
    global blt_version graph
    if [catch {set blt_version}] {set blt_version 0}
    # option for coloring markers: note that GH keeps changing how to do this!
    # also element -mapped => -show
    if {$blt_version < 2.3 || $blt_version >= 8.0} {
	# version 8.0 is ~same as 2.3
	set graph(MarkerColorOpt) -fg 
	# mapped is needed in 8.0, both are OK in 2.3
	set graph(ElementShowOption) "-mapped 1"
	set graph(ElementHideOption) "-mapped 0"
    } elseif {$blt_version >= 2.4} {
	set graph(MarkerColorOpt) -outline
	set graph(ElementShowOption) "-hide 0"
	set graph(ElementHideOption) "-hide 1"
    } else {
	set graph(MarkerColorOpt) -color
	set graph(ElementShowOption) "-mapped 1"
	set graph(ElementHideOption) "-mapped 0"
    }
    # vectors
    if [catch {
	foreach vec {allxvec xvec obsvec calcvec exxvec exobsvec} {
	    vector $vec
	    $vec notify never
	}
    } errmsg] {
	MyMessageBox -parent . -title "BLT Error" \
		-message "BLT Setup Error: could not define vectors \
(msg: $errmsg). \
EXCLEDT cannot be run without vectors." \
		-helplink "expgui.html blt" \
		-icon error -type Skip -default skip
	return 0
    }
    global expgui
    source [file join $expgui(scriptdir) excledt.tcl]
    set graph(InitExcl) 1
    ShowExcl
    return
}
