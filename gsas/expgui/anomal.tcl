# this should get moved elsewhere

proc anomalous_load {args} {
     catch {unset temp}
     # trap if more than one histogram is selected unless global mode
     if {$::expgui(globalmode) == 0 && [llength $::expgui(curhist)] > 1} {
         set ::expgui(curhist) [lindex $::expgui(curhist) 0]
     }

     set histnum $::expgui(curhist)
     set histlbl [lindex $::expmap(powderlist) $histnum]

     #determine list of histograms with the same wavelength
     set ::anom_list ""
     set ::anom_wave [histinfo $histlbl lam1]
     foreach test $::expmap(powderlist) {
         #puts "[histinfo $test lam1] versus $::anom_wave"
         if {[histinfo $test lam1] == $::anom_wave} {
             lappend ::anom_list $test
         }
     }
     #puts "this wavelength is found in histogram $::anom_list"

     set ::anom_atomcount 0
     set ::anom_abort [histinfo $histlbl anomff]

    foreach temp [histinfo $histlbl anomff] {
        incr ::anom_atomcount
        set ::anom_lbl($::anom_atomcount) [lindex $temp 0]
        set ::anom_fp($::anom_atomcount) [lindex $temp 1]
        set ::anom_f2p($::anom_atomcount) [lindex $temp 2]
        #puts "$::anom_lbl($::anom_atomcount) $::anom_fp($::anom_atomcount) $::anom_f2p($::anom_atomcount)"
    }
}

proc anomalous_editor {args} {
    if {[llength $::anom_list] == 0} {
	MyMessageBox -parent . -title "No Anom Hists" \
	    -icon warning \
	    -message "No appropriate histograms for \u0394f' and \u0394f\" fields" 
        return
    }
    # make a list of atom types in all phases
    foreach ph $::expmap(phaselist) {
        foreach at $::expmap(atomlist_$ph) {
            set typelist([atominfo $ph $at type]) ""
        }
    }
    # find the elements that do not have anom values already
    set oldff {}
    foreach items [histinfo [lindex $::anom_list 0] anomff] {
        lappend oldff [lindex $items 0]
    }
    set newff {}
    foreach typ [array names typelist] {
        if {[lsearch $oldff $typ] == -1} {lappend newff $typ}
    }
    #puts "newff = $newff"
    #if {$::anom_atomcount == 0} {return}
     catch {destroy .anomalous}
     set anomal .anomalous
     toplevel $anomal
     wm title $anomal "Anomalous Dispersion Terms"
     #wm geometry $anomal 520x370+10+10
     putontop $anomal
     set str {}
     foreach i $::anom_list {
         if {$str != ""} {append str ", "}
         append str $i
     }

    grid [frame $anomal.list -bd 2 -relief groove] -row 0 -column 0 -sticky news
    grid [label $anomal.list.lbl1 -text "The anomalous dispersion terms will be set for x-ray histogram(s)\n with wavelength $::anom_wave angstroms \[histogram(s) $str\]"] -row 0 -column 0
    grid [frame $anomal.con -bd 2 -relief groove] -row 6  -column 0 -sticky news
    set cmd "anomalous_add $anomal [list $newff]"
    grid [button $anomal.con.addnew -text "Add new type:"  \
              -command $cmd] -column 0 -row 4
    if {[llength $oldff] >= 9 || [llength $newff] == 0} {
        $anomal.con.addnew configure -state disabled
    } else {
        eval tk_optionMenu $anomal.con.elem ::anom_new $newff
        grid $anomal.con.elem -column 1 -row 4
    }
    grid columnconfigure $anomal.con 2 -weight 1
    grid [button $anomal.con.save  -width 8 -text "Save"  -command {anomalous_save}] \
        -column 3 -row 4 -padx 3
    grid [button $anomal.con.abort -width 8 -text "Cancel" -command {anomalous_abort}] \
        -column 4 -row 4 -padx 3
    grid columnconfigure $anomal.con 5 -weight 1

     grid [frame $anomal.warning -bd 2 -relief groove] -row 5 -column 0 -sticky news
     grid [label $anomal.warning.1 -text "Note: only 9 sets of \u0394f' and \u0394f\" values can be saved"] \
          -columnspan 2 -column 0 -row 0 -pady 3
#     grid [label $anomal.warning.2 -anchor center -text "Notice: \u0394f' and \u0394f\" fields are added after GENLES is run."] \
#          -columnspan 2 -column 0 -row 1 -pady 3

     grid [frame $anomal.info -bd 2 -relief groove -width 600] -row 1 -column 0 -sticky ns
    anom_fill_table $anomal.info
}

proc anomalous_add {anomal newff} {  
    add_anomff $::anom_list $::anom_new
    incr ::expgui(changed)
    set oldff {}
    foreach items [histinfo [lindex $::anom_list 0] anomff] {
        lappend oldff [lindex $items 0]
    }
    set ff {} 
    foreach typ $newff {
        if {[lsearch $oldff $typ] == -1} {lappend ff $typ}        
    }
    set newff $ff
    destroy $anomal.con.elem
    if {[llength $newff] == 0} {
        $anomal.con.addnew configure -state disabled        
    } else {
        eval tk_optionMenu $anomal.con.elem ::anom_new $newff
        set ::anom_new [lindex $newff 0]
        grid $anomal.con.elem -column 1 -row 4
    }
    anomalous_load
    anom_fill_table $anomal.info
}

proc anom_fill_table {top} { 
    eval destroy [winfo children $top]
     grid [label $top.toplabel1  -text "Type" -width 8] -column 0 -row 0
     grid [label $top.toplabel2  -anchor center -text " \u0394f'" -width 8]  -column 2 -row 0
     grid [label $top.toplabel3  -anchor center -text " \u0394f\"" -width 8] -column 4 -row 0
     for {set i 1} {$i <= $::anom_atomcount} {incr i} {
         grid [label $top.atom_lbl($i) -text "$::anom_lbl($i)" -width 8] -column 0 -row $i
         grid [entry $top.atom_fp($i)  -textvariable ::anom_fp($i)  -width 8] -column 2 -row $i
         grid [entry $top.atom_f2p($i) -textvariable ::anom_f2p($i) -width 8] -column 4 -row $i
     }
}

proc anomalous_save {args} {
     set histnum $::expgui(curhist)
     #puts $histnum
     set histlbl [lindex $::expmap(powderlist) $histnum]
     #puts $histlbl
     set x ""
     set atomcount 0
     foreach atom [histinfo $histlbl anomff] {
             incr atomcount
             lappend x "$::anom_lbl($atomcount) $::anom_fp($atomcount) $::anom_f2p($atomcount)"
     }
     #puts $x
     foreach test $::anom_list {
          histinfo $test anomff set $x
     }
     incr ::expgui(changed)
     afterputontop
     destroy .anomalous
}

proc anomalous_abort {args} {
     set histnum $::expgui(curhist)
     set histlbl [lindex $::expmap(powderlist) $histnum]
     histinfo $histlbl anomff set $::anom_abort
     afterputontop
     destroy .anomalous
}

proc Edit_Anomalous {args} {
     anomalous_load
     anomalous_editor
}