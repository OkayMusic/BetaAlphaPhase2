# Procedure list:
# RB_Import_Data_Type {args}            determines types of input available for rigid body creation panel.
# RB_Load_RBdata {args}                 parses variables from ReadRigidBody
# RB_Load_Mapdata {phase bodnum mapnum} parses variables from ReadRigidBodyMapping
# RB_Control_Panel {panelnum args}      builds notebook for rigid bodies
# RB_Create {args}                      builds rigid body create panel
# RB_Create_Cart {bodnum location args} creates cartesian coordinate frame in nbt window. (nbt = new body type)
# RB_Create_save {bodnum args}          builds rigid body from nbt window
# RB_Delete_Body {bodnum location args} panel queries user confirm rigid body deletion
# RB_Delete_Body_Confirm {bodnum location args} deletes and unmaps rigid body with UnMapRigidBody and DeleteRigidBody
# RB_Populate {rb_notebook bodnum args} populates notebook pages with rigid body information
# RB_Map_New {bodnum args}              adds new map for bodnum
# RB_VarNums                            determines (add) or removes (sub ##) rigid body variable numbers.
# RB_View_RMS {address args}            prints RMS data from Fit Rigid Body on mapping panel
# RB_Choose_Atom {bodnum args}          finds possible first atom for rigid body mapping
# RB_FitBody2Coords {bodnum menu}          fits rigid body to coordinates.
# RB_PlotStrBody {bodnum menu}             plots rigid body onto structure
# RB_Write_Map {args}                   writes mapping information with MapRigidBody
# RB_Atom_List {phase atomnum address bodnum args} returns a list of atoms in rigid body
# proc RB_ProcessPhase {bodnum args}    activate / deactivate buttons on rigid body mapping panel
# RB_Unmap {bodnum args}                writes panel for unmapping rigid body
# RB_unmap_delete {panel bodnum args}   unmaps rigid body
# RB_Edit_Matrix {bodnum args}          build edit matrix panel
# RB_Sort_Inc {bodnum dir args}         sort routine for edit matrix panel (dir = inc or dec)
# RB_String_Reverse {string args}       reverses the order or elements in a string
# RB_Matrix_Update {bodnum args}        updates the information in the edit matrix panel
# proc RB_View_Parameters {phase x y args} not used at this time.
# proc GetImportFormats {}              locates the file formats for rigid body creation panel not used at this time
# MakeRBPane {}                         called to initialize pane in notebook
# NewBodyTypeWindow                      build new rigid body save panel
# RB_Fixfrag_Load {args}                build panel for generating rigid bodies from exp file
# RB_FixFragSaveCoord {args}            build rigid body from information on rigid bodies from exp panel
# RB_FixStartAtom {phase gdisplay gcon2 args}
# RB_Atom_Fixlist {phase gdisplay}
# RB_Atom_Origin_Set {args}
# RB_Geom_Save {args}
# RB_Refine_Con {args}                  sets matrix to set refinement constrols
# RB_Variable_Clear {}
# RB_Con_But_Proc {addresses change args}
# RB_Con_Button {address args}
# RB_Var_Gen {varcount args}
# RB_Var_Assign {args}                   assigns variable numbers to refinement parameters
# RB_Ref_FlagEnable {phasenum bodnum mapnum var val args}
# RB_Var_Save {args}
# RB_TLS_Onoff {phasenum main bodnum mapnum}
# RB_Load_Vars {phasenum bodnum mapnum args}
# RB_VarSet {varin mulvarlist args}
# RB_New_RBnum {args}
# RB_CartesianTextFile {bodnum args}



# Important Global variable list:
#          ::rbtypelist                               variable that contains RB file format types.
#          ::rb_map(bodnum)                           number of times rigid body is mapped.
#          ::rb_matrix_num(bodnum)                    number of matrices in rigid body.
#          ::rb_mult(bodnum,matrixnum)                multiplier for matrix.
#          ::rb_damp(bodnum,matrixnum)                damping factor for matrix multiplier.
#          ::rb_var(bodnum,matrixnum)                 variable id for matrix multiplier.
#          ::rb_coord_num(bodnum,matrixnum)           number of coordinates associated with matrix.
#          ::rb_coord(bodnum,matrixnum,coord)         coordinate list
#          ::rb_x(bodnum,matrixnum,coordnum)          x coordinate
#          ::rb_y(bodnum,matrixnum,coordnum)          y coordinate
#          ::rb_z(bodnum,matrixnum,coordnum)          z coordinate
#          ::rb_lbl(bodnum,matrixnum,coordnum)        label for coordinate triplet
#          ::rb_map_beginning(phase,bodnum,mapnum)    first atom in list
#          ::rb_map_origin(phase,bodnum,mapnum)       origin of rigid body
#          ::rb_map_euler(phase,bodnum,mapnum)        euler angles of rigid body
#          ::rb_map_positions(phase,bodnum,mapnum)    positions
#          ::rb_map_damping(phase,bodnum,mapnum)      damping
#          ::rb_map_tls(phase,bodnum,mapnum)          tls
#          ::rb_map_tls_var(phase,bodnum,mapnum)      tls variable id number
#          ::rb_map_tls_damp(phase,bodnum,mapnum)     tls damping factor
#          ::rb_notebook                              contains address of rigid body notebook
#          ::rb_firstatom                             contains first atom on active rigid body.  Must be gobal for variable has trace.
#$         ::rb_phase                                 phase for active map
#          ::rb(phase,bodnum,mapnum,x)                origin x coord
#          ::rb(phase,bodnum,mapnum,y)                origin y coord
#          ::rb(phase,bodnum,mapnum,z)                origin z coord
#          ::rb(phase,bodnum,mapnum,e1)               euler angle 1
#          ::rb(phase,bodnum,mapnum,e2)               euler angle 2
#          ::rb(phase,bodnum,mapnum,e3)               euler angle 3


# debug code to load test files when run as an independent script
if {[array name expgui shell] == ""} {
    lappend auto_path c:/gsas/expgui
    package require Tk
    package require BWidget
    set expgui(debug) 1
    #package require La
    #namespace import La::*
    source c:/gsas/sandboxexpgui/readexp.tcl
    source c:/gsas/sandboxexpgui/gsascmds.tcl
    # test code (package already loaded in expgui)
    lappend auto_path [file dirname [info script]]
    source C:/gsas/sandboxexpgui/rb.tcl
#    puts beforeread
    expload c:/crystals/expgui/rigid/rb6norb.exp
    mapexp
#    puts after
} else {
    source [file join $expgui(scriptdir) rb.tcl]
}
package require La

# Procedure to determine possible RB file formats available

set rbtypelist ""
proc RB_Import_Data_Type {args} {
    global expgui tcl_platform
    # only needs to be done once
    if {$::rbtypelist != ""} return

    set ::rbtypelist [glob -nocomplain [file join $expgui(scriptdir) rbimport_*.tcl]]
    if {$::rbtypelist == ""} {
	MyMessageBox -parent . -title "Installation error" -icon warning \
            -message "No rigid body import routines were found.\nSomething is wrong with the EXPGUI installation"
        set ::rbtypelist " "
    }
    foreach file $::rbtypelist {
        source $file
    }
}

#global variables generated by RB_Load
#
#
#          ::rb_map(bodnum)                   number of times rigid body is mapped.
#          ::rb_matrix_num(bodnum)            number of matrices in rigid body.
#          ::rb_mult(bodnum,matrixnum)        multiplier for matrix.
#          ::rb_damp(bodnum,matrixnum)        damping factor for matrix.
#          ::rb_var(bodnum,matrixnum)         variable for matrix.
#          ::rb_coord_num(bodnum,matrixnum)   number of coordinates associated with matrix.
#          ::rb_coord(bodnum,matrixnum,coord) coordinates
#          ::rb_x(bodnum,matrixnum,coordnum)  x coordinate
#          ::rb_y(bodnum,matrixnum,coordnum)  y coordinate
#          ::rb_z(bodnum,matrixnum,coordnum   z coordinate
#          ::rb_lbl(bodnum,matrixnum,coordnum label for coordinate triplet

proc RB_Load_RBdata {args} {
    catch {unset ::rb}
    #Loop over the rigid body types in EXP file
    foreach bodnum [RigidBodyList] {
             set rb($bodnum) [ReadRigidBody $bodnum]
             #Set the number of times rigid body is mapped.
             set ::rb_map($bodnum) [lindex $rb($bodnum) 0]
             #define the matrices
             set rb_mat [lindex $rb($bodnum) 1]
             set ::rb_matrix_num($bodnum) [llength $rb_mat]
             for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
                 set temp [lindex $rb_mat [expr $matrixnum - 1]]
                 set ::rb_mult($bodnum,$matrixnum) [lindex $temp 0]
                 set ::rb_damp($bodnum,$matrixnum) [lindex $temp 1]
                 set ::rb_var($bodnum,$matrixnum)  [lindex $temp 2]
                 if {$::rb_var($bodnum,$matrixnum) == 0} {
                    set ::rb_varcheck($bodnum,$matrixnum) 0
                 } else {
                    set ::rb_varcheck($bodnum,$matrixnum) 1
                 }
#                 puts "in RB_Load_RBdata ::rb_damp = $::rb_damp($bodnum,$matrixnum)"
                 set coords [lindex $temp 3]
                 set ::rb_coord_num($bodnum,$matrixnum) [llength $coords]
                 #load all coordniate information for matrix matrixnum
                 for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,$matrixnum)} {incr coordnum} {
                     set ::rb_coord($bodnum,$matrixnum,$coordnum) [lindex $coords $coordnum]
                     set ::rb_x($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 0]
                     set ::rb_y($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 0]
                     set ::rb_z($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 0]
                     set ::rb_lbl($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 0]
#                    restore values                     
                     set ::rb_matrix_num_temp($bodnum) $::rb_matrix_num($bodnum)
                     set ::rb_coord_num_temp($bodnum,1) $::rb_coord_num($bodnum,1)
                     set ::rb_coord_temp($bodnum,$matrixnum,$coordnum) $::rb_coord($bodnum,$matrixnum,$coordnum)

                 }
             }
     }
}

############################################
#           ::rb_map_beginning(phase,bodnum,mapnum)   first atom in list
#           ::rb_map_origin(phase,bodnum,mapnum)      origin of rigid body
#           ::rb_map_euler(phase,bodnum,mapnum)       euler angles of rigid body
#           ::rb_map_positions(phase,bodnum,mapnum)   positions
#           ::rb_map_damping(phase,bodnum,mapnum)     damping
#           ::rb_map_tls(phase,bodnum,mapnum)         tls
#           ::rb_map_tls_var(phase,bodnum,mapnum)
#           ::rb_map_tls_damp(phase,bodnum,mapnum)
proc RB_Load_Mapdata {phase bodnum mapnum} {
     set rb_map [ReadRigidBodyMapping $phase $bodnum $mapnum]
     set ::rb_map_beginning($phase,$bodnum,$mapnum) [lindex $rb_map 0]
     set ::rb_map_origin($phase,$bodnum,$mapnum) [lindex $rb_map 1]
     set ::rb_map_euler($phase,$bodnum,$mapnum) [lindex $rb_map 2]
     set ::rb_map_positionvars($phase,$bodnum,$mapnum) [lindex $rb_map 3]
     set ::rb_map_damping($phase,$bodnum,$mapnum) [lindex $rb_map 4]

     set ::rb_damp_origin [lindex $::rb_map_damping($phase,$bodnum,$mapnum) 6]
     set ::rb_damp_euler [lindex $::rb_map_damping($phase,$bodnum,$mapnum) 0]

     set ::rb_map_tls($phase,$bodnum,$mapnum) [lindex $rb_map 5]
     set ::rb_map_tls_var($phase,$bodnum,$mapnum) [lindex $rb_map 6]
     set ::rb_map_tls_damp($phase,$bodnum,$mapnum) [lindex $rb_map 7]
     
     set ::rb_damp_t [lindex $::rb_map_tls_damp($phase,$bodnum,$mapnum) 0]
     set ::rb_damp_l [lindex $::rb_map_tls_damp($phase,$bodnum,$mapnum) 1]
     set ::rb_damp_s [lindex $::rb_map_tls_damp($phase,$bodnum,$mapnum) 2]
}

#############################################
#   rcb     .a               initial rigid body control panel.
#   panelnum                 the notebook panel to be accessed.
#::rb_notebook              the notebook containing all rigid body panels.

proc RB_Control_Panel {panelnum args} {
     #set rcb .a
     #destroy $rcb
     #catch {toplevel $rcb} err
     set rcb $::expgui(rbFrame)
     eval destroy [winfo children $rcb]
     #wm title $rcb "Rigid Body Control Panel"
     #wm geometry $rcb 700x600+10+10
     set rb_nb $rcb.nb

     # Enable NoteBook from BWidget package

     set ::rb_notebook [NoteBook $rb_nb -side bottom]
     # loop over rigid body types, create notebook pages
     set pagelist {}

     # add create rigid body page and populate page
     $::rb_notebook insert 0 rb_body0 -text "Create Rigid Body" \
     -raisecmd "RB_Create"
     lappend pagelist rb_body0


     foreach bodnum [RigidBodyList] {
         $::rb_notebook insert $bodnum rb_body$bodnum -text "Rigid Body Type $bodnum"  \
         -raisecmd "RB_Populate $::rb_notebook $bodnum"
	lappend pagelist rb_body$bodnum
     }

    # grid notebook
    grid $::rb_notebook -sticky news -column 0 -row 1 -columnspan 2
    grid columnconfig $rcb 1 -weight 1
    grid rowconfig    $rcb 1 -weight 1
    $::rb_notebook raise [lindex $pagelist $panelnum]
}

############################################
# Procedure to create new rigid body

proc RB_Create {args} {
     RB_Import_Data_Type
     $::rb_notebook raise [$::rb_notebook page 0]
     #sets the new rigidbody number
     set bodnum [expr [llength [RigidBodyList]] + 1]
     #sets the phase list
     set phase $::expmap(phaselist)
     set pane [$::rb_notebook getframe rb_body0]
     eval destroy [winfo children $pane]
     set con0 $pane.con0
     #set con1 $pane.con1
     #set con2 $pane.con2
     #set con3 $pane.con3

     #initialize matrix number, multiplier and number of coordinates
     set ::rb_matrix_num($bodnum) 1
     set ::rb_mult($bodnum,1) 1.000

     if {[info vars ::rb_coord_num($bodnum,1)] == ""} {set ::rb_coord_num($bodnum,1) 1}

     #set check variables to see if number of matricies or coordinates incremented.
     set ::rb_mat_num_check 0
     set ::rb_atom_num_check 0

     #building rigid body creation frames
     pack [frame $con0 -bd 2 -relief groove] -side top -pady 10

     set ::rb_loader(manual) NewBodyTypeWindow
     set ::rb_descriptor(manual) "Manual Input"


     set filedescriptors ""
     set filearray [array names ::rb_descriptor]
     foreach file $filearray {
             lappend filedescriptors $::rb_descriptor($file)
     }

     set filecount 0
     set ::rb_file_loader "Choose Method"
     grid [label $con0.lbl -text "How are rigid body coordinates \n to be entered?"] -row 0 -column 0 -sticky ns
     set menu [eval tk_optionMenu $con0.filematrix ::rb_file_loader $filedescriptors]
         foreach file $filearray {
                 $menu entryconfig $filecount -command "eval $::rb_loader($file)"
                 incr filecount
         }
     $con0.filematrix configure -width 50
     grid $con0.filematrix -row 0 -column 1

}

