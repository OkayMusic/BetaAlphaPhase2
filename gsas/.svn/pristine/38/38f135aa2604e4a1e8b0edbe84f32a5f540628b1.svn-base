######################################################################
# code for chemical restraints (soft constraints)
######################################################################
# main routine to display chemical contraints
proc DisplayChemRestraints {args} {
    #puts DisplayChemRestraints
    global expcons
    eval destroy [winfo children $expcons(chemmaster)]

    set leftfr $expcons(chemmaster).f1
    set rightfr $expcons(chemmaster).f2

    grid [frame $leftfr -bd 2 -relief groove] -column 0 -row 0 \
	-sticky nsew
    grid [frame $rightfr -bd 2 -relief groove] -column 1 -row 0 \
	-sticky nsew

    grid rowconfigure $expcons(chemmaster) 0 -weight 1
    grid columnconfigure $expcons(chemmaster) 1 -weight 1

    #Restraint Weight Control Box    
    grid [label $leftfr.lweight -text "Restraint Weight"] -column 0 -row 1 -sticky sw -pady 10
    grid [entry $leftfr.weight -width 8 -textvariable entryvar(chemrestweight)] -column 1 -row 1 -sticky sw \
	-padx 5 -pady 10
    set expcons(chemOnNoSelectDisablelist) $leftfr.weight 
    set ::entrycmd(chemrestweight) "ChemConst weight"
    set ::entrycmd(trace) 0
    set ::entryvar(chemrestweight) [ChemConst weight]
    set ::entrycmd(trace) 1
    grid [frame $leftfr.select] -columnspan 2 -column 0 -row 3 -sticky nsew

    foreach {top main side lbl} [MakeScrollTable $rightfr 500 300] {}
    grid [button $rightfr.del -textvariable expcons(DeleteLbl) \
             -command "DeleteChemRestraint $leftfr.select"] -column 1 -row 999 -columnspan 99
    lappend expcons(chemOnNoSelectDisablelist) $rightfr.del
    MouseWheelScrollTable $rightfr
    set ::expcons(ChemConstBox) $main
    set ::expcons(ChemConstBox_count) 0

    grid [label $top.lbl -textvariable expcons(ChemTopLbl) -bg beige] -column 0 \
        -columnspan 4 -row 0 -sticky w
    grid [label $top.sum -text "Actual Sum"] -column 5 -row 0
    grid [frame $top.f] -column 0 -columnspan 99 -row 1 -sticky news
    grid [label $top.ph -width 8 -text "Phase" -anchor center] -column 0 -row 3 -sticky ews
    grid [label $top.atm -width 8 -text "Atom\nlbl" -anchor center] -column 1 -row 3 -sticky ews
    grid [label $top.mult -text "Multi-\nplicity" -anchor center -padx 3] -column 2 -row 3 -sticky ews
    grid [label $top.occ  -text "Frac\nOccup." -anchor center -padx 3] -column 3 -row 3 -sticky ews
    grid [label $top.weight  -text "Multiplier" -anchor center -padx 5] -column 4 -row 3 -sticky ews
    grid [label $top.prod  -text "Product" -anchor center -padx 5] -column 5 -row 3 -sticky ews
    grid rowconfig  $top 3 -pad 10

    grid columnconfig  $top.f 4 -weight 1
    grid [label $top.f.0 -text "Target sum"] -column 0 -row 0 -sticky w
    grid [entry $top.f.1 -textvariable expcons(ChemSum) -width 12] -column 1 -row 0
    lappend expcons(chemOnNoSelectDisablelist) $top.f.1
    grid [label $top.f.2 -text "ESD"] -column 2 -row 0
    grid [entry $top.f.3 -textvariable expcons(ChemSumESD) -width 12] -column 3 -row 0
    lappend expcons(chemOnNoSelectDisablelist) $top.f.3
    grid [label $top.f.5 -width 8 -textvariable expcons(product) -anchor center] -column 5 -row 0 -sticky e
    set ::expcons(product) ""

    $::expcons(chemmaster).f2.can yview moveto 0.0
    ShowChemConstr $leftfr.select
    ResizeScrollTable $::expcons(chemmaster).f2
}

