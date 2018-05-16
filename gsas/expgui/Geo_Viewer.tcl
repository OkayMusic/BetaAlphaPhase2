#Revision 1 Prints Bond Distances, no ability to sort.

#List of Global Variables:
#::geo_atomtype($atype1)        contains atom id codes for a particular atom type (atype1)
#::geo_atomlabel($alabel1)      contains atom id code for a particular atom  (alabel1)
#::geo_enable($x)               switch to enable bond angle/distance determination.
#::geo_atomtype                 filtered atom type

#::geo_bond_list   list of bond lengths
#                  0    phase number
#                  1    atom 1 code
#                  2    atom 2 code
#                  3    atom 1 type
#                  4    atom 2 type
#                  5    atom 1 label
#                  6    atom 2 label
#                  7    distance
#                  8    esd
#                  9    symm code
#                  10   tranlational symm
#::geo_angle_list list of bond angles
#                  0    phase number
#                  1    atom 1 code (central)
#                  2    atom 2 code
#                  3    atom 3 code
#                  4    atom 1 type (central)
#                  5    atom 2 type
#                  6    atom 3 type
#                  7    atom 1 label (central)
#                  8    atom 2 label
#                  9    atom 3 label
#                  10   angle
#                  11   esd
#                  12   symm atom 2
#                  13   trans atom 2
#                  14   symm atom 3
#                  15   trans atom 3

proc Geo_Initialize {} {
     set ::geo_entryvar(atomtype) "all"
     catch {unset ::geo_enable}
     catch {unset ::geo_angles}
     catch {unset ::geo_bonds}
     catch {unset ::geo_angle_keys}
     catch {unset ::geo_phase_list}
     array set ::geo_angles ""
     array set ::geo_bonds ""
     set ::geo_alist ""
     set ::geo_filterval 5.00
}

proc Geo_Read {filename} {

   if {[file exists $filename]} {
   set fh [open $filename r]
   } else {
     puts "$filename not found in directory [pwd]"
   }

   set bond_total -1
   set angle_total -1

   set ::geo_phase_list {}
   catch {unset ::geo_angles}
   catch {unset ::geo_bonds}
   array set ::geo_bonds ""
   array set ::geo_angles ""
   array set ::geo_angle_keys ""


   while {[gets $fh line] >= 0} {
	if {[lindex $line 2] == 0} {
	    incr bond_total
	    set temp $line
	    set t1 ""
            set phase [lindex $temp 1]
            set b_dist [lindex $temp 3]
            set b_esd [lindex $temp 4]
            set atom1 [lindex $temp 5]
            set atom2 [lindex $temp 6]
            set atype1 [atominfo $phase [lindex $temp 5] type]
            set atype2 [atominfo $phase [lindex $temp 6] type]
            set atype1 [lindex [split $atype1 {+-}] 0]
            set atype2 [lindex [split $atype2 {+-}] 0]
            set alabel1 [atominfo $phase [lindex $temp 5] label]
            set alabel2 [atominfo $phase [lindex $temp 6] label]
            set symmcode [string map {" " ""} [set t2 "[lindex $temp 7][lindex $temp 8]"]]
            set key1 [string map {" " ""} [set t2 "${symmcode}_[lindex $atom2]"]]
            lappend t1 $phase $atom1 $atom2 $atype1 $atype2 $alabel1 $alabel2 $b_dist $b_esd $symmcode $key1
            lappend ::geo_bonds($phase,$atom1) $t1
            lappend ::geo_phase_list $phase

            #create atom lists, remove duplicates
            lappend ::geo_atomtype${phase}(all) [lindex $temp 5]
            lappend ::geo_atomtype${phase}($atype1) [lindex $temp 5]
            set ::geo_atomtype${phase}(all) [lsort -integer -uniq [set ::geo_atomtype${phase}(all)]]
            set ::geo_atomtype${phase}($atype1) [lsort -integer -uniq [set ::geo_atomtype${phase}($atype1)]]

	} elseif {[lindex $line 2] == 1} {
            incr angle_total
            set temp $line
            set t1 ""
	    set phase [lindex $temp 1]
            set b_angle [lindex $temp 3]
            set b_esd [lindex $temp 4]
            set atom1 [lindex $temp 5]
            set atom2 [lindex $temp 6]
            set atom3 [lindex $temp 7]
            set alabel1 [atominfo $phase [lindex $temp 5] label]
            set alabel2 [atominfo $phase [lindex $temp 6] label]
            set alabel3 [atominfo $phase [lindex $temp 7] label]
            set symmcode1 [string map {" " ""} [set t2 "[lindex $temp 8][lindex $temp 9]"]]
            set symmcode3 [string map {" " ""} [set t3 "[lindex $temp 10][lindex $temp 11]"]]
            set key1 [string map {" " ""} [set t2 "${symmcode1}_[lindex $atom1]"]]
            set key3 [string map {" " ""} [set t3 "${symmcode3}_[lindex $atom3]"]]
            lappend t1 $phase $atom1 $atom2 $atom3 $alabel1 $alabel2 $alabel3 \
                         $b_angle $b_esd $key1 $key3
            lappend ::geo_phase_list $phase
            set ::geo_angles($phase,$key1,$atom2,$key3) $t1
	}
   }
   set ::geo_phase_list [lsort -integer -uniq $::geo_phase_list]
   close $fh
}

