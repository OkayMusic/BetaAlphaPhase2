# $Id: export_xml.tcl 1251 2014-03-10 22:17:29Z toby $
# set local variables that define the proc to execute and the menu label
set label "FOX .xml format"
set action exp2xml
# write coordinates in an XML for FOX
proc exp2xml {} {
    global expmap expgui
    # don't bother if there are no phases to write
    if {[llength $expmap(phaselist)] == 0} {
	MyMessageBox -parent . -title "No phases" \
		-message "Sorry, no phases are present to write" \
		-icon warning
	return
    }
    #------------------------------------------------------------------
    if [catch {
	set filnam [file rootname $expgui(expfile)].xml
	set fp [open $filnam w]
	puts $fp "<ObjCryst Date=\"[clock format [clock seconds] -format "%Y-%m-%dT%T"]\">"
	foreach phase $expmap(phaselist) phasetype $expmap(phasetype) {
	    set name [file rootname $expgui(expfile)]_phase${phase}
	    set spacegroup [phaseinfo $phase spacegroup]
	    # remove final R from rhombohedral space groups
	    if {[string toupper [string range $spacegroup end end]] == "R"} {
		set spacegroup [string range $spacegroup 0 \
			[expr [string length $spacegroup]-2]] 
	    }
	    # remove spaces from space group
	    regsub -all " " $spacegroup "" spacegroup
	    # scan through the Origin 1/2 spacegroups for a match
	    set origin2 0
	    set sp [string toupper $spacegroup]
	    # treat bar 3 as the same as 3 (Fd3m <==> Fd-3m)
	    regsub -- "-3" $sp "3" sp
	    set fp1 [open [file join $expgui(scriptdir) spacegrp.ref] r]
	    # skip over the first section of file
	    set line 0
	    while {[lindex $line 1] != 230} {
		if {[gets $fp1 line] < 0} return
	    }
	    while {[gets $fp1 line] >= 0} {
		set testsg [string toupper [lindex $line 8]]
		regsub -all " " $testsg "" testsg
		regsub -- "-3" $testsg "3" testsg
		if {$sp == $testsg} {
		    set origin2 1
		    break
		}
	    }
	    close $fp1
	    # GSAS always uses origin2 when there is a choice
	    if {$origin2} {set spacegroup ${spacegroup}:2}
	    puts $fp "  <Crystal Name=\"${name}\" SpaceGroup=\"${spacegroup}\">"
	    set min 1
	    set max 100
	    foreach var {a b c alpha beta gamma} {
		if {$var == "alpha"} {
		    set min 28.6479
		    set max 171.887
		}
		set value [phaseinfo $phase $var]
		puts $fp "<Par Refined=\"0\" Limited=\"1\" Min=\"${min}\" Max=\"${max}\" Name=\"${var}\">${value}</Par>"
	    }
	    puts $fp {<Option Name="Use Dynamical Occupancy Correction" Choice="1" ChoiceName="Yes"/>}
	    
	    if {$phasetype == 4} {
		set cmd mmatominfo
	    } else {
		set cmd atominfo
	    }
	    set scatblock {     
    <ScatteringPowerAtom Name="${label}" Symbol="${elem}">
	    <Par Refined="0" Limited="1" Min="0.1" Max="5" Name="Biso">${Biso}</Par>
	    <RGBColour>$color</RGBColour>
	    </ScatteringPowerAtom>}

	    set i -1
	    foreach atom $expmap(atomlist_$phase) {
		# cycle through colors for now
		set color [lindex {"1 1 1" "1 0 0" "0 1 0" "0 0 1" "1 1 0" "0 1 1" "1 0 1"} [expr [incr i] % 7]]
		set label [$cmd $phase $atom label]
		set Biso [expr 8 * 3.14159 * 3.14159 * [$cmd $phase $atom Uiso]]
		set elem [$cmd $phase $atom type]
		puts $fp [subst $scatblock]
	    }
	    set scatblock {
      <Atom Name="${label}" ScattPow="${label}">
	    <Par Refined="1" Limited="0" Min="0" Max="1" Name="x">${x}</Par>
	    <Par Refined="1" Limited="0" Min="0" Max="1" Name="y">${y}</Par>
	    <Par Refined="1" Limited="0" Min="0" Max="1" Name="z">${z}</Par>
	    <Par Refined="0" Limited="1" Min="0.01" Max="1" Name="Occup">${frac}</Par>
	    </Atom>}

	    foreach atom $expmap(atomlist_$phase) {
		set label [$cmd $phase $atom label]
		foreach var {x y z frac} {
		    set $var  [$cmd $phase $atom $var]
		}
		puts $fp [subst $scatblock]
	    }
	    puts $fp {</Crystal>}
	}
	puts $fp {</ObjCryst>}
	close $fp
    } errmsg] {
	MyMessageBox -parent . -title "Export error" \
		-message "Export error: $errmsg" -icon warning
    } else {
	MyMessageBox -parent . -title "Done" \
		-message "File [file tail $filnam] was written"
    }
}