############################################################
#procedure to create tables of cartesian coordinates

proc RB_Create_Cart {bodnum location args} {
     if {$::rb_matrix_num($bodnum) == $::rb_mat_num_check && $::rb_coord_num($bodnum,1) == $::rb_atom_num_check} {return}
     if {[catch {expr $::rb_matrix_num($bodnum)}] == 1 || [catch {expr $::rb_coord_num($bodnum,1)}] == 1} {return}
     if {$::rb_matrix_num($bodnum) != int($::rb_matrix_num($bodnum)) || $::rb_coord_num($bodnum,1) != int($::rb_coord_num($bodnum,1)) } {return}
     eval destroy [winfo children $location]
     foreach {top main side lbl} [MakeScrollTable $location] {}
     set ::rb_atom_num_check $::rb_coord_num($bodnum,1)
     set ::rb_mat_num_check $::rb_matrix_num($bodnum)
     set col 0
     grid [label $top.multilbl -text "Matrix Multiplier"] -row 1 -column 0
#     grid [label $top.damplbl -text "Damping Factor"] -row 2 -column 0
     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
          grid [label $top.matlbl$matrixnum -text "Matrix $matrixnum"] -row 0 -column [expr $col + 2]
          grid [entry $top.multi$matrixnum -textvariable ::rb_mult($bodnum,$matrixnum) -width 7 -takefocus 1] -row 1 -column [expr $col +2]
#          puts "in RB_Create_Cart damp = $::rb_damp($bodnum,$matrixnum)"

#          set dampfactors "0 1 2 3 4 5 6 7 8 9"
#          eval tk_optionMenu $top.damp$matrixnum ::rb_damp($bodnum,$matrixnum) $dampfactors
#          grid $top.damp$matrixnum -row 2 -column [expr $col +2]
#          $top.damp$matrixnum config -width 4


#          grid [entry $top.damp$matrixnum -textvariable ::rb_damp($bodnum,$matrixnum) -width 7 -takefocus 1] -row 2 -column  [expr $col +2]


          if {$::rb_mult($bodnum,$matrixnum) == ""} {set ::rb_mult($bodnum,$matrixnum) 1.000}
#          if {$::rb_damp($bodnum,$matrixnum) == ""} {set ::rb_damp($bodnum,$matrixnum) 0}

          grid [label $main.x$matrixnum -text "X"] -row 0 -column [expr $col + 1]
          grid [label $main.y$matrixnum -text "Y"] -row 0 -column [expr $col + 2]
          grid [label $main.z$matrixnum -text "Z"] -row 0 -column [expr $col + 3]
          grid [label $main.b$matrixnum -text "    "] -row 0 -column [expr $col +4]
          incr col 4
     }

     for {set coordnum 0} {$coordnum <= [expr $::rb_coord_num($bodnum,1) - 1]} {incr coordnum} {
          grid [label $main.lbl$coordnum -text "Site [expr $coordnum + 1]"] -row [expr $coordnum+10] -column 0
          set col 0
          for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
              grid [entry $main.x($matrixnum,$coordnum) -textvariable ::rb_x($bodnum,$matrixnum,$coordnum) -width 8 -takefocus 1] -row [expr $coordnum+10] -column [expr $col + 1]
              if {$::rb_x($bodnum,$matrixnum,$coordnum) == ""} {set ::rb_x($bodnum,$matrixnum,$coordnum) 0}
              grid [entry $main.y($matrixnum,$coordnum) -textvariable ::rb_y($bodnum,$matrixnum,$coordnum) -width 8 -takefocus 1] -row [expr $coordnum+10] -column [expr $col + 2]
              if {$::rb_y($bodnum,$matrixnum,$coordnum) == ""} {set ::rb_y($bodnum,$matrixnum,$coordnum) 0}
              grid [entry $main.z($matrixnum,$coordnum) -textvariable ::rb_z($bodnum,$matrixnum,$coordnum) -width 8 -takefocus 1] -row [expr $coordnum+10] -column [expr $col + 3]
              if {$::rb_z($bodnum,$matrixnum,$coordnum) == ""} {set ::rb_z($bodnum,$matrixnum,$coordnum) 0}
              grid [label $main.b($matrixnum,$coordnum) -text "    "] -row [expr $coordnum+10]  -column [expr $col +4]
              incr col 4
          }
          ResizeScrollTable $location
     }
}
########################################################
# Procedure to save new rigid body to EXP file.

proc RB_Create_Save {bodnum args} {
     set temp_mat ""
     set temp_car ""
     set temp_mat_group ""
     set temp_car_group ""
     set total ""
#     puts $::::rb_coord_num($bodnum,1)
     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
         lappend temp_mat $::rb_mult($bodnum,$matrixnum)
     }

     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
         for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,1)} {incr coordnum} {
                  set temp_cart_triplet "$::rb_x($bodnum,$matrixnum,$coordnum) $::rb_y($bodnum,$matrixnum,$coordnum) $::rb_z($bodnum,$matrixnum,$coordnum)"
                  lappend temp $temp_cart_triplet
         }
         lappend temp_car $temp
     }
#     puts "sites: $::rb_coord_num($bodnum,1)"
#     puts "matrix multiplier:  $temp_mat"
#     puts "cartesian coords:   $temp_car"
     AddRigidBody $temp_mat $temp_car
    RecordMacroEntry "AddRigidBody $temp_mat [list $temp_car]" 0
    RecordMacroEntry "incr expgui(changed)" 0
     incr ::expgui(changed)
     destroy .nbt
     RB_Load_RBdata
     RB_Control_Panel $bodnum
}

###################################################
# Procedures to delete rigid bodies

proc RB_Delete_Body {bodnum location args} {
     destroy $location.delete
     set really $location.delete
     toplevel $really
     putontop $really
     wm title $really "Delete Rigid Body"
     grid [label $really.lbl -text "Confirm \n Is rigid body $bodnum to be deleted?"] -row 0 -column 0 -columnspan 2 -pady 15
     grid [button $really.save -text "Delete" -bg red -command "RB_Delete_Body_Confirm $bodnum $location.delete"] \
          -row 1 -column 0 -padx 5 -pady 5
     grid [button $really.abort -text "Abort" -bg green -command "RB_Populate $::rb_notebook $bodnum; \
     $::rb_notebook raise rb_body$bodnum"] -row 1 -column 1 \
          -padx 5 -pady 5
}

proc RB_Delete_Body_Confirm {bodnum location args} {

 #   unmap all instances of the rigid body
     foreach phase $::expmap(phaselist) {
             foreach mapnum [RigidBodyMappingList $phase $bodnum] {
                     UnMapRigidBody $phase $bodnum $mapnum
                     RecordMacroEntry "UnMapRigidBody $phase $bodnum $mapnum" 0
             }
     }
#    puts "delete rigid body number $bodnum"
     DeleteRigidBody $bodnum
     RecordMacroEntry "DeleteRigidBody $bodnum" 0
#    puts "destroy location $location"
     destroy $location
#    increment expgui
     incr ::expgui(changed)
    RecordMacroEntry "incr expgui(changed)" 0
     RB_Load_RBdata
     RB_Control_Panel 0
}

############################################################
# Procedure to populate notebook pages

proc RB_Populate {rb_notebook bodnum args} {
     RB_Load_RBdata
     set ::rb_panel $bodnum
     set phaselist $::expmap(phaselist)
     # set notebook frame
     set pane [$rb_notebook getframe rb_body$bodnum]
     eval destroy [winfo children $pane]
     set con $pane.con
     grid [frame $con -bd 2 -relief groove] -row 0 -column 1 -pady 10

     #Rigid body mapping control panel along with matrix multipliers and damping factor labels
    set n [lindex [ReadRigidBody $bodnum] 0]
    if {$n == 0} {
        set str "(not mapped)"
    } elseif {$n == 1} {
        set str "(mapped 1 time)"
    } else {
        set str "(mapped $n times)"
    }
     grid [label  $con.rb_num -text "Rigid Body Type $bodnum\n$str"] -row 0 -column 0 -padx 5 -pady 5
     grid [button $con.rb_newmap -text "Map Body $bodnum" -command "RB_Map_New $bodnum" -width 18] -row 0 -column 1 -padx 5 -pady 5
     grid [button $con.rb_unmap -text "Unmap Body $bodnum" -command "RB_Unmap $bodnum" -width 18] -row 0 -column 2 -padx 5 -pady 5
     button $con.rb_delete -text "Delete Body $bodnum" -command "RB_Delete_Body $bodnum $con.rb_delete" -width 18
     grid   $con.rb_delete -row 4 -column 2 -padx 5 -pady 5

     grid [label $con.rb_mlbl1 -text "Matrix"] -row 1 -column 0
     grid [label $con.rb_mlbl2 -text "Multiplier"] -row 2 -column 0
     grid [label $con.rb_mlbl3 -text "Damping Factor"] -row 3 -column 0
     grid [button $con.plot -text "Plot Rigid Body" -command "PlotRBtype $bodnum" -width 18] -row 4 -column 0

     set matrixnum 0
     for {set mnum 1} {$mnum <= $::rb_matrix_num($bodnum)} {incr mnum} {
        incr matrixnum
        grid [label $con.rb_mm$mnum   -text "$mnum"]                -row 1 -column $matrixnum
        grid [label $con.rb_mult$mnum -text "$::rb_mult($bodnum,$mnum)"] -row 2 -column $matrixnum
        grid [label $con.rb_damp$mnum -text "$::rb_damp($bodnum,$mnum)"] -row 3 -column $matrixnum
     }

     button $con.rb_vmatrix -text "Edit Matrix" -command "RB_Edit_Matrix $bodnum" -width 18
     grid   $con.rb_vmatrix -row 4 -column 1 -padx 5 -pady 5
     grid [button $con.refine -text "Refinement \n Controls" -command "RB_Refine_Con" -width 18 ] -row 5 -column 1

     # create header for mapping data
     foreach {top main side lbl} [MakeScrollTable $pane] {}
     grid [label $main.rb_origin -text "Origin"] -row 0 -column 3 -columnspan 3
     grid [label $main.rb_euler -text "Euler Angles"] -row 0 -column 6 -columnspan 3
     grid [label $main.rb_site -text "Sites"] -row 0 -column 10 -columnspan 3
     grid [label $main.rb_ref -text "Phase"] -row 1 -column 2
     grid [label $main.rb_map -text "Map"] -row 1 -column 1
     grid [label $main.rb_x   -text "x"] -row 1 -column 3
     grid [label $main.rb_y   -text "y"] -row 1 -column 4
     grid [label $main.rb_z   -text "z"] -row 1 -column 5
     grid [label $main.rb_euler_x -text "R1"] -row 1 -column 6
     grid [label $main.rb_euler_y -text "R2"] -row 1 -column 7
     grid [label $main.rb_euler_z -text "R3"] -row 1 -column 8
     set col 11
     for {set coordnum 1} {$coordnum <= $::rb_coord_num($bodnum,1)} {incr coordnum} {
        label $main.rb_site$coordnum -text "$coordnum"
        grid $main.rb_site$coordnum -row 1 -column $col -padx 5
        incr col
     }

     # populate mapping data table
     set row 2
     foreach phase $phaselist {
             incr row
	     foreach mapnum [RigidBodyMappingList $phase $bodnum] {
                      set row [expr $row + $mapnum]
                      RB_Load_Mapdata $phase $bodnum $mapnum
                      grid [label $main.rb_map$phase$mapnum -text "$mapnum"] -row $row -column 1
                      grid [label $main.rb_cb$phase$mapnum -text $phase] -row $row -column 2
                      set origin $::rb_map_origin($phase,$bodnum,$mapnum)

                      grid [label $main.rb_x$phase$mapnum   -text "[format %1.3f [lindex $origin 0]]"] -row $row -column 3 -padx 5
                      grid [label $main.rb_y$phase$mapnum   -text "[format %1.3f [lindex $origin 1]]"] -row $row -column 4 -padx 5
                      grid [label $main.rb_z$phase$mapnum   -text "[format %1.3f [lindex $origin 2]]"] -row $row -column 5 -padx 5
                      set euler $::rb_map_euler($phase,$bodnum,$mapnum)
                      for {set j 0} {$j < 3} {incr j} {
                                  set euler1 [lindex $euler $j]
                                  set angle  [lindex $euler1 0]
                                  set axis   [lindex $euler1 1]
                                  label $main.rb_euler_$phase$mapnum$axis -text "[format %1.2f $angle]"
                      }

                      grid [label $main.rb_tls$phase$mapnum -text "     "] -row $row -column 9
                      set q 1
                      grid $main.rb_euler_$phase$mapnum$q -row $row -column 6  -padx 5
                      set q 2
                      grid $main.rb_euler_$phase$mapnum$q -row $row -column 7 -padx 5
                      set q 3
                      grid $main.rb_euler_$phase$mapnum$q -row $row -column 8 -padx 5
                      set col 11
                      set atomnum $::rb_map_beginning($phase,$bodnum,$mapnum)
                 # get a list of the atoms in the RB
                 set st [lsearch $::expmap(atomlist_$phase) $atomnum]
                 set en [expr {$st+$::rb_coord_num($bodnum,1)-1}]
                 set atoms [lrange $::expmap(atomlist_$phase) $st $en]
                 foreach a $atoms {
                     set lbl [atominfo $phase $a label]
                     grid [label $main.rb_site$phase$mapnum$a -text $lbl] -row $row -column $col -padx 5
                     incr col
                 }
             }
     incr row
     }
     ResizeScrollTable $pane
}

proc DisplayRB {} {     ;# called each time the panel is raised
    eval destroy [winfo children $::expgui(rbFrame)]
     RB_Load_RBdata
     RB_Control_Panel 0
    #label $::expgui(rbFrame).l -text "RB Parameters"
    #grid $::expgui(rbFrame).l -column 1 -row 1
    ResizeNotebook
}

proc MakeRBPane {} {     ;# called to create the panel intially
#    label $::expgui(rbFrame).l -text "RB Parameters"
#    grid $::expgui(rbFrame).l -column 1 -row 1
#    ResizeNotebook
}

#######################################################################
# New Mapping Event
# not updated