# Add a new restraint to the list of chemical restraints
proc AddChemConstr {win} {
    #puts AddChemConstr
    global expcons
    set conslist [ChemConst restraintlist get]
    if {$conslist == 1} {
        set conslist {}
    }
    lappend conslist {0 0.1}
    ChemConst restraintlist set $conslist
    RecordMacroEntry "ChemConst restraintlist set [list $conslist]" 0
    RecordMacroEntry "incr expgui(changed)" 0
    incr ::expgui(changed)
    ShowChemConstr $win
    set ::expcons(ChemConsSelect) [llength $conslist]
    ShowSelectedChemConst
}    

# display the occupancy and multiplicty for an atom site
proc ChemFillConstraintRow {num} {
    #puts "ChemFillConstraintRow phase $num $::expcons(phase$num) atom $::expcons(atom$num)"
    if {$::expcons(atom$num) == ""} {
        set mult ""
        set frac ""
    } else {
        set mult [atominfo $::expcons(phase$num) $::expcons(atom$num) mult]
        set frac [atominfo $::expcons(phase$num) $::expcons(atom$num) frac]
        set box $::expcons(ChemConstBox)
        $box.weight$num config -state normal
    }
    set ::expcons(mult$num) $mult
    set ::expcons(occ$num) $frac
    set ::expcons(prod$num) ""
}

# fill the atom menu
proc ChemSetAtmMenu {menu num} {
    #puts ChemSetAtmMenu
    set phase $::expcons(phase$num)
    $menu delete 0 end
    foreach a $::expmap(atomlist_$phase) {
        set lbl [atominfo $phase $a label]
        $menu add command -label "$lbl (#$a)" \
            -command "set expcons(atom$num) $a; set expcons(albl$num) $lbl; ChemFillConstraintRow $num"
    }
    set ::expcons(atom$num) {}
    set ::expcons(albl$num) {}
    ChemFillConstraintRow $num
    set box $::expcons(ChemConstBox)
    $box.weight$num config -state disabled
    set ::expcons(DisableChemWeightsTrace) 1
    set ::ChemWeights($num)  ""
    set ::expcons(DisableChemWeightsTrace) 0
}    

# add a row to the table. Optionally specify the phase # to select
# (if there is only one choice for phase, it gets selected)
proc AddRow2ChemContrTbl {{phase ""}} {
    set i [incr ::expcons(ChemConstBox_count)]
    set ::expcons(atom$i) ""
    set ::expcons(albl$i) {}
    set box $::expcons(ChemConstBox)
    # create and fill menus
    set menu [tk_optionMenu $box.ph$i expcons(phase$i) {}]
    set atmmenu [tk_optionMenu $box.atm$i expcons(albl$i) {}]
    grid $box.ph$i -column 0 -row $i -sticky news
    grid $box.atm$i -column 1 -row $i -sticky news
    grid [label $box.mult$i -width 8 -textvariable expcons(mult$i) -anchor center] -column 2 -row $i -sticky news
    grid [label $box.occ$i  -width 8 -textvariable expcons(occ$i) -anchor center] -column 3 -row $i -sticky news
    grid [entry $box.weight$i -width 8 -textvariable ChemWeights($i) \
              -state disabled] \
        -column 4 -row $i -sticky news
    grid [label $box.prod$i -width 8 -textvariable expcons(prod$i) -anchor center] \
        -column 5 -row $i -sticky news
    ChemFillConstraintRow $i
    $menu delete 0 end
    foreach ph $::expmap(phaselist) {
        $menu add command -label $ph \
            -command "set expcons(phase$i) $ph; ChemSetAtmMenu $atmmenu $i"
    }
    if {[llength $::expmap(phaselist)] == 1} {
        set phase [lindex $::expmap(phaselist) 0]
    }
    # select the phase if there is only one choice
    if {$phase != ""} {
        set ::expcons(phase$i) $phase
        ChemSetAtmMenu $atmmenu $i
    } else {
        set ::expcons(phase$i) {}
    }
    set ::expcons(DisableChemWeightsTrace) 1
    set ::ChemWeights($i)  ""
    set ::expcons(DisableChemWeightsTrace) 0
}