proc Geo_Viewer {args} {

    # Run DISAGL
    global expgui
    pleasewait "searching interatomic distances"
    # save EXP file if changed
    savearchiveexp
    set root [file root $expgui(expfile)]
    catch {file delete -force $root.disagl}
    close [open disagl.inp w]
    catch {exec [file join $expgui(gsasexe) disagl] \
	       [file tail $root] < disagl.inp > disagl.out}
    catch {file delete -force disagl.inp disagl.out}
    if {! [file exists $root.disagl]} {
	MyMessageBox -parent . -title "DISAGL Problem" \
	    -message "Unable to run DISAGL. Do you have problems writing files in [pwd]?" \
	    -icon error
	donewait
	return
    }

    # load DISAGL distances
    Geo_Read $root.disagl
    donewait
    if {[llength  $::geo_phase_list] == 0} {
	MyMessageBox -parent . -title "DISAGL Problem" \
	    -message "No output found in DISAGL output. Is something wrong with DISAGL settings or this .EXP file?" \
	    -icon error
	return
    }
     set mcb .maincontrolbox
     catch {toplevel $mcb}
     eval destroy [winfo children $mcb]
     wm title $mcb "Viewer for Bond Distances and Angles"

     raise $mcb
     set sc $mcb.sortcon
     set as $mcb.atomselect
     set ad $mcb.atomdistlist
     set dc $mcb.disaglcon

     frame $sc -bd 2 -relief groove
     frame $as -bd 2 -relief groove
     frame $ad -bd 2 -relief groove
     frame $dc -bd 2 -relief groove
     grid $sc -column 0 -row 0 -sticky new
     grid $as -column 0 -row 1 -sticky new
     grid $ad -column 1 -row 0 -rowspan 3 -sticky nesw
     grid $dc -column 0 -row 2

     grid [button $dc.dcon -text "Run DISAGL Program" -command {DA_Control_Panel 1; unset ::geo_phase_list; Geo_Viewer}] \
        -column 0 -row 0
        $dc.dcon config -bd 4


     grid rowconfigure $mcb 1 -weight 1
     grid columnconfigure $mcb 1 -weight 1

     label $sc.phlabel -text Phase
#     eval tk_optionMenu $sc.phase ::geo_entryvar(phase) $::expmap(phaselist)
     eval tk_optionMenu $sc.phase ::geo_entryvar(phase) $::geo_phase_list
     label $sc.atom1 -text "Atom Type"
     label $sc.filterlab -text "Dmax Filter"
     entry $sc.filterval -textvariable ::geo_filterval
          $sc.filterval config -width 6
     #button $sc.engage -text "Print Info" -command Geo_Fill_Display
     grid $sc.phlabel -row 0 -column 0
     grid $sc.phase   -row 0 -column 1
     grid $sc.atom1   -row 1 -column 0
     grid $sc.filterlab   -row 2 -column 0
     grid $sc.filterval -row 2 -column 1

     label $as.atom -text "Choose Atom(s)"

     grid $as.atom -row 0 -column 1

     foreach {top main side lbl} [MakeScrollTable $as] {}
     [winfo parent $main] config -bg [$main cget -bg]

   foreach item [trace vinfo ::geo_entryvar(phase)] {
       eval trace vdelete ::geo_entryvar(phase) $item
   }
   foreach item [trace vinfo ::geo_entryvar(atomtype)] {
       eval trace vdelete ::geo_entryvar(atomtype) $item
   }
   set ::geo_entryvar(phase) [lindex $::geo_phase_list 0]
   Geo_setPhase $sc $as $main
   trace variable ::geo_entryvar(phase) w "Geo_setPhase $sc $as $main"
   trace variable ::geo_entryvar(atomtype) w "Geo_setAtomType $sc $as $main"
   Geo_Display
       ResizeScrollTable $as
       $as.can config -width [lindex [$as.can cget -scrollregion] 2]

   }