proc RB_Map_New {bodnum args} {
    catch {unset ::rb_firstatom}
    set ::rb_firstatom ""
    set ::body_type $bodnum
    catch {destroy .newmap}
    set nm .newmap
    toplevel $nm
    putontop $nm
    wm title $nm "Map Rigid Body #$bodnum"

    foreach item [trace vinfo ::rb_phase] {
            eval trace vdelete ::rb_phase $item
    }

    set ::rb_phase [lindex $::expmap(phaselist) 0]
    set nmap [expr $::rb_map($bodnum) + 1]
    eval tk_optionMenu $nm.pinput ::rb_phase $::expmap(phaselist)
    grid [label $nm.phase -text "Phase: "] -row 3 -column 1
    grid [label $nm.f_atom -text "Choose first atom Number"] -row 4 -column 1
    grid [label $nm.origin -text "input origin in fractional coordinates: "] -row 6 -column 1
    grid [label $nm.euler -text "input Euler angles: "] -row 7 -column 1
    grid [entry $nm.finputm -textvariable ::rb_firstatom -width 8 -takefocus 1] -row 4 -column 2

    foreach item [trace vinfo ::rb_firstatom] {
            eval trace vdelete ::rb_firstatom $item
    }
    trace variable ::rb_firstatom w "RB_Atom_List \$::rb_phase \$::rb_firstatom $nm $bodnum"

    grid [button $nm.finput -text "list allowed" -command "RB_Choose_Atom $bodnum"] -row 4 -column 3
    grid [label $nm.o1l -text "x"] -row 5 -column 2
    grid [label $nm.o2l -text "y"] -row 5 -column 3
    grid [label $nm.o3l -text "z"] -row 5 -column 4

    set ::origin1 0
    set ::origin2 0
    set ::origin3 0
    set ::euler1 0
    set ::euler2 0
    set ::euler3 0

    grid [entry $nm.o1 -width 8 -textvariable ::origin1 -takefocus 1] -row 6 -column 2
    grid [entry $nm.o2 -width 8 -textvariable ::origin2 -takefocus 1] -row 6 -column 3
    grid [entry $nm.o3 -width 8 -textvariable ::origin3 -takefocus 1] -row 6 -column 4
    grid [entry $nm.e1 -width 8 -textvariable ::euler1 -takefocus 1] -row 7 -column 2
    grid [entry $nm.e2 -width 8 -textvariable ::euler2 -takefocus 1] -row 7 -column 3
    grid [entry $nm.e3 -width 8 -textvariable ::euler3 -takefocus 1] -row 7 -column 4

    grid $nm.pinput -row 3 -column 3

    grid [frame $nm.p] -row 8 -column 1 -columnspan 4 -sticky e
    grid [button $nm.p.fit -text "Fit rigid body to phase" -command "RB_FitBody2Coords $bodnum $nm; RB_View_RMS $nm"] -row 0 -column 1
    grid [button $nm.p.plot -text "Plot rigid body & phase" -command "RB_PlotStrBody $bodnum $nm"] -row 1 -column 1
    grid [label $nm.p.l -text "Bonds: "] -row 1 -column 2
    grid [entry $nm.p.e] -row 1 -column 3
    $nm.p.e delete 0 end
    $nm.p.e insert 0 "0.9-1.1, 1.3-1.6"

    grid [frame $nm.l] -row 9 -column 2 -columnspan 3
    grid [button $nm.l.s -text "map update" -width 12 -command {RB_Write_Map}] -column 1 -row 1
    grid [button $nm.l.q -text "Abort" -width 6 -command "destroy $nm"] -column 2  -row 1

    foreach item [trace vinfo ::rb_phase] {
            eval trace vdelete ::rb_phase $item
    }
    trace variable ::rb_phase w "RB_ProcessPhase $bodnum"
}

proc RB_View_RMS {address args} {
     set addrms $address.rms
     catch {destroy $addrms}
     grid [frame $addrms -bd 2] -row 5 -column 8 -columnspan 99 -rowspan 99
     set row 1

     grid [label $addrms.atomlbl -text "   atom"] -row 0 -column 0
     grid [label $addrms.rmslbl -text "\t rms"] -row 0 -column 1
     foreach i $::rb_atom_rms {
             set atom [lindex $i 0]
             set temp [lindex $i 1]
             set rms [format %.3f $temp]
             set id [string tolower $atom]
             grid [label $addrms.$id$row -text "   $atom"] -row $row -column 0
             grid [label $addrms.rms$id$row -text "\t $rms"] -row $row -column 1
             incr row
     }
}

###########################################################
# Procedure for choosing first atom during mapping event.
# not updated

proc RB_Choose_Atom {bodnum args} {
    set phase $::rb_phase
    # get the number of atoms in this type of body
    set natoms [llength [lindex [lindex [lindex [ReadRigidBody $bodnum] 1] 0] 3]]
    set atomlist [RigidStartAtoms $::rb_phase $natoms]
    if {[llength $atomlist] == 0} {
	RB_ProcessPhase $bodnum
	return
    }
     catch {destroy .chooseatom}
     set ca .chooseatom
     toplevel $ca
     wm title $ca "Choose Atom"
#     puts $atomlist
     foreach {top main side lbl} [MakeScrollTable $ca] {}
     set row 0
     set column 0
     foreach atom $atomlist {
        set label "[atominfo $phase $atom label] \($atom\)"
        button $main.$atom -text $label -command "set ::rb_firstatom $atom; destroy $ca"
        incr row
        if {$row > 5} {
           set row 1
           incr column
        }
      grid $main.$atom -row $row -column $column -padx 5 -pady 5
      }
      ResizeScrollTable $ca
      putontop $ca
      tkwait window $ca
      afterputontop
      raise .newmap
}

##########################################################
##########################################################

proc RB_FitBody2Coords {bodnum menu} {
    set warn ""
    foreach i {1 2 3} lbl {x y z} {
	if {[string trim [set ::euler$i]] == ""} {
	    set ::euler$i 0.0
	}
	if {[string trim [set ::origin$i]] == ""} {
	    set ::origin$i .0
	}
	if {[catch {expr [set ::euler$i]}]} {
	    append warn "\tError in Euler angle around $lbl\n"
	}
	if {[catch {expr [set ::origin$i]}]} {
	    append warn "\tError in origin $lbl\n"
	}
    }
    if {[catch {expr $::rb_firstatom}]} {
	append warn "\tError in 1st atom number\n"
    }
    if {$warn != ""} {
	MyMessageBox -parent $menu -title "Input error" \
		-message "Invalid input:\n$warn" -icon warning
	return
    }
    set Euler [list "1 $::euler1" "2 $::euler2" "3 $::euler3"]
    set origin "$::origin1 $::origin2 $::origin3"
    set phase $::rb_phase
    set cell {}
    foreach p {a b c alpha beta gamma} {
	lappend cell [phaseinfo $phase $p]
    }
    set coords [RB2cart [lindex [ReadRigidBody $bodnum] 1]]
    set natom [llength $coords]
    set firstind [lsearch $::expmap(atomlist_$phase) $::rb_firstatom]
    set atoms [lrange \
		   [lrange $::expmap(atomlist_$phase) $firstind end] \
		   0 [expr {$natom-1}]]
    # now loop over atoms
    set frcoords {}
    foreach atom $atoms {
	set xyz {}
	foreach v {x y z} {
	    lappend xyz [atominfo $phase $atom $v]
	}
	lappend frcoords $xyz
    }
    # it would be nice to have checkboxes for each atom, but for now use em all
    set useflags {}
    foreach i $coords {lappend useflags 1}
#    puts "frcoords $frcoords"
#    puts "coords $coords"
    # do the fit
    foreach {neworigin newEuler rmsdev newfrac rmsbyatom} \
	[FitBody $Euler $cell $coords $useflags $frcoords $origin] {}
    foreach i {1 2 3} val $neworigin pair $newEuler {
	set ::origin$i $val
	set ::euler$i [lindex $pair 1]
    }
    # show deviations

    set ::rb_atom_rms ""
    foreach atom $atoms rms $rmsbyatom {
#	puts "[atominfo $phase $atom label]\t$rms"
	lappend ::rb_atom_rms "[atominfo $phase $atom label] $rms"
    }
    #puts "CalcBody $Euler $cell $coords $origin"
    #puts $coords
    #puts $frcoords
    #DRAWxtlPlotRBFit $frcoords $phase $::rb_firstatom 0 $bondlist $bondlist
 }

proc RB_PlotStrBody {bodnum menu} {
    set warn ""
    foreach i {1 2 3} lbl {x y z} {
	if {[catch {expr [set ::euler$i]}]} {
	    append warn "\tError in Euler angle around $lbl\n"
	}
	if {[catch {expr [set ::origin$i]}]} {
	    append warn "\tError in origin $lbl\n"
	}
    }
    if {[catch {expr $::rb_firstatom}]} {
	append warn "\tError in 1st atom number\n"
    }
    if {$warn != ""} {
	MyMessageBox -parent $menu -title "Input error" \
		-message "Invalid input:\n$warn" -icon warning
	return
    }
    # translate bond list
    set bl [$menu.p.e get]
    regsub -all "," $bl " " bl
    set bondlist {}
    set warn ""
    foreach b $bl {
	if {[llength [split $b "-"]] == 2} {
	    lappend bondlist [split $b "-"]
	} else {
	    set warn "error parsing bond list"
	}
    }
    if {$warn != ""} {
	MyMessageBox -parent . -title "Input warning" \
		-message "Invalid bond input" -icon warning
    }
     set Euler [list "1 $::euler1" "2 $::euler2" "3 $::euler3"]
     set origin "$::origin1 $::origin2 $::origin3"
     set phase $::rb_phase
     set cell {}
     foreach p {a b c alpha beta gamma} {
	lappend cell [phaseinfo $phase $p]
    }
    set coords [RB2cart [lindex [ReadRigidBody $bodnum] 1]]
    set frcoords [CalcBody $Euler $cell $coords $origin]
    #puts "CalcBody $Euler $cell $coords $origin"
    #puts $coords
    #puts $frcoords
    DRAWxtlPlotRBFit $frcoords $phase $::rb_firstatom 0 $bondlist $bondlist
 }
#

proc RB_Write_Map {args} {
   if {$::rb_firstatom == ""} {
      MyMessageBox -title "warning" -message "The first atom for the rigid body must be choosen to update mapping"
      return
   }
   set origin "$::origin1 $::origin2 $::origin3"
   set euler "$::euler1 $::euler2 $::euler3"
#   puts "phase = $::rb_phase"
#   puts "bodnum = $::body_type"
#   puts "firstatom = $::rb_firstatom"
#   puts "position = $origin"
#   puts "Euler = $euler"
    MapRigidBody $::rb_phase $::body_type $::rb_firstatom $origin $euler
    RecordMacroEntry "MapRigidBody $::rb_phase $::body_type $::rb_firstatom [list $origin] [list $euler]" 0
   incr ::rb_map($::body_type)
   set curpage [$::rb_notebook raise]
   $::rb_notebook raise [$::rb_notebook page end]
   $::rb_notebook raise $curpage
   destroy .newmap
   RunRecalcRBCoords
   incr ::expgui(changed)
   RecordMacroEntry "incr expgui(changed)" 0
   RB_Populate $::rb_notebook $::body_type
   $::rb_notebook raise rb_body$::body_type
}

proc RB_Atom_List {phase atomnum address bodnum args} {
     foreach w [winfo children $address] {
             if {[string first ".atom" $w] != -1} {destroy $w}
     }
     set col 8
    if {$atomnum == ""} return
    grid [label $address.atomlbl -text "Atoms Mapped to Rigid Body"] -row 3 -column 8 -columnspan 99
    # get the number of atoms in this type of body
    set natoms [llength [lindex [lindex [lindex [ReadRigidBody $bodnum] 1] 0] 3]]
    set atoms [RigidStartAtoms $phase $natoms]
    if {[lsearch $atoms $atomnum] == -1} {
         grid [label $address.atomerr -text "(invalid 1st atom)"] -row 4 -column $col
	return
    }
    set atoms [lrange $::expmap(atomlist_$phase) \
		   [lsearch $::expmap(atomlist_$phase) $atomnum] end]
    foreach j [lrange $atoms 0 [expr {$natoms - 1}]] {
	set atom [atominfo $phase $j label]
	grid [label $address.atom$phase$bodnum$j -text $atom] -row 4 -column $col
	incr col
     }
}

proc RB_ProcessPhase {bodnum args} {
    if {$::rb_phase == ""} {
	set atoms {}
    } else {
	# get the number of atoms in this type of body
	set natoms [llength [lindex [lindex [lindex [ReadRigidBody $bodnum] 1] 0] 3]]

	set atoms [RigidStartAtoms $::rb_phase $natoms]
    }
    set nm .newmap
    if {[llength $atoms] == 0} {
	foreach w "$nm.finputm $nm.p.plot $nm.p.fit $nm.p.e $nm.l.s" {
	    $w config -state disabled
	}
	$nm.finput config -text "None allowed" -state disabled
    } else {
	foreach w "$nm.finputm $nm.p.plot $nm.p.fit $nm.p.e $nm.l.s" {
	    $w config -state normal
	}
	$nm.finput config -text "Show allowed" -state normal
    }
}

proc RB_Unmap {bodnum args} {
    catch {unset ::rb_firstatom}
    set ::rb_firstatom ""
    set ::body_type $bodnum
    catch {destroy .unmap}
    set um .unmap
    toplevel $um
    putontop $um
    wm title $um "Map Rigid Body #$bodnum"
    set ::phase 1
    set umap $::rb_map($bodnum)
#    eval tk_optionMenu $um.pinput ::rb_phase $::expmap(phaselist)
#    grid [label $um.phase -text "Phase: "] -row 3 -column 1
#    grid $um.pinput -row 3 -column 2

    set mapnumber $::rb_map($bodnum)
    set unpane $um.pane
    foreach {top main side lbl} [MakeScrollTable $um] {}
    grid [label $main.cb -text "unmap"] -row 1 -column 0 -padx 5
    grid [label $main.map -text "map"] -row 1 -column 1 -padx 5
    grid [label $main.ph -text "Phase"] -row 1 -column 2 -padx 5
    set matrixnum $::rb_matrix_num($bodnum)
    grid [label $main.rb_sitelbl -text "Site number"] -row 0 -column 3 -columnspan 5 -sticky w
    for {set coordnum 1} {$coordnum <= $::rb_coord_num($bodnum,$matrixnum)} {incr coordnum} {
        label $main.rb_site$coordnum -text "$coordnum"
        grid $main.rb_site$coordnum -row 1 -column [expr 2 + $coordnum]
    }
    set row 2
    foreach phase $::expmap(phaselist) {
        incr row
	foreach coordnum [RigidBodyMappingList $phase $bodnum] {
            set row [expr $row + $coordnum]
            RB_Load_Mapdata $phase $bodnum $coordnum
            checkbutton $main.unmap$phase$coordnum -variable ::rb_unmap($phase,$bodnum,$coordnum)
            grid $main.unmap$phase$coordnum -row $row -column 0
            grid [label $main.rb_map$phase$coordnum -text "$coordnum"] -row $row -column 1
            grid [label $main.rb_cb$phase$coordnum -text $phase] -row $row -column 2
            set atomnum $::rb_map_beginning($phase,$bodnum,$coordnum)
            # get a list of the atoms in the RB
            set st [lsearch $::expmap(atomlist_$phase) $atomnum]
            set en [expr {$st+$::rb_coord_num($bodnum,0)-1}]
            set atoms [lrange $::expmap(atomlist_$phase) $st $en]
            set col 3
            foreach a $atoms {
                set lbl [atominfo $phase $a label]
                grid [label $main.rb_site$phase$coordnum$col -text $lbl -padx 3] -row $row -column $col
                incr col
            }
        }
        incr row
    }
    ResizeScrollTable $um

     grid [frame $um.update -bd 2 -relief groove] -row 0 -column 1 -pady 10
     button $um.update.con -text "Update Rigid Body Mapping" -command "RB_unmap_delete $um $bodnum"
     button $um.update.abort -text "Abort" -command "destroy $um"
     grid $um.update.con -row 0 -column 0 -padx 5 -pady 5
     grid $um.update.abort -row 0 -column 1
     incr ::expgui(changed)

}

proc RB_unmap_delete {panel bodnum args} {
#     puts $panel
     foreach phase $::expmap(phaselist) {
        foreach mapnum [RigidBodyMappingList $phase $bodnum] {
                if {$::rb_unmap($phase,$bodnum,$mapnum) == 1} {
                   RecordMacroEntry "UnMapRigidBody $phase $bodnum $mapnum" 0
                   UnMapRigidBody $phase $bodnum $mapnum
                }
        }
        incr ::expgui(changed)
         RecordMacroEntry "incr expgui(changed)" 0
        destroy $panel
        set curpage [$::rb_notebook raise]
        RB_Populate $::rb_notebook $bodnum
        $::rb_notebook raise rb_body$bodnum
     }
}