# this is called when a Constraint is selected (or cleared)
# it clears and then loads the values into the box to the left
proc ShowSelectedChemConst {} {
    #puts ShowSelectedChemConst
    foreach win [winfo children $::expcons(ChemConstBox)] {
        destroy $win
    }        
    set ::expcons(ChemConstBox_count) 0
    if {$::expcons(ChemConsSelect) == "" || $::expcons(ChemConsSelect) == 0} {
        set conslist [ChemConst restraintlist get]
        if {$conslist == 1 || [llength $conslist] == 0} {
            set ::expcons(ChemTopLbl) "no restraint selected"
            set ::expcons(DeleteLbl) ""
            foreach item $::expcons(chemOnNoSelectDisablelist) {
                $item config -state disabled
            }
            grid forget $::expcons(chemmaster).f2
            return
        } else {
            # select the first if none are selected
            set ::expcons(ChemConsSelect) 1
        }
    }
    set consnum $::expcons(ChemConsSelect)
    set ::expcons(ChemTopLbl) "Restraint $::expcons(ChemConsSelect) selected"
    set ::expcons(DeleteLbl) "Delete Restraint $::expcons(ChemConsSelect)"
    foreach item $::expcons(chemOnNoSelectDisablelist) {
        $item config -state normal
    }
    grid $::expcons(chemmaster).f2 -column 1 -row 0 -sticky news
    incr consnum -1
    set conslist [ChemConst restraintlist get]
    set ::expcons(ChemNotChanged) 1
    if {$conslist == 1} return
    set constr [lindex $conslist $consnum]

    set num 0
    set ::expcons(DisableChemWeightsTrace) 1
    foreach vals [lrange $constr 2 end] {
        incr num
        AddRow2ChemContrTbl [lindex $vals 0]
        set ::expcons(atom$num)  [lindex $vals 1]
        set ::expcons(albl$num) [atominfo [lindex $vals 0] [lindex $vals 1] label]
        ChemFillConstraintRow $num
        set ::expcons(DisableChemWeightsTrace) 1
        set ::ChemWeights($num)  [lindex $vals 2]
        set ::expcons(DisableChemWeightsTrace) 0
    }
    set ::expcons(DisableChemWeightsTrace) 0
    ChemShowTotals
    # scroll to top
    $::expcons(chemmaster).f2.can yview moveto 0.0
    ResizeScrollTable $::expcons(chemmaster).f2
    set ::expcons(DisableChemWeightsTrace) 1
    set ::expcons(ChemSum) [lindex $constr 0]
    set ::expcons(ChemSumESD) [lindex $constr 1]
    set ::expcons(DisableChemWeightsTrace) 0

 }

# Show a list of restraints in box to left; select first if only one
proc ShowChemConstr {win} {
    global expcons
    set ::expcons(ChemConsSelect) ""
    eval destroy [winfo children $win]
    set conslist [ChemConst restraintlist get]
    if {$conslist == 1 || [llength $conslist] == 0} {
        grid [label $win.l -text "no restraints defined" \
                  -pady 10 -anchor center ] -column 0 -row 1 -sticky ns
        set conslist {}
    } else {
        for {set i 1} {$i <= [llength $conslist]} {incr i} {
            grid [radiobutton $win.$i -text "Restraint $i" \
                      -variable expcons(ChemConsSelect) \
                      -command ShowSelectedChemConst -value $i] -column 0 -row $i
        }
        if {[llength $conslist] == 1} {set ::expcons(ChemConsSelect) 1}
#        set ::expcons(ChemConsSelect) 1
    }
    if { [llength $conslist] < 9} {
        grid [button $win.add -text "Add Restraint" -anchor center \
                  -command "AddChemConstr $win"] \
            -columnspan 2 -column 0 -row 99
    }
    ShowSelectedChemConst
}

