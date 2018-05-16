
     set ::rb_loader(cartesian) RB_Cartesian_Load
     set ::rb_descriptor(cartesian) "Cartesian coordinates from text file"


   proc RB_Cartesian_Load {args} {

     destroy .cartesian
     toplevel .cartesian
     set cart .cartesian


     pack [frame $cart.con -bd 2 -relief groove] -side top
     pack [frame $cart.display -bd 2 -relief groove] -side top -expand 1 -fill both
     pack [frame $cart.save -bd 2 -relief groove] -side bottom
     wm title $cart "Load rigid body information from cartesian coordinate file"
     wm geometry $cart 600x600+10+10
     set ::rb_file_load ""
     set ::rb_cartfile ""
     set filelist ""
     set files [glob -nocomplain [file join $::expgui(scriptdir) *.cart]]
     foreach file $files {
            lappend ::rb_cartfile [lindex [string map {"/" " "} $file] end]
     }
 #    puts $::rb_cartfile
     set ::rb_file_load [lindex $::rb_cartfile 0]
 #    grid [label $cart.con.lbl -text "Choose Z-Matrix file to load"] -row 1 -column 0
 #    eval tk_optionMenu $cart.con.file ::rb_file_load $::rb_cartfile
 #    grid $cart.con.file -row 1 -column 1

     grid [button $cart.con.but -text "Load Coordinates from File" -width 22 -command "RB_cart $cart.display"] -row 2 -column 1
     grid [button $cart.save.but2 -text "Save Cartesian \n Coordinates" -width 15 -command "RB_cart_Build"] -row 2 -column 1 -padx 5
     $cart.save.but2 config -state disable
     grid [button $cart.save.but3 -text "Abort" -width 15 -command "destroy .cartesian"] -row 2 -column 3 -padx 5 -sticky ns
}

proc RB_cart {location args} {
     catch {unset array ::tline}
     set ::rb_file_load [tk_getOpenFile -parent .cartesian -filetypes {
      	    {"Cartesian input" .cart} {"All files" *}}]
     if {[string trim $::rb_file_load] == ""} return
     set fh [open $::rb_file_load r]
     set ::rb_linenum 0
     while {[gets $fh line] >= 0} {
           set line [string trim $line]
           if {$line == ""} continue
#           puts "blankcheck = $blankcheck\ntemp = $temp"
#           set temp [string trim $line " "]
#           if {$blankcheck != "0" && $blankcheck != "-1"}
#           if {$blankcheck != ""} {
              incr ::rb_linenum
              set ::tline($::rb_linenum) [string map {, " "} $line]
              puts "::tline($::rb_linenum) = $::tline($::rb_linenum) "
#           }


     }
     RB_cart_Display $location
     .cartesian.save.but2 config -state normal

}

 proc RB_cart_Display {location args} {

     eval destroy [winfo children $location]
     foreach {top main side lbl} [MakeScrollTable $location] {}
     set col [llength $::tline(1)]
     grid [label $top.col -justify center -text "Ignore \n line"] -row 0 -column 0
     set ::rb_cart_col(1) "label"
     set ::rb_cart_col(2) "X"
     set ::rb_cart_col(3) "Y"
     set ::rb_cart_col(4) "Z"



     set ::rb_colnum 0
     for {set linenum 1} {$linenum <= $::rb_linenum} {incr linenum} {
         for {set colnum 0} {$colnum <= [expr [llength $::tline($linenum)] -1]} {incr colnum} {
             grid [label $main.cart$::rb_colnum -text [lindex $::tline($linenum) $colnum] -width 8] -padx 5 -row $linenum -column [expr $colnum + 1]
             set ::rb_dummy_atom($linenum) 0
             grid [checkbutton $main.d$::rb_colnum -variable ::rb_dummy_atom($linenum)]  -row $linenum -column 0
             incr ::rb_colnum
         }
     }

       for {set z 1} {$z <= $::rb_colnum} {incr z} {
         if {$z > 4} {set ::rb_cart_col($z) "Ignore"}


         set menu [tk_optionMenu $top.$z ::rb_cart_col($z) atom X Y Z Ignore]
             $menu entryconfig 1 -command "RB_cart_restraint $z"
             $menu entryconfig 2 -command "RB_cart_restraint $z"
             $menu entryconfig 3 -command "RB_cart_restraint $z"
         grid $top.$z -row 0 -column $z
         $top.$z config -width 8

     }

     ResizeScrollTable $location
}

proc RB_cart_restraint {col args} {

     set fixcoord $::rb_cart_col($col)
          puts "column $col coordinate changed to $fixcoord"
     for {set z 1} {$z <= $::rb_colnum} {incr z} {
         if {$z != $col} {
            if {$::rb_cart_col($z) == $fixcoord} {puts "col $z needs to be changed"}
            if {$::rb_cart_col($z) == $fixcoord} {set ::rb_cart_col($z) "Ignore"}
         }
     }
}


proc RB_cart_Build {} {

     set bodytyp [expr [llength [RigidBodyList]] + 1]
     set ::rb_num 1
     set ::rb_matrix_num($bodytyp) 1
     set sitenum $::rb_linenum
     set temp $::rb_linenum
     set colnum [llength $::tline(1)]

     for {set z 1} {$z <= $::rb_colnum} {incr z} {
        if {$::rb_cart_col($z) == "x" || $::rb_cart_col($z) == "X"} {set ::rb_x_coord [expr $z - 1]}
        if {$::rb_cart_col($z) == "y" || $::rb_cart_col($z) == "Y"} {set ::rb_y_coord [expr $z - 1]}
        if {$::rb_cart_col($z) == "z" || $::rb_cart_col($z) == "Z"} {set ::rb_z_coord [expr $z - 1]}
     }
   #  puts "x = $::rb_x_coord"
   #  puts "y = $::rb_y_coord"
   #  puts "z = $::rb_z_coord"

     set x 1

     catch {array unset ::rb_x $bodytyp,1,*}
     catch {array unset ::rb_y $bodytyp,1,*}
     catch {array unset ::rb_z $bodytyp,1,*}


     for {set coordnum 1} {$coordnum <= $sitenum} {incr coordnum} {
         if {$::rb_dummy_atom($coordnum) != 1} {
  #                puts $::tline($coordnum)
                  set ::rb_x($bodytyp,1,$x) [lindex $::tline($coordnum) $::rb_x_coord]
                  set ::rb_y($bodytyp,1,$x) [lindex $::tline($coordnum) $::rb_y_coord]
                  set ::rb_z($bodytyp,1,$x) [lindex $::tline($coordnum) $::rb_z_coord]
  #                puts "line = $::tline($coordnum)"
  #                puts "coors = $::rb_x($bodytyp,1,$coordnum) $::rb_y($bodytyp,1,$coordnum) $::rb_z($bodytyp,1,$coordnum)"
                  incr x
         } else {
         set temp [expr $temp -1]
         }

     }

     set ::rb_coord_num($bodytyp,1) $temp


    #$::rb_notebook raise [$::rb_notebook page 0]
    # set pane [$::rb_notebook getframe rb_body0]
    # set con2 $pane.con2

     #RB_Create_Cart $bodytyp $con2
     destroy .cartesian
     NewBodyTypeWindow
}