proc RB_Create_from_Edit {args} {
     set bodnum [RB_New_RBnum]
     RB_Create_Save $bodnum
}



proc RB_Edit_Matrix {bodnum args} {
#     puts "Bodnum = $bodnum"
     catch {destroy .viewmatrix}
     set em .viewmatrix
     toplevel $em
     putontop $em
     wm title $em "Edit Matrices for Rigid Body $bodnum"

     set vm $em.entry
     set um $em.update
     set sm $em.sort
     grid [frame $vm -bd 2 -relief groove] -row 0 -column 0 -columnspan 2
     grid [frame $sm -bd 2 -relief groove] -row 1 -column 0 -columnspan 2 -pady 10
     grid [frame $um -bd 2 -relief groove] -row 2 -column 0 -columnspan 2

#    Editor Options
     grid [label $sm.title -text "Matrix Editor Control Panel"] -row 0 -column 0 -columnspan 4
     grid [label $sm.sort -width 21 -text "Move Checked Elements"] -row 1 -column 0
     grid [button $sm.inc -text "\u2191" -command "RB_Sort_Inc $bodnum inc"] -row 1 -column 1 -padx 5
     grid [button $sm.dec -text "\u2193" -command "RB_Sort_Inc $bodnum dec"] -row 1 -column 2 -padx 5
     grid [button $sm.swap -width 21 -text "Swap Checked Elements" -command "RB_Sort_Swap $bodnum"] -row 2 -column 0 -columnspan 3
     grid [button $sm.delete -width 21 -text "Delete Checked Elements" -command "RB_Delete_Element $bodnum"] -row 3 -column 0 -columnspan 3
     grid [button $sm.add   -width 21 -text "Increase Number of Sites" -command "RB_Add_Element $bodnum"] -row 4 -column 0 -columnspan 3
     grid [button $sm.addmatrix -width 21 -text "Add New Matrix" -command "RB_Add_New_Matrix $bodnum"] -row 5 -column 0 -columnspan 3

#    Save Options
     grid [button $um.update -width 24 -text "Save Changes" -bg green -command "RB_Matrix_Update $bodnum"] -row 3 -column 0 -padx 5
     grid [button $um.new -width 24 -text "Save Rigid Body Type" -command "RB_Create_from_Edit"] -row 0 -column 1 -padx 5
 #    grid [button $um.sort -text "Sort Matrix Info" -command "RB_Cart_Sort $bodnum"] -row 0 -column 1

     grid [button $um.print -width 24 -text "Export Cartesian \n Coordinates to File" -command "RB_CartesianTextFile $bodnum"] -row 2 -column 1 -pady 5
     grid [button $um.restore -width 24 -text "Undo Changes" -command "RB_Restore_Matrix $bodnum"] -row 3 -column 1 -padx 5
     grid [button $um.abort -text "Abort" -width 24 -command "RB_Edit_Matrix_Abort $bodnum $em"] -row 3 -column 2 -padx 5

     grid [label $vm.lblmm -text "Matrix Multiplier"] -row 3 -column 2
     grid [label $vm.lbldamp -text "Damping Factor"] -row 4 -column 2
     grid [label $vm.lblvar -text "Refine Multiplier"] -row 5 -column 2

     set w 1
     grid [label $vm.site -text "sort"] -row 6 -column 0 -columnspan 2


     for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,$w)} {incr coordnum} {
         grid [checkbutton $vm.sort$coordnum -variable ::rb_sort($coordnum)] -row [expr $coordnum + 7] -column 1
         grid [label $vm.lbls$coordnum -text "Site [expr $coordnum + 1]"] -row [expr $coordnum + 7] -column 2
     }
     set col 3
     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
         grid [label $vm.lblm$matrixnum -text "Matrix #$matrixnum"] -row 2 -column [expr $col +1]
         grid [entry $vm.mult$matrixnum -textvariable ::rb_mult($bodnum,$matrixnum) -width 8 -takefocus 1] -row 3 -column [expr $col + 1]
         set dampfactors "0 1 2 3 4 5 6 7 8 9"
         eval tk_optionMenu $vm.damp$matrixnum ::rb_damp($bodnum,$matrixnum) $dampfactors
         grid $vm.damp$matrixnum -row 4 -column [expr $col + 1]
         $vm.damp$matrixnum config -width 4
#         grid [entry $vm.damp$matrixnum -textvariable ::rb_damp($bodnum,$matrixnum) -width 8 -takefocus 1 -state normal] -row 4 -column [expr $col + 1]
         grid [checkbutton $vm.var$matrixnum -variable ::rb_varcheck($bodnum,$matrixnum) -text $::rb_var($bodnum,$matrixnum) \
              -state normal -command "RB_MMultRef $bodnum $matrixnum"] -row 5 -column [expr $col +1]

         grid [label $vm.x$matrixnum -text "X"] -row 6 -column [expr $col]
         grid [label $vm.y$matrixnum -text "Y"] -row 6 -column [expr $col + 1]
         grid [label $vm.z$matrixnum -text "Z"] -row 6 -column [expr $col + 2]
         for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,$w)} {incr coordnum} {
#             puts $::rb_coord($bodnum,$i,$j)

              set ::rb_x($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 0]
              set ::rb_y($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 1]
              set ::rb_z($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 2]
              set ::rb_lbl($bodnum,$matrixnum,$coordnum) [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 3]


             grid [entry $vm.lblcx$matrixnum$coordnum -textvariable ::rb_x($bodnum,$matrixnum,$coordnum) -width 8 -takefocus 1] -row [expr $coordnum+7] -column [expr $col]
             grid [entry $vm.lblcy$matrixnum$coordnum -textvariable ::rb_y($bodnum,$matrixnum,$coordnum) -width 8 -takefocus 1] -row [expr $coordnum+7] -column [expr $col + 1]
             grid [entry $vm.lblcz$matrixnum$coordnum -textvariable ::rb_z($bodnum,$matrixnum,$coordnum) -width 8 -takefocus 1] -row [expr $coordnum+7] -column [expr $col + 2]
             grid [label $vm.lblcb$matrixnum$coordnum -text "    "] -row [expr  $coordnum+6] -column [expr $col + 3]
         }
     incr col 4
     }
}

proc RB_Restore_Matrix {bodnum} {
     set ::rb_matrix_num($bodnum) $::rb_matrix_num_temp($bodnum)
     set ::rb_coord_num($bodnum,1) $::rb_coord_num_temp($bodnum,1)
         for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,1)} {incr coordnum} {
             for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
                 set ::rb_coord($bodnum,$matrixnum,$coordnum) $::rb_coord_temp($bodnum,$matrixnum,$coordnum)

             }
     }
RB_Edit_Matrix $bodnum
}

proc RB_Add_New_Matrix {bodnum} {
     incr ::rb_matrix_num($bodnum)
     set matrixnum $::rb_matrix_num($bodnum)
     set ::rb_var($bodnum,$matrixnum) 0
     set ::rb_mult($bodnum,$matrixnum) 1.000
     for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,1)} {incr coordnum} {
         set ::rb_coord($bodnum,$matrixnum,$::rb_coord_num($bodnum,1) ""
         lappend ::rb_coord($bodnum,$matrixnum,$coordnum) 0 0 0 lbl
     }
     RB_Edit_Matrix $bodnum


}

proc RB_Edit_Matrix_Abort {bodnum location} {
#    reset matrix
#     set ::rb_coord_num($bodnum,1) $::rb_coord_num_temp($bodnum,1)
#     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
#         for {set coordnum 0} {$coordnum < $::rb_coord_num_temp($bodnum,1)} {incr coordnum} {
#             set ::rb_coord($bodnum,$matrixnum,$coordnum) $::rb_coord_temp($bodnum,$matrixnum,$coordnum)
#         }
#     }
     destroy $location
}

proc RB_Add_Element {bodnum} {
     incr ::rb_coord_num($bodnum,1)
     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
         set ::rb_coord($bodnum,$matrixnum,$::rb_coord_num($bodnum,1) ""
         lappend ::rb_coord($bodnum,$matrixnum,[expr $::rb_coord_num($bodnum,1)- 1]) 0 0 0 lbl
         puts $::rb_coord($bodnum,$matrixnum,[expr $::rb_coord_num($bodnum,1) - 1])
     }
     RB_Edit_Matrix $bodnum
}

proc RB_Delete_Element {bodnum} {

     set newcoord 0
     set deletedrecords 0

     for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,1)} {incr coordnum} {
           for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {

               if {$::rb_sort($coordnum) != 1} {
                  set xtemp $::rb_x($bodnum,$matrixnum,$coordnum)
                  set ytemp $::rb_y($bodnum,$matrixnum,$coordnum)
                  set ztemp $::rb_z($bodnum,$matrixnum,$coordnum)
                  set lbltemp [lindex $::rb_coord($bodnum,$matrixnum,$coordnum) 3]


                  set ::rb_x($bodnum,$matrixnum,$newcoord) $xtemp
                  set ::rb_y($bodnum,$matrixnum,$newcoord) $ytemp
                  set ::rb_z($bodnum,$matrixnum,$newcoord) $ztemp
                  puts "array element = $::rb_coord($bodnum,$matrixnum,$coordnum)"
                  set ::rb_coord($bodnum,$matrixnum,$newcoord) ""
                  puts "xyztemp = $xtemp $ytemp $ztemp $lbltemp"
                  lappend ::rb_coord($bodnum,$matrixnum,$newcoord) $xtemp $ytemp $ztemp $lbltemp
                  puts "goofy output = $::rb_coord($bodnum,$matrixnum,$newcoord)"
                  incr newcoord
               } else {
                  incr deletedrecords
               }
           }
     }
     for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,1)} {incr coordnum} {
         set ::rb_sort($coordnum) 0
     }
     set tempcoord [expr $::rb_coord_num($bodnum,1) - $deletedrecords]
     set ::rb_coord_num($bodnum,1) $tempcoord
     RB_Edit_Matrix $bodnum
}



proc RB_VarNums {toggle {var ""} args} {
#    initalize rigid body variable list if not already initialized
#    toggle can be:
#           add      This returns the smallest unused variable number
#           sub ##   This removes variable ## from the varlist.

     if {[info vars ::rb_varlist] == ""} {
        set ::rb_varlist ""
     }
     if {$::rb_varlist == ""} {
          set ::rb_varlist [RigidBodyGetVarNums]
     }

     if {$toggle == "add"} {
          set count 1
          while {[lsearch $::rb_varlist $count] > 0} {
               incr count
          }
          lappend ::rb_varlist $count
#          puts $::rb_varlist
          return $count
     }
     if {$toggle == "sub"} {
          set temp ""
          foreach v $::rb_varlist {
                  if {$v != $var} {
                     lappend temp $v
                  }
          }
          set ::rb_varlist $temp
#          puts $::rb_varlist
          return 0
      }
}

proc RB_MMultRef {bodnum matrixnum args} {
#    procedure sets or unsets the variable number for the matrix multiplier
#     puts "boing:"
     if {$::rb_varcheck($bodnum,$matrixnum) == "0"} {
        set ::rb_var($bodnum,$matrixnum) [RB_VarNums sub $::rb_var($bodnum,$matrixnum)]
     } else {
        set ::rb_var($bodnum,$matrixnum) [RB_VarNums add]
     }
     destroy .viewmatrix
     RB_Edit_Matrix $bodnum
}

proc RB_Sort_Swap {bodnum args} {
     set count 0
     set rb_swap_list ""
     for {set coordnum 0} {$coordnum < $::rb_coord_num($bodnum,1)} {incr coordnum} {
         if {$::rb_sort($coordnum) == 1} {
            incr count
            lappend rb_swap_list $coordnum
         }
     }
     if {$count != 2} {
#        puts "wrong number of arguments, swap failed"
        bell
        return
     }
#     puts "swap happens"
#     puts $rb_swap_list
     for {set i 1} {$i <= $::rb_matrix_num($bodnum)} {incr i} {
         set coord1 [lindex $rb_swap_list 0]
         set coord2 [lindex $rb_swap_list 1]
         set x1dum $::rb_x($bodnum,$i,$coord1)
         set y1dum $::rb_y($bodnum,$i,$coord1)
         set z1dum $::rb_z($bodnum,$i,$coord1)
         set ::rb_x($bodnum,$i,$coord1) $::rb_x($bodnum,$i,$coord2)
         set ::rb_y($bodnum,$i,$coord1) $::rb_y($bodnum,$i,$coord2)
         set ::rb_z($bodnum,$i,$coord1) $::rb_z($bodnum,$i,$coord2)
         set ::rb_x($bodnum,$i,$coord2) $x1dum
         set ::rb_y($bodnum,$i,$coord2) $y1dum
         set ::rb_z($bodnum,$i,$coord2) $z1dum
     }

}

proc RB_Sort_Inc {bodnum dir args} {
     set sortlist ""
     for {set count 0} {$count < $::rb_coord_num($bodnum,1)} {incr count} {
         if {$::rb_sort($count) == 1} {
            lappend sortlist $count
         }
     }
#     puts $sortlist

     foreach check $sortlist {
             set checkup [expr $check - 1]
             set checkdwn [expr $check + 1]
             if {$checkup < 0} {
                if {$dir == "inc"} {
                   bell
                   return
                }
             }
             if {$checkdwn >= $::rb_coord_num($bodnum,1)} {
                if {$dir == "dec"} {
                   bell
                   return
                }
             }
     }
     if {$dir == "dec"} {set sortlist [RB_String_Reverse $sortlist]}

     for {set i 1} {$i <= $::rb_matrix_num($bodnum)} {incr i} {
         foreach sort $sortlist {
             if {$dir == "inc"} {set line1 [expr $sort - 1]}
             if {$dir == "dec"} {set line1 [expr $sort + 1]}
             set x1dum $::rb_x($bodnum,$i,$line1)
             set y1dum $::rb_y($bodnum,$i,$line1)
             set z1dum $::rb_z($bodnum,$i,$line1)
             set ::rb_x($bodnum,$i,$line1) $::rb_x($bodnum,$i,$sort)
             set ::rb_y($bodnum,$i,$line1) $::rb_y($bodnum,$i,$sort)
             set ::rb_z($bodnum,$i,$line1) $::rb_z($bodnum,$i,$sort)
             set ::rb_x($bodnum,$i,$sort) $x1dum
             set ::rb_y($bodnum,$i,$sort) $y1dum
             set ::rb_z($bodnum,$i,$sort) $z1dum

             set ::rb_sort($sort) 0
             if {$dir == "inc"} {set ::rb_sort([expr $sort - 1]) 1}
             if {$dir == "dec"} {
                foreach relabel $sortlist {
                    set ::rb_sort([expr $relabel +1]) 1
                }
             }
        }
     }

}

proc RB_String_Reverse {string args} {
#    puts "$string"
    set rstring ""
    set len [expr [llength $string] - 1]
    while {$len > -1} {
        lappend rstring [lindex $string $len]
        incr len -1
    }
#    puts "contents of rstring = $rstring"
    return $rstring
}