# updates the Actual Sum 
proc ChemShowTotals {} {
    #puts ChemShowTotals
    set errors 0
    set unfilled 0
    set product 0.0
    set conslist {}
    for {set i 1} {$i <= $::expcons(ChemConstBox_count)} {incr i} {
        set num $i
        set weight [string trim $::ChemWeights($num)]
        if {$::expcons(phase$num) == "" || \
                $::expcons(atom$num) == "" || \
                $weight == ""} {
            incr unfilled
            continue
        }
        if {[catch {
            set weight [expr 1.*$weight]
            set prod [expr {
                            $::expcons(mult$num) * 
                            $::expcons(occ$num) * $weight
                        }]
            set ::expcons(prod$num) [format "%.3f" $prod]
         } err ]} {
            incr errors
        } else {
            set product [expr {$product + $prod}]
            if {$weight != 0} {
                lappend conslist [list $::expcons(phase$num) $::expcons(atom$num) $weight]
            }   
        }
    }
    if {$errors > 0} {
        set ::expcons(product) "?"
        return {}
    } else {
        # if there are no unused rows, add one
        if {$unfilled == 0} {
            AddRow2ChemContrTbl
            set ::expcons(DisableChemWeightsTrace) 1
            set ::ChemWeights($::expcons(ChemConstBox_count)) ""
            set ::expcons(DisableChemWeightsTrace) 0
            ResizeScrollTable $::expcons(chemmaster).f2
            #puts "scroll to end?"
            #$::expcons(chemmaster).f2.can yview moveto 1.0
        }
        set ::expcons(product) [format "%.3f" $product]
    }
    return $conslist
}

# compute the product for a row. Called when the weight value is changed
# show a box as yellow, if an invalid number is entered
proc ChemUpdateRow {var index mode} {
    if $::expcons(DisableChemWeightsTrace) return
    set num $index
    set weight [string trim $::ChemWeights($num)]
    set box $::expcons(ChemConstBox)
    # if any var is blank ignore the row
    if {!($::expcons(phase$num) == "" || \
              $::expcons(atom$num) == "" || \
              $weight == "")} {
        # not blank
        if {[catch {expr 1.*$weight} err]} {
            $box.weight$num config -fg red -bg yellow
            return
        }
    }
    $box.weight$num config -fg black -bg gray95
    SaveChemRestraint
}

# called after a weight is entered or after a sum/esd is entered 
# to update the "actual sum" and if there are no errors to 
# save the restraint
proc SaveChemRestraint {args} {    
    #puts "SaveChemRestraint $::expcons(DisableChemWeightsTrace)"
    if $::expcons(DisableChemWeightsTrace) return
    set conslist [ChemShowTotals]
    if {[llength $conslist] == 0} return
    catch {
        expr $::expcons(ChemSum) 
        expr $::expcons(ChemSumESD) 
        set newcnst [concat $::expcons(ChemSum) $::expcons(ChemSumESD) $conslist]
    }
    set conslist [ChemConst restraintlist get]
    #foreach i $conslist {puts $i}
    set i $::expcons(ChemConsSelect)
    incr i -1
    set conslist [lreplace $conslist $i $i $newcnst]
    #puts "\nafter"
    #foreach i $conslist {puts $i}
    ChemConst restraintlist set $conslist
    if $::expcons(ChemNotChanged) {
        set ::expcons(ChemNotChanged) 0
        incr ::expgui(changed)
        RecordMacroEntry "incr expgui(changed)" 0
    }
    RecordMacroEntry "ChemConst restraintlist set [list $conslist]" 0
}

proc DeleteChemRestraint {win} {
    set conslist [ChemConst restraintlist get]
    set i $::expcons(ChemConsSelect)
    incr i -1
    set conslist [lreplace $conslist $i $i]
    ChemConst restraintlist set $conslist

    ShowChemConstr $win
    if {[llength $conslist] > 0} {
        set ::expcons(ChemConsSelect) 1
    } else {
        set ::expcons(ChemConsSelect) ""
    }
    ShowSelectedChemConst

    if $::expcons(ChemNotChanged) {
        set ::expcons(ChemNotChanged) 0
        incr ::expgui(changed)
        RecordMacroEntry "incr expgui(changed)" 0
    }
    RecordMacroEntry "ChemConst restraintlist set [list $conslist]" 0
}

set ::ChemWeights(0) ""
foreach item [trace vinfo ::ChemWeights] {
    eval trace vdelete ::ChemWeights $item
}
trace variable ::ChemWeights w ChemUpdateRow 

set ::expcons(ChemSum) ""
set ::expcons(ChemSumESD) ""
foreach item [trace vinfo expcons(ChemSum)] {
    eval trace vdelete expcons(ChemSum) $item
}
trace variable expcons(ChemSum) w SaveChemRestraint 

foreach item [trace vinfo expcons(ChemSumESD)] {
    eval trace vdelete expcons(ChemSumESD) $item
}
trace variable expcons(ChemSumESD) w SaveChemRestraint 

set expcons(DisableChemWeightsTrace) 0