proc Geo_setPhase {sc as main args} {
     catch {destroy $sc.atomtype}
     catch {eval destroy [winfo children $::geo_main]}
     catch {eval destroy [winfo children $::geo_side]}
     set ::geo_entryvar(atomtype) all
     set ::geo_alist ""
     eval tk_optionMenu $sc.atomtype ::geo_entryvar(atomtype) \
          "[lsort [array names ::geo_atomtype${::geo_entryvar(phase)}]]"
     grid $sc.atomtype -column 1 -row 1
     Geo_setAtomType  $sc $as $main
}

proc Geo_setAtomType {sc as main args} {
   set ::geo_atomlist ""
   set ::geo_atomlist [set ::geo_atomtype${::geo_entryvar(phase)}($::geo_entryvar(atomtype))]
   set rownum 1
   set colnum 1
   eval destroy [winfo children $main]
      foreach i $::geo_atomlist {
             #puts $i
             if {[expr $colnum % 5] == 0} {incr rownum; set colnum 1}
             set x [atominfo $::geo_entryvar(phase) $i  label]
             set xlower [string tolower $x]
             set ::geo_enable($xlower) $i
             #parray ::geo_enable
             button $main.atom_$xlower -text "$x" -width 5 -command "Geo_Enable $main.atom_$xlower $::geo_enable($xlower)"
             grid $main.atom_$xlower -column $colnum -row $rownum -padx 5 -pady 5
             incr colnum

             }
      ResizeScrollTable $as
      $as.can config -width [lindex [$as.can cget -scrollregion] 2]
}

proc Geo_Enable {main entry args} {

        if {[$main cget -relief] == "raised"} {
        lappend ::geo_alist $entry
        $main config -bg green -relief sunken

        } else {
          set i [lsearch $::geo_alist $entry]
          puts "seach = $i"
          set ::geo_alist [string trim [lreplace $::geo_alist $i $i]]
#          $main config -bg SystemButtonFace -relief raised
          $main config -bg LightGray -relief raised
        }
   Geo_Fill_Display
}