proc RB_Matrix_Update {bodnum args} {
     set temp_mat ""
     set temp_damp ""
     set temp_var ""
     set temp_car ""
     set temp_mat_group ""
     set temp_car_group ""
     set total ""

     for {set matrixnum 1} {$matrixnum <= $::rb_matrix_num($bodnum)} {incr matrixnum} {
         set temp ""
         lappend temp_mat $::rb_mult($bodnum,$matrixnum)
         lappend temp_var $::rb_var($bodnum,$matrixnum)
         lappend temp_damp $::rb_damp($bodnum,$matrixnum)
#         puts "temp_damp = $::rb_damp($bodnum,$matrixnum)"
         for {set atomnum 0} {$atomnum < $::::rb_coord_num($bodnum,1)} {incr atomnum} {
             set temp_cart_triplet "$::rb_x($bodnum,$matrixnum,$atomnum) $::rb_y($bodnum,$matrixnum,$atomnum) $::rb_z($bodnum,$matrixnum,$atomnum)"
             lappend temp $temp_cart_triplet
         }
         lappend temp_car $temp
     }

#     puts "Matrix Update Info = $bodnum $temp_mat $temp_car"
#     puts "Matrix damping = $temp_damp"
#     puts "Matrix vars = $temp_var"
     SetRigidBodyVar $bodnum $temp_var $temp_damp
    RecordMacroEntry "SetRigidBodyVar $bodnum [list $temp_var] [list $temp_damp]" 0
     ReplaceRigidBody $bodnum $temp_mat $temp_car $temp_var $temp_damp
    RecordMacroEntry "ReplaceRigidBody $bodnum [list $temp_mat] [list $temp_car] [list $temp_var] [list $temp_damp]" 0
     #SetRigidBodyVar $bodnum $temp_var $temp_damp
     incr ::expgui(changed)
    RecordMacroEntry "incr expgui(changed)" 0
     RB_Load_RBdata
     RB_Control_Panel $bodnum
     destroy .viewmatrix

}


proc GetImportFormats {} {
    global expgui tcl_platform
    # only needs to be done once
    if [catch {set expgui(importFormatList)}] {
	set filelist [glob -nocomplain [file join $expgui(scriptdir) import_*.tcl]]
	foreach file $filelist {
	    set description ""
	    source $file
	    if {$description != ""} {
		lappend expgui(importFormatList) $description
		if {$tcl_platform(platform) == "unix"} {
		    set extensions "[string tolower $extensions] [string toupper $extensions]"
		}
		set expgui(extensions_$description) $extensions
		set expgui(proc_$description) $procname
	    }
	}
    }
}

proc NewBodyTypeWindow {} {
     destroy .nbt
     toplevel .nbt
     putontop .nbt
     set con1 .nbt.1
     set con2 .nbt.2
     set con3 .nbt.3

     set bodnum [RB_New_RBnum]
#     set bodnum [expr [llength [RigidBodyList]] + 1]
     pack [frame $con1 -bd 2 -relief groove] -side top -pady 10
     pack [frame $con2 -bd 2 -relief groove] -side top -expand 1 -fill both
     pack [frame $con3 -bd 2 -relief groove] -side top
     grid [label $con1.lbl -text "New Rigid Body Type $bodnum"] -row 0 -column 0
     grid [label $con1.mat -text "Number of Matricies Describing Rigid Body"] -row 1 -column 0



     spinbox $con1.matnum -from 1 -to 10 -textvariable ::rb_matrix_num($bodnum) -width 5 -command "RB_Create_Cart $bodnum $con2"
     grid $con1.matnum -row 1 -column 1 -padx 10
     grid [label $con1.atoms -text "Number of Cartesian Sites"] -row 2 -column 0
     spinbox $con1.atomsnum -from 3 -to 1000 -textvariable ::rb_coord_num($bodnum,1) -width 5 -command "RB_Create_Cart $bodnum $con2"
     grid $con1.atomsnum -row 2 -column 1 -padx 10


     grid [button $con3.save -text "Save \n Rigid Body" -command "RB_Create_Save $bodnum"] -row 0 -column 2 -padx 5 -pady 5
     grid [button $con3.print -text "Export Cartesian \n Coordinates to File" -command "RB_CartesianTextFile $bodnum"] -row 0 -column 3 -padx 5
#     $con3.print configure -status disable
     grid [button $con3.abort -text "Abort \n Rigid Body" -command "destroy .nbt; RB_Control_Panel end"] -row 0 -column 4 -padx 5 -pady 5

     RB_Create_Cart $bodnum $con2

     bind $con1.atomsnum <Leave> "RB_Create_Cart $bodnum $con2"
     bind $con1.atomsnum <Return> "RB_Create_Cart $bodnum $con2"
     bind $con1.matnum <Leave> "RB_Create_Cart $bodnum $con2"
     bind $con1.matnum <Return> "RB_Create_Cart $bodnum $con2"
}

proc RB_Fixfrag_Load {args} {
     destroy .geometry
     toplevel .geometry
     putontop .geometry
     set geo .geometry


     pack [frame $geo.con -bd 2 -relief groove] -side top
     pack [frame $geo.display -bd 2 -relief groove] -side top -expand 1 -fill both
     pack [frame $geo.con2 -bd 2 -relief groove] -side bottom
#     pack [frame $geo.save -bd 2 -relief groove] -side bottom

     wm title $geo "Fix Molecular Fragment from EXP File"
     wm geometry $geo 800x400+10+10

     set phase 1
     set gcon $geo.con
     set gcon2 $geo.con2
     set gdisplay $geo.display
     set ::gcon_atoms 3

     eval tk_optionMenu $geo.con.phaseinput ::rb_phase $::expmap(phaselist)
     grid [label $gcon.phaselbl -text "Input Phase"] -row 0 -column 0
     grid $gcon.phaseinput -row 0 -column 1
     set ::gcon_atoms_total $::expmap(atomlist_$phase)
     grid [label $gcon.atomlbl -text "Number of atoms in fragment: "] -row 1 -column 0
     spinbox $gcon.atom -from 3 -to [lrange $::expmap(atomlist_$phase) end end] -textvariable ::gcon_atoms -width 5
     grid $gcon.atom -row 1 -column 1 -padx 5
     grid [button $gcon.atomchoice -text "Choose Start Atom" -command "RB_FixStartAtom $phase $gdisplay $gcon2"] -row 1 -column 2
     grid [button $gcon2.save -text "Save and Map \n Rigid Body" -width 15 -command "RB_Geom_Save"] -row 0 -column 0 -padx 5
          $gcon2.save config -state disable
     grid [button $gcon2.savec -text "Export Cartesian \n Coordinates" -width 15 -command "RB_FixFragSaveCoord"] -row 0 -column 1 -padx 5
          $gcon2.savec config -state disable
     grid [button $gcon2.abort -text "Abort" -width 15 -command "destroy .geometry"] -row 0 -column 2 -sticky ns -padx 5

}

proc RB_FixFragSaveCoord {args} {
# number of atoms in rigid body  ::gcon_atoms
# first atom in rigid body       ::gcon_start
# origin list                    ::gcon_origin_list

     set vector1list "X"
     set vector2list "Y"

     lappend vector1list [expr $::geom_x1 - [expr $::gcon_start -1]]
     lappend vector1list [expr $::geom_x2 - [expr $::gcon_start -1]]
     lappend vector2list [expr $::geom_y1 - [expr $::gcon_start -1]]
     lappend vector2list [expr $::geom_y2 - [expr $::gcon_start -1]]

     set ::gcon_origin_list ""
     foreach item $::rb_atom_range {
                if {$::rb_atom_origin_set($item) == 1} {
                set temp [expr $item - [expr $::gcon_start - 1]]
                   lappend ::gcon_origin_list $temp
                }
        }

        set temp1 [ExtractRigidBody $::rb_phase $::gcon_atoms $::gcon_start $::gcon_origin_list $vector1list $vector2list]
        if {[lindex $temp1 0] == {} || [lindex $temp1 1] == {} || [lindex $temp1 2] == {}} {
            # an error occurred
            return
        }

   set coordlist ""
   lappend coordlist [lindex $temp1 2]
#   puts $coordlist

   set bodnum [RB_New_RBnum]
#   puts "body number = $bodnum"
   set coordnum 0
#   set ::rb_damp($bodnum,1) 0
   set ::rb_coord_num($bodnum,1) $::gcon_atoms

   catch {array unset ::rb_x $bodnum,1,*}
   catch {array unset ::rb_y $bodnum,1,*}
   catch {array unset ::rb_z $bodnum,1,*}


   foreach coord $coordlist {

           set ::rb_x($bodnum,1,$coordnum) [lindex $coord 1]
           set ::rb_y($bodnum,1,$coordnum) [lindex $coord 2]
           set ::rb_z($bodnum,1,$coordnum) [lindex $coord 3]
           incr coordnum
   }


   NewBodyTypeWindow
   destroy .geometry
#   RB_Control_Panel 0


}

proc RB_FixStartAtom {phase gdisplay gcon2 args} {
     set ::gcon_start ""
     set possible_start [RigidStartAtoms $phase $::gcon_atoms]

     if {$possible_start == ""} {
        set ::gdisplay $gdisplay
        #grid [label $ca.stop -text "Warning, action failed due to lack of unmapped atoms."] -row 0 -column 0
        #grid [button $ca.cont -text "continue" -command "destroy $ca"] -row 1 -column 0
        MyMessageBox -parent $gdisplay \
          -message "There are not enough atoms in this phase that are not already mapped to a rigid body to use."
        return
     }

     catch {destroy .chooseatom}
     set ca .chooseatom
     toplevel $ca
     wm title $ca "Choose Atom"

#     puts $atomlist
     foreach {top main side lbl} [MakeScrollTable $ca] {}

     set row 0
     set column 0
     foreach atom $possible_start {
        set label "[atominfo $phase $atom label] \($atom\)"
        button $main.$atom -text $label -command "set ::gcon_start $atom; destroy $ca"

        incr row
        if {$row > 5} {
           set row 1
           incr column
        }
      grid $main.$atom -row $row -column $column -padx 5 -pady 5
      }
      ResizeScrollTable $ca
      putontop $ca
      tkwait window $ca
      afterputontop
      $gcon2.save config -state normal
      $gcon2.savec config -state normal
      RB_Atom_Fixlist $phase $gdisplay
}

proc RB_Atom_Fixlist {phase gdisplay} {
#     set ::gcon_start ""
     set start_loc [lsearch $::expmap(atomlist_$phase) $::gcon_start]
     set ::rb_atom_range [lrange $::expmap(atomlist_$phase) $start_loc [expr $start_loc + $::gcon_atoms - 1]]
#     puts "location = $start_loc  range = $::rb_atom_range"
     set rownum 1
     set colnum 1

     eval destroy [winfo children $gdisplay]
     grid [frame $gdisplay.lbl -bd 2 -relief groove] -row 0 -column 0
     grid [frame $gdisplay.atoms -bd 2 -relief groove] -row 1 -column 0
     grid [frame $gdisplay.param -bd 2 -relief groove] -row 1 -column 1

     grid [label $gdisplay.lbl.state -text "Select atoms to define centroid for origin"] -row 0 -column 0
  #   grid [button $gdisplay.lbl.set -text "Set Origin" -command "RB_Atom_Origin_Set"] -row 3 -column 0

     foreach {top main side lbl} [MakeScrollTable $gdisplay.atoms] {}
     eval destroy [winfo children $main]
     foreach atom $::rb_atom_range {


             if {[expr $colnum % 4] == 0} {incr rownum; set colnum 1}
             set atomid [atominfo $phase $atom  label]
#             puts $atomid
             set ::rb_atom_origin_set($atom) 1
             grid [checkbutton $main.$atom -text "$atomid" -variable ::rb_atom_origin_set($atom)] -row $rownum -column $colnum
             incr colnum

             }
      ResizeScrollTable $gdisplay.atoms


  set paramlist $gdisplay.param
# [atominfo $phase $::rb_atom_range label]
  grid [label $paramlist.lbl -text "Define Axes"] -row 0 -column 0 -columnspan 2
  grid [label $paramlist.lbl1 -text "Atom 1"] -row 1 -column 0
  grid [label $paramlist.lbl2 -text "Atom 2"] -row 1 -column 1
  grid [label $paramlist.lblx -text "Choose two atoms to define vector for x-axis: "] -row 2 -column 0 -pady 10 -columnspan 2
  grid [label $paramlist.lbly -text "Choose two atoms to define second vector defining xy plane: "] -row 4 -column 0 -pady 10 -columnspan 2

  set atom_info_list ""
  set atom_list ""
  foreach atom $::rb_atom_range {
          lappend atom_info_list $atom
          lappend atom_info_list [atominfo $phase $atom label]
          lappend atom_list [atominfo $phase $atom label]
  }

#                  puts $atom_info_list
       set ::rb_param_x1 [lindex $atom_list 0]
       set ::rb_param_x2 [lindex $atom_list 1]
       set ::rb_param_y1 [lindex $atom_list 0]
       set ::rb_param_y2 [lindex $atom_list 2]
       set ::geom_x1     [lindex $::rb_atom_range 0]
       set ::geom_x2     [lindex $::rb_atom_range 1]
       set ::geom_y1     [lindex $::rb_atom_range 0]
       set ::geom_y2     [lindex $::rb_atom_range 2]

       set menu [eval tk_optionMenu $paramlist.x1 ::rb_param_x1 $atom_list]
           foreach item $atom {
              set max [llength $atom]
              for {set count 0} {$count <= [expr $max - 1]} {incr count} {
                 $menu entryconfig $count -command "set ::geom_x1 [lindex $atom_info_list [expr $count*2]]"
              }
       }

       set menu [eval tk_optionMenu $paramlist.x2 ::rb_param_x2 $atom_list]
           foreach item $atom {
              set max [llength $atom]
              for {set count 0} {$count <= [expr $max - 1]} {incr count} {
                 $menu entryconfig $count -command "set ::geom_x2 [lindex $atom_info_list [expr $count*2]]"
              }
       }

       set menu [eval tk_optionMenu $paramlist.y1 ::rb_param_y1 $atom_list]
           foreach item $atom {
              set max [llength $atom]
              for {set count 0} {$count <= [expr $max - 1]} {incr count} {
                 $menu entryconfig $count -command "set ::geom_y1 [lindex $atom_info_list [expr $count*2]]"
              }
       }

       set menu [eval tk_optionMenu $paramlist.y2 ::rb_param_y2 $atom_list]
           foreach item $atom {
              set max [llength $atom]
              for {set count 0} {$count <= [expr $max - 1]} {incr count} {
                 $menu entryconfig $count -command "set ::geom_y2 [lindex $atom_info_list [expr $count*2]]"
              }
       }


       grid $paramlist.x1 -row 3 -column 0
       grid $paramlist.x2 -row 3 -column 1
       grid $paramlist.y1 -row 5 -column 0
       grid $paramlist.y2 -row 5 -column 1


         $paramlist.x1 config -width 4
         $paramlist.x2 config -width 4
         $paramlist.y1 config -width 4
         $paramlist.y2 config -width 4

  }


proc RB_Atom_Origin_Set {args} {
        set ::rb_origin_list ""
        foreach item $::rb_atom_range {
                if {$::rb_atom_origin_set($item) == 1} {
                   lappend ::rb_origin_list $item
                }
        }
#        puts "Origin list = $::rb_origin_list"
}

proc RB_Geom_Save {args} {
# number of atoms in rigid body  ::gcon_atoms
# first atom in rigid body       ::gcon_start
# origin list                    ::gcon_origin_list

     set vector1list "X"
     set vector2list "Y"

     lappend vector1list [expr $::geom_x1 - [expr $::gcon_start -1]]
     lappend vector1list [expr $::geom_x2 - [expr $::gcon_start -1]]
     lappend vector2list [expr $::geom_y1 - [expr $::gcon_start -1]]
     lappend vector2list [expr $::geom_y2 - [expr $::gcon_start -1]]

     set ::gcon_origin_list ""
     foreach item $::rb_atom_range {
                if {$::rb_atom_origin_set($item) == 1} {
                set temp [expr $item - [expr $::gcon_start - 1]]
                   lappend ::gcon_origin_list $temp
                }
        }
#        puts "Origin list = $::gcon_origin_list"
#        puts "vector 1 list = $vector1list"
#        puts "vector 2 list = $vector2list"
#        puts "number atoms = $::gcon_atoms"
#        puts "start atom  = $::gcon_start"

        set temp1 [ExtractRigidBody $::rb_phase $::gcon_atoms $::gcon_start $::gcon_origin_list $vector1list $vector2list]
        if {[lindex $temp1 0] == {} || [lindex $temp1 1] == {} || [lindex $temp1 2] == {}} {
           #   puts "Geometry Crashed"
        }
        #puts "string 1 = [lindex $temp1 0]"
        #puts "string 2 = [lindex $temp1 1]"
        #puts "string 3 = [lindex $temp1 2]"

        set cartesian ""
        lappend cartesian [lindex $temp1 2]
        #puts "Cartesian = $cartesian"

        set bodnum [AddRigidBody 1 $cartesian]
     RecordMacroEntry "AddRigidBody 1 [list $cartesian]" 0
        # set ::rb_damp($bodnum,1) 0
        set ::rb_coord_num($bodnum,1) $::gcon_atoms

     MapRigidBody $::rb_phase $bodnum $::gcon_start [lindex $temp1 0] [lindex $temp1 1]
     RecordMacroEntry "MapRigidBody $::rb_phase $bodnum $::gcon_start [lindex $temp1 0] [lindex $temp1 1]" 0
     incr ::expgui(changed)
     RecordMacroEntry "incr expgui(changed)" 0
     destroy .geometry
     RB_Control_Panel 0
}

proc RB_Refine_Con {args} {
     catch {destroy .refcon}
     set con .refcon
     toplevel $con
     wm title $con "Rigid Body Refinement Controls"
     wm geometry $con 1150x600+10+10
     set ::rb_var_list ""
     set ::rb_var_list_tls ""
     set ::varnum 1
     set ::rb_var_name "var$::varnum"
#     putontop $con
      grid [frame $con.info -bd 2 -relief groove] -row 1 -column 0 -sticky news
      grid columnconfig $con 0 -weight 1
      grid [frame $con.con -bd 2 -relief groove] -row 0 -column 0
      grid [frame $con.terminate -bd 2 -relief groove] -row 2 -column 0

      #bandaid fix:  load all mapping data
      foreach phase $::expmap(phaselist) {
              foreach bodnum [RigidBodyList] {
                      foreach mapnum [RigidBodyMappingList $phase $bodnum] {
                              RB_Load_Mapdata $phase $bodnum $mapnum
                      }
              }
      }

      #grid rowconfig $con 0 -weight 1

     foreach {top main side lbl} [MakeScrollTable $con.info] {}
             grid [label $top.rb -text "Body"] -row 1 -column 1 -padx 3
             grid [label $top.phase -text "Ph"] -row 1 -column 2 -padx 3
             grid [label $top.mapnum -text "Map"] -row 1 -column 3 -padx 3
             grid [label $top.x -text "X"] -row 1 -column 4 -padx 3
             grid [label $top.y -text "Y"] -row 1 -column 5 -padx 3
             grid [label $top.z -text "Z"] -row 1 -column 6 -padx 3
             grid [label $top.b1 -text "   "] -row 1 -column 7 -padx 3
             grid [label $top.e1 -text "E1"] -row 1 -column 8 -padx 3
             grid [label $top.e2 -text "E2"] -row 1 -column 9 -padx 3
             grid [label $top.e3 -text "E3"] -row 1 -column 10 -padx 3
             grid [label $top.tlscon1 -text "on/off"] -row 1 -column 11 -padx 3
#             grid [label $top.b2 -text "   "] -row 1 -column 11 -padx 3
             grid [label $top.t11 -text "T11"] -row 1 -column 12 -padx 3
             grid [label $top.t22 -text "T22"] -row 1 -column 13 -padx 3
             grid [label $top.t33 -text "T33"] -row 1 -column 14 -padx 3
             grid [label $top.t12 -text "T12"] -row 1 -column 15 -padx 3
             grid [label $top.t13 -text "T13"] -row 1 -column 16 -padx 3
             grid [label $top.t23 -text "T23"] -row 1 -column 17 -padx 3
             grid [label $top.b3 -text "   "] -row 1 -column 18 -padx 3
             grid [label $top.l11 -text "L11"] -row 1 -column 19 -padx 3
             grid [label $top.l22 -text "L22"] -row 1 -column 20 -padx 3
             grid [label $top.l33 -text "L33"] -row 1 -column 21 -padx 3
             grid [label $top.l12 -text "L12"] -row 1 -column 22 -padx 3
             grid [label $top.l13 -text "L13"] -row 1 -column 23 -padx 3
             grid [label $top.l23 -text "L23"] -row 1 -column 24 -padx 3
             grid [label $top.zb4 -text "   "] -row 1 -column 25 -padx 3
             grid [label $top.s12 -text "S12"] -row 1 -column 26 -padx 3
             grid [label $top.s13 -text "S13"] -row 1 -column 27 -padx 3
             grid [label $top.s21 -text "S21"] -row 1 -column 28 -padx 3
             grid [label $top.s23 -text "S23"] -row 1 -column 29 -padx 3
             grid [label $top.s31 -text "S31"] -row 1 -column 30 -padx 3
             grid [label $top.s32 -text "S32"] -row 1 -column 31 -padx 3
             grid [label $top.saa -text "SAA"] -row 1 -column 32 -padx 3
             grid [label $top.sbb -text "SBB"] -row 1 -column 33 -padx 3

             grid [label $top.refcoord -text "Origin"] -row 0 -column 4 -padx 5 -columnspan 3
             grid [label $top.refeuler -text "Euler Angles"] -row 0 -column 8 -padx 5 -columnspan 3
             grid [label $top.tlscon2 -text "TLS"] -row 0 -column 11
             grid [label $top.tls -text "TLS"] -row 0 -column 12 -padx 5 -columnspan 6
#             grid [label $top.atoms -text "Atoms in Mapping"] -row 0 -column 6 -padx 5 -columnspan 10

             #Determine number of rigid bodies and rigid body mappings
             set rb_num [RigidBodyList]
             set row 1
             foreach phasenum $::expmap(phaselist) {
                 foreach bodnum $rb_num {
                     set rb_map_num($phasenum,$bodnum) [RigidBodyMappingList $phasenum $bodnum]

                  foreach mapnum $rb_map_num($phasenum,$bodnum) {
#                         puts "mapnum = $mapnum"
#                         grid [checkbutton $main.check($phasenum,$bodnum,$mapnum)] -row $row -column 0
                         grid [label $main.body($phasenum,$bodnum,$mapnum) -text $bodnum] -row $row -column 1
                         grid [label $main.phase($phasenum,$bodnum,$mapnum) -text $phasenum] -row $row -column 2
                         grid [label $main.map($phasenum,$bodnum,$mapnum) -text $mapnum] -row $row -column 3
                         RB_Load_Vars $phasenum $bodnum $mapnum
#                         puts "the checkbutton variable is $::rb_var($phasenum,$bodnum,$mapnum,tls)"

#                         puts $main
                         grid [button $main.cfefx($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.cfefx($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,x) -width 8] -row $row -column 4
                         grid [entry $main.cfefxentry($phasenum,$bodnum,$mapnum) -textvariable ::rb($phasenum,$bodnum,$mapnum,x) -width 8] -row [expr $row + 1] -column 4
                         grid [button $main.cfefy($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.cfefy($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,y) -width 8]  -row $row -column 5
                         grid [entry $main.cfefyentry($phasenum,$bodnum,$mapnum) -textvariable ::rb($phasenum,$bodnum,$mapnum,y) -width 8] -row [expr $row + 1] -column 5
                         grid [button $main.cfefz($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.cfefz($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,z) -width 8] -row $row -column 6
                         grid [entry $main.cfefzentry($phasenum,$bodnum,$mapnum) -textvariable ::rb($phasenum,$bodnum,$mapnum,z) -width 8] -row [expr $row + 1] -column 6
                         grid [label $main.b1($phasenum,$bodnum,$mapnum) -text "   "] -row $row -column 7

                         grid [button $main.eref1($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.eref1($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,e1) -width 8] -row $row -column 8
                         grid [entry $main.eref1entry($phasenum,$bodnum,$mapnum) -textvariable ::rb($phasenum,$bodnum,$mapnum,e1) -width 8] -row [expr $row + 1] -column 8
                         grid [button $main.eref2($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.eref2($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,e2) -width 8] -row $row -column 9
                         grid [entry $main.eref2entry($phasenum,$bodnum,$mapnum) -textvariable ::rb($phasenum,$bodnum,$mapnum,e2) -width 8] -row [expr $row + 1] -column 9
                         grid [button $main.eref3($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.eref3($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,e3) -width 8] -row $row -column 10
                         grid [entry $main.eref3entry($phasenum,$bodnum,$mapnum) -textvariable ::rb($phasenum,$bodnum,$mapnum,e3) -width 8] -row [expr $row + 1] -column 10
#                         grid [label $main.b2($phasenum,$bodnum,$mapnum) -text "   "] -row $row -column 11

                         grid [checkbutton $main.tlscon($phasenum,$bodnum,$mapnum) -variable ::rb_var($phasenum,$bodnum,$mapnum,tls) -command "RB_TLS_Onoff $phasenum $main $bodnum $mapnum" -width 5] -row $row -column 11


                         grid [button $main.t11ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.t11ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,t11) -width 8] -row $row -column 12
                         grid [entry $main.t11entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,t11) -width 8] -row [expr $row + 1] -column 12
                         grid [button $main.t22ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.t22ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,t22) -width 8] -row $row -column 13
                         grid [entry $main.t22entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,t22) -width 8] -row [expr $row + 1] -column 13
                         grid [button $main.t33ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.t33ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,t33) -width 8] -row $row -column 14
                         grid [entry $main.t33entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,t33) -width 8] -row [expr $row + 1] -column 14
                         grid [button $main.t12ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.t12ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,t12) -width 8] -row $row -column 15
                         grid [entry $main.t12entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,t12) -width 8] -row [expr $row + 1] -column 15
                         grid [button $main.t13ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.t13ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,t13) -width 8] -row $row -column 16
                         grid [entry $main.t13entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,t13) -width 8] -row [expr $row + 1] -column 16
                         grid [button $main.t23ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.t23ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,t23) -width 8] -row $row -column 17
                         grid [entry $main.t23entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,t23) -width 8] -row [expr $row + 1] -column 17

                         grid [button $main.l11ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.l11ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,l11) -width 8] -row $row -column 19
                         grid [entry $main.l11entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,l11) -width 8] -row [expr $row + 1] -column 19
                         grid [button $main.l22ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.l22ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,l22) -width 8] -row $row -column 20
                         grid [entry $main.l22entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,l22) -width 8] -row [expr $row + 1] -column 20
                         grid [button $main.l33ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.l33ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,l33) -width 8] -row $row -column 21
                         grid [entry $main.l33entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,l33) -width 8] -row [expr $row + 1] -column 21
                         grid [button $main.l12ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.l12ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,l12) -width 8] -row $row -column 22
                         grid [entry $main.l12entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,l12) -width 8] -row [expr $row + 1] -column 22
                         grid [button $main.l13ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.l13ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,l13) -width 8] -row $row -column 23
                         grid [entry $main.l13entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,l13) -width 8] -row [expr $row + 1] -column 23
                         grid [button $main.l23ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.l23ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,l23) -width 8] -row $row -column 24
                         grid [entry $main.l23entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,l23) -width 8] -row [expr $row + 1] -column 24

                         grid [label $main.b4($phasenum,$bodnum,$mapnum) -text "   "] -row $row -column 25

                         grid [button $main.s12ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.s12ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,s12) -width 8] -row $row -column 26
                         grid [entry $main.s12entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,s12) -width 8] -row [expr $row + 1] -column 26
                         grid [button $main.s13ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.s13ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,s13) -width 8] -row $row -column 27
                         grid [entry $main.s13entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,s13) -width 8] -row [expr $row + 1] -column 27
                         grid [button $main.s21ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.s21ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,s21) -width 8] -row $row -column 28
                         grid [entry $main.s21entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,s21) -width 8] -row [expr $row + 1] -column 28
                         grid [button $main.s23ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.s23ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,s23) -width 8] -row $row -column 29
                         grid [entry $main.s23entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,s23) -width 8] -row [expr $row + 1] -column 29
                         grid [button $main.s31ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.s31ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,s31) -width 8] -row $row -column 30
                         grid [entry $main.s31entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,s31) -width 8] -row [expr $row + 1] -column 30
                         grid [button $main.s32ref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.s32ref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,s32) -width 8] -row $row -column 31
                         grid [entry $main.s32entry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,s32) -width 8] -row [expr $row + 1] -column 31
                         grid [button $main.saaref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.saaref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,saa) -width 8] -row $row -column 32
                         grid [entry $main.saaentry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,saa) -width 8] -row [expr $row + 1] -column 32
                         grid [button $main.sbbref($phasenum,$bodnum,$mapnum) -command "RB_Con_Button $main.sbbref($phasenum,$bodnum,$mapnum)" -textvariable ::rb_var($phasenum,$bodnum,$mapnum,sbb) -width 8] -row $row -column 33
                         grid [entry $main.sbbentry($phasenum,$bodnum,$mapnum) -textvariable ::rb_tls($phasenum,$bodnum,$mapnum,sbb) -width 8] -row [expr $row + 1] -column 33

                         RB_TLS_Onoff $phasenum $main $bodnum $mapnum


#                         set col 4
                         set atomnum $::rb_map_beginning($phasenum,$bodnum,$mapnum)
#                         puts "first atom = $atomnum"
#                         set atomlist "atoms in rigid body #$bodnum:    "
                         set atomlist {}
                         # get a list of the atoms in the RB
                         set st [lsearch $::expmap(atomlist_$phase) $atomnum]
                         set en [expr {$st+$::rb_coord_num($bodnum,1)-1}]
                         set atoms [lrange $::expmap(atomlist_$phase) $st $en]
                         foreach a $atoms {
                             if {$atomlist != ""} {append atomlist ", "}
                             set lbl [atominfo $phase $a label]
                             append atomlist $lbl
                        }
                        grid [label $main.rb_site$phasenum$bodnum$mapnum \
                                  -text "atoms in rigid body:    $atomlist"] \
                             -row [expr $row + 2] -column 4 -padx 5 -columnspan 999 -sticky w
                        incr row 3
                     }
                 }
             }
             ResizeScrollTable $con.info
             set ::rbaddresses [winfo children .refcon.info.can.f]

             set ::rb_var_name "var$::varnum"
             set free "free"
             set const ""

             grid [label $con.con.lbl -text "Set Variables Selected Below"] -row 1 -column 1
             grid [button $con.con.free -width 22 -text "Set Free Variable" -command {RB_Con_But_Proc $::rbaddresses free}] -row 2 -column 1
             grid [button $con.con.const -width 22 -text "Do Not Refine Variables" -command {RB_Con_But_Proc $::rbaddresses ""}] -row 3 -column 1
             grid [button $con.con.var -width 22 -text "Set Constrained Variables" -command {RB_Con_But_Proc $::rbaddresses $::rb_var_name; incr ::varnum; set ::rb_var_name "var$::varnum"}] -row 4 -column 1
             grid [entry $con.con.vare -textvariable ::rb_var_name -width 5] -row 4 -column 2
             grid [button $con.con.clear -width 22 -text "Clear All Variables" -command {RB_Variable_Clear}] -row 5 -column 1

             grid [label $con.terminate.originlabel -text "Origin Damping Factor "] -row 5 -column 1


             eval tk_optionMenu $con.terminate.origindamp ::rb_damp_origin 0 1 2 3 4 5 6 7 8 9
             grid $con.terminate.origindamp -row 5 -column 3