proc Geo_Display {args} {
     catch {destroy $as.$main}

     set ad .maincontrolbox.atomdistlist
     foreach {top ::geo_main ::geo_side lbl} [MakeScrollTable $ad] {}
     [winfo parent $::geo_main] config -bg [$::geo_main cget -bg]

     bind $ad <Configure> "catch {ResizeScrollTable $ad}"
       ResizeScrollTable $ad
       $ad.can config -width 500


     #puts "$ad $::geo_main"

 #    label $top.toplabel0 -text "Atom 1" -width 8
     label $top.toplabel1 -text "Atom 2" -width 8
     label $top.toplabel2 -text "symm" -width 8
     label $top.toplabel3 -text "Distance" -width 10
     label $top.toplabel4 -text "Angle"
#     grid $top.toplabel0 -column 0 -row 0
     grid $top.toplabel1 -column 0 -row 0
     grid $top.toplabel2 -column 1 -row 0
     grid $top.toplabel3 -column 2 -row 0
     grid $top.toplabel4 -column 3 -row 0
}
proc Geo_Fill_Display {args} {
     set rownum 0
     set colnum 3
     set bondnum 0
     set counter 0
     eval destroy [winfo children $::geo_main]
     eval destroy [winfo children $::geo_side]

     foreach i $::geo_alist {
             set slist [lsort -index 7 $::geo_bonds($::geo_entryvar(phase),$i)]
             set colnum 3
             set keylist ""
             set atmlist {}
             set symlist {}
             incr rownum
             if {[string trim $::geo_filterval] == ""} {set ::geo_filterval 5.00}
             foreach j $slist {
                 if {[lindex $j 7] <= $::geo_filterval} {
                    lappend keylist [lindex $j 10]
                    lappend atmlist [lindex $j 6]
                    lappend symlist [lindex $j 9]
                    label $::geo_side.atom1${bondnum} -text [lindex $j 5] -width 8
                    label $::geo_main.atom2${bondnum} -text [lindex $j 6] -width 8
                    label $::geo_main.atom2symm${bondnum} -text [lindex $j 9] -width 8
                    set bonddist [lindex $j 7]
                    set bondesd  [lindex $j 8]
                    set bondentry [formatSU $bonddist $bondesd]
                    label $::geo_main.bonddist${bondnum} -text $bondentry -width 10

                    grid $::geo_side.atom1${bondnum} -row $rownum -column 0
                    grid $::geo_main.atom2${bondnum} -row $rownum -column 0
                    grid $::geo_main.atom2symm${bondnum} -row $rownum -column 1
                    grid $::geo_main.bonddist${bondnum} -row $rownum -column 2

                    set key [lindex $j 10]
                    set atom [lindex $j 1]
                    set phase [lindex $j 0]


                    foreach k $keylist {

                            if {$key != $k} {
                            # search for atom 1 - central atom - atom 2 angle.
                            if {[array name ::geo_angles "$phase,$key,$atom,$k"] != ""} {
                               set ang  [lindex $::geo_angles($phase,$key,$atom,$k) 7]
                               set angesd [lindex $::geo_angles($phase,$key,$atom,$k) 8]
                               set angentry [formatSU $ang $angesd]
                               label $::geo_main.$counter -text $angentry
#                               label $::geo_main.$counter -text [lindex $::geo_angles($phase,$key,$atom,$k) 7]
                               grid $::geo_main.$counter -row $rownum -column $colnum -padx 5
                               incr colnum
                               incr counter
                               # search for atom 2 - central atom - atom 1 angle.
                            } elseif {[array name ::geo_angles "$phase,$k,$atom,$key"] != ""} {
                               set ang  [lindex $::geo_angles($phase,$k,$atom,$key) 7]
                               set angesd [lindex $::geo_angles($phase,$k,$atom,$key) 8]
                               set angentry [formatSU $ang $angesd]
                               label $::geo_main.$counter -text $angentry
#                              label $::geo_main.$counter -text [lindex $::geo_angles($phase,$k,$atom,$key) 7]
                              grid $::geo_main.$counter -row $rownum -column $colnum -padx 5

                              incr colnum
                              incr counter
                            }
                            }
                    }
                 incr bondnum
                 incr rownum
                 set colnum 3
             }
             }
                  set colnum 3
            incr rownum
             foreach atm [lrange $atmlist 0 end-1] {
                label $::geo_main.$counter -text $atm
                grid $::geo_main.$counter -row $rownum -column $colnum
                    incr colnum
                    incr counter
             }
                 set colnum 3
             incr rownum
             foreach sym [lrange $symlist 0 end-1] {
                label $::geo_main.$counter -text $sym
                grid $::geo_main.$counter -row $rownum -column $colnum
                    incr colnum
                    incr counter
             }
              incr rownum
             grid rowconfigure $::geo_main $rownum  -minsize 10
}
ResizeScrollTable [winfo parent [winfo parent $::geo_main]]
MouseWheelScrollTable [winfo parent [winfo parent $::geo_main]]
}
proc Geo_Print {} {
}

Geo_Initialize
#Geo_Read TEST.DISAGL
#Geo_Viewer