#             $con.terminate.origindamp config -width 4 -state disable

             grid [label $con.terminate.anglelabel -text "Angle Damping Factor "] -row 6 -column 1
             eval tk_optionMenu $con.terminate.angledamp ::rb_damp_euler 0 1 2 3 4 5 6 7 8 9
             grid $con.terminate.angledamp -row 6 -column 3
 #            $con.terminate.angledamp config -width 4 -state disable

             grid [label $con.terminate.tls -text "TLS Damping Factors "] -row 7 -column 1
             eval tk_optionMenu $con.terminate.t ::rb_damp_t "" 0 1 2 3 4 5 6 7 8 9
             eval tk_optionMenu $con.terminate.l ::rb_damp_l "" 0 1 2 3 4 5 6 7 8 9
             eval tk_optionMenu $con.terminate.s ::rb_damp_s "" 0 1 2 3 4 5 6 7 8 9
             grid [label $con.terminate.t1 -text "T"] -row 7 -column 2
             grid $con.terminate.t -row 7 -column 3
#             $con.terminate.t config -state disable
             grid [label $con.terminate.l1 -text "L"] -row 7 -column 4
             grid $con.terminate.l -row 7 -column 5
#             $con.terminate.l config -state disable
             grid [label $con.terminate.s1 -text "S"] -row 7 -column 6
             grid $con.terminate.s -row 7 -column 7
#             $con.terminate.s config -state disable

             grid [button $con.terminate.save -width 22 -text "Assign Variables and Save" -command RB_Var_Assign] -row 8 -column 1 -columnspan 2
             grid [button $con.terminate.abort -width 22 -text "Abort" -command  {destroy .refcon}] -row 9 -column 1 -columnspan 2

}

proc RB_Variable_Clear {} {
     foreach var $::rb_var_list {
             set $var ""
     }
     foreach var $::rb_var_list_tls {
             set $var ""
     }

}

proc RB_Con_But_Proc {addresses change args} {
#     puts "$addresses $change"
     foreach address $addresses {
             set a [eval $address cget -bg]
             if {$a == "yellow"} {
                set var [eval $address cget -textvariable]
                set $var $change
                $address config -relief raised -bg lightgray
              }
     }
}

#procedure to turn buttons on (sunken yellow) and off (lightgray raised).
proc RB_Con_Button {address args} {
     set a [eval $address cget -relief]
     if {$a == "raised"} {
        $address config -relief sunken -bg yellow
     }
     if {$a == "sunken"} {
        $address config -relief raised
        $address config -bg lightgray
     }
}



#procedure to determine next available variable number for GSAS
proc RB_Var_Gen {varcount args} {
     while {[lsearch $::rb_varlist $varcount] != -1} {incr varcount}
     lappend ::rb_varlist $varcount
     return $varcount
}

#procedure to assign variable names to relationships
proc RB_Var_Assign {args} {
     set ::rb_varlist [RigidBodyGetVarNums]
     set varcount 1
     set varlist ""
     catch {array unset rb_var_temp}
     foreach var $::rb_var_list {
            if {[set $var] == ""} {
               set $var 0
            } elseif {[set $var] == "free"} {
                     set $var [RB_Var_Gen $varcount]
                     set varcount [set $var]
            } else {
#                     puts [lsearch $varlist [set $var]]
                     if {[lsearch $varlist [set $var]] == -1} {
                        lappend varlist [set $var]
                        puts $varlist
                        set rb_variable([set $var]) [RB_Var_Gen $varcount]
                        set $var $rb_variable([set $var])

                     } else {
                        set $var $rb_variable([set $var])
                     }
             }
     }

          foreach var $::rb_var_list_tls {
            if {[set $var] == ""} {
               set $var 0
            } elseif {[set $var] == "free"} {
                     set $var [RB_Var_Gen $varcount]
                     set varcount [set $var]
            } else {
#                     puts [lsearch $varlist [set $var]]
                     if {[lsearch $varlist [set $var]] == -1} {
                        lappend varlist [set $var]
#                        puts $varlist
                        set rb_variable([set $var]) [RB_Var_Gen $varcount]
                        set $var $rb_variable([set $var])

                     } else {
                        set $var $rb_variable([set $var])
                     }
             }
     }

     RB_Var_Save
     incr ::expgui(changed)
     destroy .refcon
}

#procedure for enabling refinement flags
proc RB_Ref_FlagEnable {phasenum bodnum mapnum var val args} {
    set atomnum $::rb_map_beginning($phasenum,$bodnum,$mapnum)
    # get a list of the atoms in the RB
    set st [lsearch $::expmap(atomlist_$phasenum) $atomnum]
    set en [expr {$st+$::rb_coord_num($bodnum,1)-1}]
    set atomlist [lrange $::expmap(atomlist_$phasenum) $st $en]
    atominfo $phasenum $atomlist $var set $val
 }




#procedure to send variable numbers to EXP file.
proc RB_Var_Save {args} {

     #Determine number of rigid bodies and rigid body mappings
     set rb_num [RigidBodyList]
     foreach phasenum $::expmap(phaselist) {
          foreach bodnum $rb_num {
               set rb_map_num($phasenum,$bodnum) [RigidBodyMappingList $phasenum $bodnum]
               foreach mapnum $rb_map_num($phasenum,$bodnum) {
                       set refcoordflag 0
                       set reftlsflag 0
                       set rb_list "$::rb_var($phasenum,$bodnum,$mapnum,e1) \
                           $::rb_var($phasenum,$bodnum,$mapnum,e2) $::rb_var($phasenum,$bodnum,$mapnum,e3) \
                           0 0 0 $::rb_var($phasenum,$bodnum,$mapnum,x) $::rb_var($phasenum,$bodnum,$mapnum,y) \
                           $::rb_var($phasenum,$bodnum,$mapnum,z)"
#                       puts "param saved for map $phasenum $bodnum $mapnum is vvvvvvv $rb_list"
                       RigidBodyVary $phasenum $bodnum $mapnum $rb_list
                       RecordMacroEntry "incr expgui(changed); RigidBodyVary $phasenum $bodnum $mapnum [list $rb_list]" 0
                       foreach test $rb_list {
                            if {$test != 0} {
                               set refcoordflag 1
                            }
                       }
                          RB_Ref_FlagEnable $phasenum $bodnum $mapnum xref $refcoordflag

                       if {$::rb_var($phasenum,$bodnum,$mapnum,tls) == 1} {
                           set rb_tls "$::rb_var($phasenum,$bodnum,$mapnum,t11) $::rb_var($phasenum,$bodnum,$mapnum,t22) \
                               $::rb_var($phasenum,$bodnum,$mapnum,t33) $::rb_var($phasenum,$bodnum,$mapnum,t12) \
                               $::rb_var($phasenum,$bodnum,$mapnum,t13) $::rb_var($phasenum,$bodnum,$mapnum,t23) \
                               $::rb_var($phasenum,$bodnum,$mapnum,l11) $::rb_var($phasenum,$bodnum,$mapnum,l22) \
                               $::rb_var($phasenum,$bodnum,$mapnum,l33) $::rb_var($phasenum,$bodnum,$mapnum,l12) \
                               $::rb_var($phasenum,$bodnum,$mapnum,l13) $::rb_var($phasenum,$bodnum,$mapnum,l23) \
                               $::rb_var($phasenum,$bodnum,$mapnum,s12) $::rb_var($phasenum,$bodnum,$mapnum,s13) \
                               $::rb_var($phasenum,$bodnum,$mapnum,s21) $::rb_var($phasenum,$bodnum,$mapnum,s23) \
                               $::rb_var($phasenum,$bodnum,$mapnum,s31) $::rb_var($phasenum,$bodnum,$mapnum,s32) \
                               $::rb_var($phasenum,$bodnum,$mapnum,saa) $::rb_var($phasenum,$bodnum,$mapnum,sbb)"
                           set rb_tls_vals "$::rb_tls($phasenum,$bodnum,$mapnum,t11) $::rb_tls($phasenum,$bodnum,$mapnum,t22) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,t33) $::rb_tls($phasenum,$bodnum,$mapnum,t12) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,t13) $::rb_tls($phasenum,$bodnum,$mapnum,t23) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,l11) $::rb_tls($phasenum,$bodnum,$mapnum,l22) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,l33) $::rb_tls($phasenum,$bodnum,$mapnum,l12) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,l13) $::rb_tls($phasenum,$bodnum,$mapnum,l23) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,s12) $::rb_tls($phasenum,$bodnum,$mapnum,s13) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,s21) $::rb_tls($phasenum,$bodnum,$mapnum,s23) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,s31) $::rb_tls($phasenum,$bodnum,$mapnum,s32) \
                               $::rb_tls($phasenum,$bodnum,$mapnum,saa) $::rb_tls($phasenum,$bodnum,$mapnum,sbb)"

                            set rb_damping "$::rb_damp_euler $::rb_damp_euler $::rb_damp_euler \
                                $::rb_damp_euler $::rb_damp_euler $::rb_damp_euler \
                                $::rb_damp_origin $::rb_damp_origin $::rb_damp_origin"
                            set rb_damping_tls "$::rb_damp_t $::rb_damp_l $::rb_damp_s"
                            puts "tls damping = $rb_damping_tls"
#                            puts "rb damping = $rb_damping"


#                            RigidBodySetDamp $phasenum $bodnum $mapnum $rb_damping $rb_damping_tls
                            
                            if {$::rb_var($phasenum,$bodnum,$mapnum,tls) == 0} {
                                  RigidBodySetDamp $phasenum $bodnum $mapnum $rb_damping 
                            } else {
                                  RigidBodySetDamp $phasenum $bodnum $mapnum $rb_damping $rb_damping_tls
                            }

#                           puts "TLS Values to be saved = $rb_tls_vals"
                            set rb_tls_positions "$::rb($phasenum,$bodnum,$mapnum,x) $::rb($phasenum,$bodnum,$mapnum,y) \
                               $::rb($phasenum,$bodnum,$mapnum,z)"
                            set rb_tls_euler "$::rb($phasenum,$bodnum,$mapnum,e1) $::rb($phasenum,$bodnum,$mapnum,e2) \
                               $::rb($phasenum,$bodnum,$mapnum,e3)"
#                           puts "origin positions = $rb_tls_positions"
#                           puts "euler angles = $rb_tls_euler"

#                           puts "TLS param save for $mapnum $bodnum $mapnum is vvvvvvvv $rb_tls"
                           RigidBodySetTLS $phasenum $bodnum $mapnum $rb_tls_vals
                           EditRigidBodyMapping $phasenum $bodnum $mapnum $rb_tls_positions $rb_tls_euler
#                           RecordMacroEntry "RigidBodySetTLS $phasenum $bodnum $mapnum $rb_tls_vals"

                           RigidBodyTLSVary $phasenum $bodnum $mapnum $rb_tls
                           RecordMacroEntry "RigidBodyTLSVary $phasenum $bodnum $mapnum [list $rb_tls]" 0
                           foreach test $rb_tls {
                            if {$test != 0} {
                               set reftlsflag 1
                            }
                       }
                          RB_Ref_FlagEnable $phasenum $bodnum $mapnum uref $reftlsflag
                       }
                       incr ::expgui(changed)
                       RecordMacroEntry "incr expgui(changed)" 0

               }
          }
#     puts "phasenumber is $phasenum"
     DisplayAllAtoms $phasenum
#need to track body number from button on notebook page.  Below is a temporary fix
      RB_Control_Panel $::rb_panel
#     RB_Populate $::rb_notebook 1
     }
}

# procedure to turn tls buttons on or off
proc RB_TLS_Onoff {phasenum main bodnum mapnum} {

      lappend tlsparam $main.t11ref($phasenum,$bodnum,$mapnum) $main.t22ref($phasenum,$bodnum,$mapnum) $main.t33ref($phasenum,$bodnum,$mapnum) \
              $main.t12ref($phasenum,$bodnum,$mapnum) $main.t13ref($phasenum,$bodnum,$mapnum) $main.t23ref($phasenum,$bodnum,$mapnum) \
              $main.l11ref($phasenum,$bodnum,$mapnum) $main.l22ref($phasenum,$bodnum,$mapnum) $main.l33ref($phasenum,$bodnum,$mapnum) \
              $main.l12ref($phasenum,$bodnum,$mapnum) $main.l13ref($phasenum,$bodnum,$mapnum) $main.l23ref($phasenum,$bodnum,$mapnum) \
              $main.s12ref($phasenum,$bodnum,$mapnum) $main.s13ref($phasenum,$bodnum,$mapnum) $main.s21ref($phasenum,$bodnum,$mapnum) \
              $main.s23ref($phasenum,$bodnum,$mapnum) $main.s31ref($phasenum,$bodnum,$mapnum) $main.s32ref($phasenum,$bodnum,$mapnum) \
              $main.saaref($phasenum,$bodnum,$mapnum) $main.sbbref($phasenum,$bodnum,$mapnum)

      lappend tlsentry $main.t11entry($phasenum,$bodnum,$mapnum) $main.t22entry($phasenum,$bodnum,$mapnum) $main.t33entry($phasenum,$bodnum,$mapnum) \
              $main.t12entry($phasenum,$bodnum,$mapnum) $main.t13entry($phasenum,$bodnum,$mapnum) $main.t23entry($phasenum,$bodnum,$mapnum) \
              $main.l11entry($phasenum,$bodnum,$mapnum) $main.l22entry($phasenum,$bodnum,$mapnum) $main.l33entry($phasenum,$bodnum,$mapnum) \
              $main.l12entry($phasenum,$bodnum,$mapnum) $main.l13entry($phasenum,$bodnum,$mapnum) $main.l23entry($phasenum,$bodnum,$mapnum) \
              $main.s12entry($phasenum,$bodnum,$mapnum) $main.s13entry($phasenum,$bodnum,$mapnum) $main.s21entry($phasenum,$bodnum,$mapnum) \
              $main.s23entry($phasenum,$bodnum,$mapnum) $main.s31entry($phasenum,$bodnum,$mapnum) $main.s32entry($phasenum,$bodnum,$mapnum) \
              $main.saaentry($phasenum,$bodnum,$mapnum) $main.sbbentry($phasenum,$bodnum,$mapnum)

#      puts $tlsparam
              if {$::rb_var($phasenum,$bodnum,$mapnum,tls) == 0} {
                        RigidBodyEnableTLS $phasenum $bodnum $mapnum 0
                        foreach x $tlsparam {
                                $x config -state disable -relief sunken
                        }
                        foreach x $tlsentry {
                                $x config -state disable
                        }
              } else {
                        RigidBodyEnableTLS $phasenum $bodnum $mapnum 1
                        foreach x $tlsparam {
                                $x config -state normal -relief raised
                        }
                        foreach x $tlsentry {
                                $x config -state normal
                        }
              }
}


proc RB_Load_Vars {phasenum bodnum mapnum args} {
#     foreach var $::rb_map_positionvars($phasenum,$bodnum,$mapnum) {
#             catch {unset temp($var)}
#     }
#
#     foreach var $::rb_map_positionvars($phasenum,$bodnum,$mapnum) {
#            if {[info exists temp($var)] == "0"} {
#                set temp($var) $var
#                } else {
#                  lappend mulvarlist $var
#             }
#    }
#
#    foreach var $::rb_map_tls_var($phasenum,$bodnum,$mapnum) {
#             if {[info exists temp($var)] == "0"} {
#                set temp($var) $var
#             } else {
#                lappend mulvarlist $var
#             }
#     }
#     puts "the mulvarlist is     $mulvarlist"

#     8Aug12    new code to determine variable names
     set rb_num [RigidBodyList]
     set varlist ""
     set mvarlist ""
     foreach phase $::expmap(phaselist) {
          foreach bod $rb_num {
               set rb_map_num($phase,$bod) [RigidBodyMappingList $phase $bod]
               if {$rb_map_num($phase,$bod) != ""} {
                  foreach map $rb_map_num($phase,$bod) {
                           foreach var $::rb_map_positionvars($phase,$bod,$map) {
                                    set temp1 [lsearch $varlist $var]
                                    if {$temp1 == "-1"} {lappend varlist $var
                                       } else {
                                           if {[lsearch $mvarlist $var] == "-1"} {lappend mvarlist $var}
                                       }
                           }
                           foreach var $::rb_map_tls_var($phase,$bod,$map) {
                                    set temp1 [lsearch $varlist $var]
                                    if {$temp1 == "-1"} {lappend varlist $var
                                       } else {
                                           if {[lsearch $mvarlist $var] == "-1"} {lappend mvarlist $var}
                                       }
                          }
                   }
               }
          }
     }
#     puts "varlist    $varlist"
#     puts "mvarlist   $mvarlist"

     set ::rb_var($phasenum,$bodnum,$mapnum,x) [RB_VarSet [lindex $::rb_map_positionvars($phasenum,$bodnum,$mapnum) 6] $mvarlist $varlist]
     set ::rb_var($phasenum,$bodnum,$mapnum,y) [RB_VarSet [lindex $::rb_map_positionvars($phasenum,$bodnum,$mapnum) 7] $mvarlist $varlist]
     set ::rb_var($phasenum,$bodnum,$mapnum,z) [RB_VarSet [lindex $::rb_map_positionvars($phasenum,$bodnum,$mapnum) 8] $mvarlist $varlist]

     lappend ::rb_var_list ::rb_var($phasenum,$bodnum,$mapnum,x) ::rb_var($phasenum,$bodnum,$mapnum,y) ::rb_var($phasenum,$bodnum,$mapnum,z)

     set ::rb_var($phasenum,$bodnum,$mapnum,e1) [RB_VarSet [lindex $::rb_map_positionvars($phasenum,$bodnum,$mapnum) 0] $mvarlist $varlist]
     set ::rb_var($phasenum,$bodnum,$mapnum,e2) [RB_VarSet [lindex $::rb_map_positionvars($phasenum,$bodnum,$mapnum) 1] $mvarlist $varlist]
     set ::rb_var($phasenum,$bodnum,$mapnum,e3) [RB_VarSet [lindex $::rb_map_positionvars($phasenum,$bodnum,$mapnum) 2] $mvarlist $varlist]

     lappend ::rb_var_list ::rb_var($phasenum,$bodnum,$mapnum,e1) ::rb_var($phasenum,$bodnum,$mapnum,e2) ::rb_var($phasenum,$bodnum,$mapnum,e3)

     ### create variables containing origin, euler angles and tls terms 14 Aug 2012

     set ::rb($phasenum,$bodnum,$mapnum,x) [lindex $::rb_map_origin($phasenum,$bodnum,$mapnum) 0]
     set ::rb($phasenum,$bodnum,$mapnum,y) [lindex $::rb_map_origin($phasenum,$bodnum,$mapnum) 1]
     set ::rb($phasenum,$bodnum,$mapnum,z) [lindex $::rb_map_origin($phasenum,$bodnum,$mapnum) 2]

     set ::rb($phasenum,$bodnum,$mapnum,e1) [lindex [lindex $::rb_map_euler($phasenum,$bodnum,$mapnum) 0] 0]
     set ::rb($phasenum,$bodnum,$mapnum,e2) [lindex [lindex $::rb_map_euler($phasenum,$bodnum,$mapnum) 1] 0]
     set ::rb($phasenum,$bodnum,$mapnum,e3) [lindex [lindex $::rb_map_euler($phasenum,$bodnum,$mapnum) 2] 0]

     set ::rb_tls($phasenum,$bodnum,$mapnum,t11) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 0]
     set ::rb_tls($phasenum,$bodnum,$mapnum,t22) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 1]
     set ::rb_tls($phasenum,$bodnum,$mapnum,t33) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 2]
     set ::rb_tls($phasenum,$bodnum,$mapnum,t12) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 3]
     set ::rb_tls($phasenum,$bodnum,$mapnum,t13) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 4]
     set ::rb_tls($phasenum,$bodnum,$mapnum,t23) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 5]
     set ::rb_tls($phasenum,$bodnum,$mapnum,l11) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 6]
     set ::rb_tls($phasenum,$bodnum,$mapnum,l22) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 7]
     set ::rb_tls($phasenum,$bodnum,$mapnum,l33) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 8]
     set ::rb_tls($phasenum,$bodnum,$mapnum,l12) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 9]
     set ::rb_tls($phasenum,$bodnum,$mapnum,l13) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 10]
     set ::rb_tls($phasenum,$bodnum,$mapnum,l23) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 11]
     set ::rb_tls($phasenum,$bodnum,$mapnum,s12) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 12]
     set ::rb_tls($phasenum,$bodnum,$mapnum,s13) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 13]
     set ::rb_tls($phasenum,$bodnum,$mapnum,s21) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 14]
     set ::rb_tls($phasenum,$bodnum,$mapnum,s23) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 15]
     set ::rb_tls($phasenum,$bodnum,$mapnum,s31) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 16]
     set ::rb_tls($phasenum,$bodnum,$mapnum,s32) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 17]
     set ::rb_tls($phasenum,$bodnum,$mapnum,saa) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 18]
     set ::rb_tls($phasenum,$bodnum,$mapnum,sbb) [lindex $::rb_map_tls($phasenum,$bodnum,$mapnum) 19]


     if {$::rb_map_tls_var($phasenum,$bodnum,$mapnum) != ""} {


          set ::rb_var($phasenum,$bodnum,$mapnum,t11) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 0] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,t22) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 1] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,t33) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 2] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,t12) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 3] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,t13) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 4] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,t23) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 5] $mvarlist $varlist]

          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,t11) ::rb_var($phasenum,$bodnum,$mapnum,t22) ::rb_var($phasenum,$bodnum,$mapnum,t33)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,t12) ::rb_var($phasenum,$bodnum,$mapnum,t13) ::rb_var($phasenum,$bodnum,$mapnum,t23)

          set ::rb_var($phasenum,$bodnum,$mapnum,l11) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 6] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,l22) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 7] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,l33) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 8] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,l12) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 9] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,l13) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 10] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,l23) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 11] $mvarlist $varlist]

          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,l11) ::rb_var($phasenum,$bodnum,$mapnum,l22) ::rb_var($phasenum,$bodnum,$mapnum,l33)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,l12) ::rb_var($phasenum,$bodnum,$mapnum,l13) ::rb_var($phasenum,$bodnum,$mapnum,l23)

          set ::rb_var($phasenum,$bodnum,$mapnum,s12) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 12] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,s13) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 13] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,s21) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 14] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,s23) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 15] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,s31) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 16] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,s32) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 17] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,saa) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 18] $mvarlist $varlist]
          set ::rb_var($phasenum,$bodnum,$mapnum,sbb) [RB_VarSet [lindex $::rb_map_tls_var($phasenum,$bodnum,$mapnum) 19] $mvarlist $varlist]

          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,s12) ::rb_var($phasenum,$bodnum,$mapnum,s13) ::rb_var($phasenum,$bodnum,$mapnum,s21)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,s23) ::rb_var($phasenum,$bodnum,$mapnum,s31) ::rb_var($phasenum,$bodnum,$mapnum,s32)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,saa) ::rb_var($phasenum,$bodnum,$mapnum,sbb)

          set ::rb_var($phasenum,$bodnum,$mapnum,tls) 1

     } else {
          set ::rb_var($phasenum,$bodnum,$mapnum,t11) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,t22) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,t33) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,t12) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,t13) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,t23) ""

          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,t11) ::rb_var($phasenum,$bodnum,$mapnum,t22) ::rb_var($phasenum,$bodnum,$mapnum,t33)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,t12) ::rb_var($phasenum,$bodnum,$mapnum,t13) ::rb_var($phasenum,$bodnum,$mapnum,t23)

          set ::rb_var($phasenum,$bodnum,$mapnum,l11) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,l22) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,l33) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,l12) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,l13) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,l23) ""

          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,l11) ::rb_var($phasenum,$bodnum,$mapnum,l22) ::rb_var($phasenum,$bodnum,$mapnum,l33)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,l12) ::rb_var($phasenum,$bodnum,$mapnum,l13) ::rb_var($phasenum,$bodnum,$mapnum,l23)

          set ::rb_var($phasenum,$bodnum,$mapnum,s12) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,s13) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,s21) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,s23) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,s31) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,s32) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,saa) ""
          set ::rb_var($phasenum,$bodnum,$mapnum,sbb) ""

          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,s12) ::rb_var($phasenum,$bodnum,$mapnum,s13) ::rb_var($phasenum,$bodnum,$mapnum,s21)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,s23) ::rb_var($phasenum,$bodnum,$mapnum,s31) ::rb_var($phasenum,$bodnum,$mapnum,s32)
          lappend ::rb_var_list_tls ::rb_var($phasenum,$bodnum,$mapnum,saa) ::rb_var($phasenum,$bodnum,$mapnum,sbb)

          set ::rb_var($phasenum,$bodnum,$mapnum,tls) 0
     }

}

proc RB_VarSet {varin mvarlist varlist args} {
     set temp [lsearch $mvarlist $varin]
     if {$temp == "-1"} {set varout "free"
        } else {
          set varout var$varin
        }
     if {$varin == 0} {set varout ""}
     return $varout


 #    if {$varin == 0} {set varout ""
 #       } else {
 #         set temp [lsearch $mulvarlist $varin]
 #         if {$temp == "-1"} {set varout "free"
 #                } else {
 #                  set varout var$varin
 #             }
 #    }
 #    return $varout
}

#returns next unused rigid body number
proc RB_New_RBnum {args} {

     set temp [RigidBodyList]
     for {set count 1} {[lsearch $temp $count] != -1} {incr count} {
     }
     return $count
}

proc RB_CartesianTextFile {bodnum args} {
    if {$::rb_matrix_num($bodnum) > 1} {
       MyMessageBox -message "Multiple matrices present, cannot save coordinates to file"
       return
    }
    set rb_file_write [tk_getSaveFile -filetypes {{"Cartesian output" .cart} {"All files" *}}]
    set fh [open $rb_file_write w]
    set coordnummax $::rb_coord_num($bodnum,1)
    for {set coord 0} {$coord < $coordnummax} {incr coord} {
        set line [list $::rb_x($bodnum,1,$coord) $::rb_y($bodnum,1,$coord) $::rb_z($bodnum,1,$coord)]
#        puts $line
#        puts $fh $line
    }
    close $fh
}

############################################################################################
proc RB_View_Parameters {phase x y args} {
   set euler     $::rb_map_euler($phase,$x,$y)
   set positions $::rb_map_positions($phase,$x,$y)
   set damping   $::rb_map_damping($phase,$x,$y)
   catch {destroy .viewparam}
   set vp .viewparam
   toplevel $vp
   wm title $vp "Refinement Options"
   frame $vp.con -bd 2 -relief groove
   frame $vp.spa -bd 2 -relief groove
   frame $vp.refflag -bd 2 -relief groove
   grid $vp.con -row 0 -column 0

   grid $vp.spa -row 2 -column 0
   grid $vp.refflag -row 1 -column 0

   set con $vp.con
   label $con.lbl -text "Refine: "
   button $con.tog -text "off"
   grid $con.lbl -row 0 -column 0
   grid $con.tog -row 0 -column 1

   grid [label $vp.spa.lbl1 -text "Supplemental Position Angles"] row 0 -column 0 -columnspan 3
   set ::e_angle1$y [lindex [lindex $euler 3] 0]

   set ::e_angle2$y [lindex [lindex $euler 4] 0]
   set ::e_angle3$y [lindex [lindex $euler 5] 0]
   grid [label $vp.spa.angle1l -text "Sup. Angle 1"] -row 1 -column 0
   grid [label $vp.spa.angle2l -text "Sup. Angle 2"] -row 2 -column 0
   grid [label $vp.spa.angle3l -text "Sup. Angle 3"] -row 3 -column 0
   grid [entry $vp.spa.angle1 -textvariable ::e_angle1$y] -row 1 -column 1
   grid [entry $vp.spa.angle2 -textvariable ::e_angle2$y] -row 2 -column 1
   grid [entry $vp.spa.angle3 -textvariable ::e_angle3$y] -row 3 -column 1

   set e_axis1 [lindex [lindex $euler 3] 1]
   set e_axis2 [lindex [lindex $euler 4] 1]
   set e_axis3 [lindex [lindex $euler 5] 1]

   grid [label $vp.refflag.lbl1 -text "Refinement Flags"] -row 0 -column 0 -columnspan 3
   grid [label $vp.refflag.x_axis -text "X-axis"] -row 1 -column 0
   grid [label $vp.refflag.y_axis -text "Y-axis"] -row 1 -column 1
   grid [label $vp.refflag.z_axis -text "Z-axis"] -row 1 -column 2
   grid [label $vp.refflag.euler1 -text "Euler Angle 1"] -row 3 -column 0
   grid [label $vp.refflag.euler2 -text "Euler Angle 2"] -row 3 -column 1
   grid [label $vp.refflag.euler3 -text "Euler Angle 3"] -row 3 -column 2
   grid [label $vp.refflag.sup1 -text "Sup. Angle 1"] -row 5 -column 0
   grid [label $vp.refflag.sup2 -text "Sup. Angle 2"] -row 5 -column 1
   grid [label $vp.refflag.sup3 -text "Sup. Angle 3"] -row 5 -column 2

   for {set j 0} {$j < 9} {incr j} {
       label $vp.refflag.$j -text [lindex $positions $j]
   }
   grid $vp.refflag.0 -row 2 -column 0
   grid $vp.refflag.1 -row 2 -column 1
   grid $vp.refflag.2 -row 2 -column 2
   grid $vp.refflag.3 -row 4 -column 0
   grid $vp.refflag.4 -row 4 -column 1
   grid $vp.refflag.5 -row 4 -column 2
   grid $vp.refflag.6 -row 6 -column 0
   grid $vp.refflag.7 -row 6 -column 1
   grid $vp.refflag.8 -row 6 -column 2

}

