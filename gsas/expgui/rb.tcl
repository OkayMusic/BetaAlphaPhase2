#============================================================================
# Rigid body utility routines
#============================================================================
# RigidBodyGetVarNums: Returns a list of the variable numbers in use
#       for rigid body variable parameters.
# RigidBodyAtomNums: returns a list of atom numbers that are mapped to
#       rigid bodies in a selected phase
# RigidStartAtoms: returns a list of atoms that are allowed for creation of RB
# ExtractRigidBody: Use the GSAS geometry program to cartesian coordinates &
#       setting info for a RB from fractional coordinates for atoms in a phase
# RunRecalcRBCoords: updates the coordinates in all phases after changes have
#       been made to rigid parameters.
# CalcBody: Convert ortho to fractional coordinates using RB parameters
# FitBody: Optimize the origin and Euler angles to match a rigid body to a
#       set of fractional coordinates
# zmat2coord: convert a z-matrix to a set of cartesian coordinates
# RB2cart: convert the representation used for rigid bodies into 
#       cartesian coordinates
# PlotRBtype: plot a rigid body with DRAWxtl
# PlotRBcoords: plot orthogonal coordinates with DRAWxtl
# DRAWxtlPlotRBFit: plot a set of fraction coordinates superimposed 
#       on a structure read from a phase with DRAWxtl
#============================================================================
#============================================================================
# RigidBodyGetVarNums: Returns a list of the variable numbers used already
# for rigid body variable parameters
proc RigidBodyGetVarNums {} {
    set varlist {}
    foreach type [RigidBodyList] {
	set typelist [lindex [ReadRigidBody $type] 1]
	foreach item $typelist {
	    lappend varlist [lindex $item 2]
	}
	foreach phase $::expmap(phaselist) {
	    foreach i [RigidBodyMappingList $phase $type] {
		set items [ReadRigidBodyMapping $phase $type $i]
		set varlist [concat $varlist [lindex $items 3]]
		if {[llength [lindex $items 6]] > 0} {
		    set varlist [concat $varlist [lindex $items 6]]
		}
	    }
	}
    }
    return [lsort -integer -unique $varlist]
}

# RigidBodyAtomNums: Returns a list of the atoms mapped to rigid bodies in 
# phase $phase
proc RigidBodyAtomNums {phase} {
    if {[lsearch $::expmap(phaselist) $phase] == -1} {return ""}
    set allatoms $::expmap(atomlist_$phase)
    # get matching atoms coordinate range
    set mappedlist {}
    foreach type [RigidBodyList] {
	foreach i [RigidBodyMappingList $phase $type] {
	    # get the number of atoms in this type of body
	    set natoms [llength [lindex [lindex [lindex [ReadRigidBody $type] 1] 0] 3]]
	    set natom1 [expr {$natoms - 1}]
	    set items [ReadRigidBodyMapping $phase $type $i]
	    set firstatom [lindex $items 0]
	    set firstind [lsearch $allatoms $firstatom]
	    set mappedlist [concat $mappedlist \
				[lrange \
				     [lrange $allatoms $firstind end] \
				     0 $natom1] \
			       ]
	}
    }
    return [lsort -integer $mappedlist]
}

# RigidStartAtoms: Find allowed starting atoms for a rigid body in a phase
# Input: 
#   phase is the phase number
#   natoms is the number of atoms in the RB to be mapped
# Returns a list of valid "start" atoms.
# Example: if the atom numbers in the phase are {2 4 5 6 7 8} and no rigid bodies
# are mapped, then a 4-atom body can be mapped starting with atom 2, 4 or 5 only,
# so {2 4 5} is returned
# If atoms 2-6 were already mapped, then this routine would return an empty
# list, as it is not possible to map the body.
proc RigidStartAtoms {phase natoms} {
    if {[lsearch $::expmap(phaselist) $phase] == -1} {return ""}
    set allatoms $::expmap(atomlist_$phase)
    set usedatoms [RigidBodyAtomNums $phase]
    set startatomlist {}
    for {set i 0} {$i < [llength $allatoms]} {incr i} {
	set al [lrange $allatoms $i [expr {$i+$natoms-1}]]
	if {[llength $al] < $natoms} break
	set ok 1
	foreach atom $al {
	    if {[lsearch $usedatoms $atom] != -1} {
		set ok 0
		break
	    }
	}
	if $ok {lappend startatomlist [lindex $al 0]}
    }
    return $startatomlist
}

# ExtractRigidBody: Use the GSAS geometry program to compute a set of cartesian coordinates for a 
# set of atoms in a .EXP file and provide the origin shift and Euler angles needed to 
# place the cartesian system into the crystal coordinates. Used for setting up a rigid body.
# Returns a nested list of lists:
#   element 0: a list of the origin location {x y z} in fraction coordinates
#   element 1: a list of three rotation angles in form {a1 a2 a3}
#              where a1, a2 and a3 are rotations around the cartesian x, y and z axes
#   element 2: a list of $natom cartesian coordinate triples {{x1 y1 z1} {x2 y2 z2}...}
# arguments:
    # phase: phase #
    # natom: number of atoms in group
    # firstatom: sequence # in phase (may be > than number of the atom)
    # originlist: atoms to define origin (where 1 is first atom in group; <= natom)
    # vector1: list of 3 values with X, Y or Z, atom #a and #b (number as in origin)  (for example {X 1 3})
    # vector2: list of 3 values with X, Y or Z, atom #a and #b (number as in origin)
    # note that vector2 must define a different axis than vector1 
    # also and vector1 and vector2 cannot use the same atom pair
proc ExtractRigidBody {phase natom firstatom originlist vector1 vector2} {
    global expgui
    set fp [open "geom.inp" "w"]
    puts $fp "N"
    if {[llength ::expmap(phaselist)] > 1} {
       # select phase
       puts $fp "N"
       puts $fp $phase
       puts $fp "N"
    }
    puts $fp "R"
    puts $fp "$natom"
    puts $fp "$firstatom"
    puts $fp [llength $originlist]
    foreach i $originlist {
	puts $fp $i
    }
    foreach i [concat $vector1 $vector2] {
	puts $fp $i
    }
    puts $fp "0"
    puts $fp "X"
    close $fp
    #puts "[file join $expgui(gsasexe) geometry] $expgui(expfile) < geom.inp > geom.out"
    # Save any change sin the current exp file
    savearchiveexp
    catch {
	exec [file join $expgui(gsasexe) geometry] $expgui(expfile) < geom.inp > geom.out
    } err
    #puts $err
    file delete geom.inp
    set fp [open geom.out r]
    set origin {}
    set Euler {}
    set coordlist {}
    while {[gets $fp line] >= 0} {
	if {[string first "Cell coordinates of origin" $line] != -1} {
	    set origin [lrange [string range $line [string first "are" $line] end] 1 3]
            #puts "origin in rb = $origin"
	}
	if {[string first "Rotation angles" $line] != -1} {
	    set Euler {}
	    foreach i [lrange [split $line "="] 1 3] {
		lappend Euler [lindex $i 0]
	    }
	    #puts $line
	    #puts $Euler
	}
	if {[string first "Atom   Orthon" $line] != -1} {
	    set coordlist {}
	    for {set i 1} {$i <= $natom} {incr i} {
		gets $fp line
		set coord {}
		lappend coord [string trim [string range $line 9 15]]
		lappend coord [string trim [string range $line 16 22]]
		lappend coord [string trim [string range $line 23 29]]
		lappend coord [string trim [string range $line 0 8]]
		#puts $line
		#puts $coord
		lappend coordlist $coord
	    }
	    #puts $coordlist
	}
    }
    #file delete geom.out
    if {[llength $origin] == 0 || [llength $Euler] == 0 || [llength $coordlist] == 0} {
       puts "Error: run of GEOMETRY failed"
       error "Run of Program GEOMETRY failed, cannot continue"
    }
    return [list $origin $Euler $coordlist]
}

# RunRecalcRBCoords: updates the coordinates in a .EXP file after a rigid 
# body has been changed, mapped or the setting info is changed
proc RunRecalcRBCoords { } {
    global expgui tcl_platform
    set input [open resetmult.inp w]
    puts $input "Y"
    puts $input "l b"
    puts $input "n"
    puts $input "x x x"
    puts $input "x"
    close $input
    # Save the current exp file
    savearchiveexp
    # disable the file changed monitor
    set expgui(expModifiedLast) 0
    set expnam [file root [file tail $expgui(expfile)]]
    set err [catch {
	if {$tcl_platform(platform) == "windows"} {
	    exec [file join $expgui(gsasexe) expedt.exe] $expnam < resetmult.inp >& resetmult.out
	} else {
	    exec [file join $expgui(gsasexe) expedt] $expnam < resetmult.inp >& resetmult.out
	}
    } errmsg]
    loadexp $expgui(expfile)
    set fp [open resetmult.out r]
    set out [read $fp]
    close $fp
    set expgui(exptoolout) $out
    catch {file delete resetmult.inp resetmult.out}
    if {$err} {
	return $errmsg
    } else {
	return ""
    }
}


# compute a rotation matrix for orthogonal coordinates (based on MAKMATD in GSAS)
# rotate angle degrees around axis (1, 2 or 3) for (x, y, or z)
# returns a list that can be used as a matrix in the La package
proc RotMatrix {axis angle} {
    set ang [expr {$angle * acos(0) / 90.}]
    set mat "1 0 0 0 1 0 0 0 1"
    if {$axis == 1}  {
	set i1 1
	set i2 2
    } elseif {$axis == 2}  {
	set i1 2
	set i2 0
    } else {
	set i1 0
	set i2 1
    }
    proc imat {i1 i2} {return [expr {(3*$i2) + $i1}]}
    foreach item {
	{$i1 $i1 [expr {cos($ang)}]}
	{$i2 $i2 [expr {cos($ang)}]}
	{$i1 $i2 [expr {-sin($ang)}]}
	{$i2 $i1 [expr {sin($ang)}]}
    } {
	foreach {c r val} [subst $item] {}
	set mat [lreplace $mat [imat $c $r] [imat $c $r] $val]	
    }
    return "2 3 3 $mat"
}

# compute the derivative of the rotation matrix with respect to the angle, see RotMatrix
# (based on MAKMATD in GSAS)
# returns a list that can be used as a matrix in the La package
proc DerivRotMatrix {axis angle} {
    set ang [expr {$angle * acos(0) / 90.}]
    set mat "0 0 0 0 0 0 0 0 0"
    if {$axis == 1}  {
	set i1 1
	set i2 2
    } elseif {$axis == 2}  {
	set i1 2
	set i2 0
    } else {
	set i1 0
	set i2 1
    }
    proc imat {i1 i2} {return [expr {(3*$i2) + $i1}]}
    foreach item {
	{$i1 $i1 [expr {-sin($ang) * acos(0) / 90.}]}
	{$i2 $i2 [expr {-sin($ang) * acos(0) / 90.}]}
	{$i1 $i2 [expr {-cos($ang) * acos(0) / 90.}]}
	{$i2 $i1 [expr {cos($ang) * acos(0) / 90.}]}
    } {
	foreach {c r val} [subst $item] {}
	set mat [lreplace $mat [imat $c $r] [imat $c $r] $val]	
    }
    return "2 3 3 $mat"
}

# compute an orthogonalization matrix from cell parameters (based on AMATRX in GSAS)
# returns a list that can be used as a matrix in the La package
proc OrthoMatrix {a b c alpha beta gamma} {
    set CA [expr {cos($alpha * acos(0) / 90.)}]
    set CB [expr {cos($beta * acos(0) / 90.)}]
    set CG [expr {cos($gamma * acos(0) / 90.)}]
    set SA [expr {sin($alpha * acos(0) / 90.)}]
    set SB [expr {sin($beta * acos(0) / 90.)}]
    set SC [expr {sin($gamma * acos(0) / 90.)}]
    set CASTAR [expr { ($CB*$CG-$CA)/($SB*$SC) }]    ;#! cos(Alpha*)
    set CBSTAR [expr { ($CA*$CG-$CB)/($SA*$SC) }]    ;#! cos(Beta*)
    set CCSTAR [expr { ($CA*$CB-$CG)/($SA*$SB) }]    ;#! cos(Gamma*)
    set SASTAR [expr { sqrt(1.0-($CASTAR*$CASTAR*2)) }]    ;#! sin(Alpha*)
    set SBSTAR [expr { sqrt(1.0-($CBSTAR*$CBSTAR*2)) }]    ;#! sin(Beta*)
    set SCSTAR [expr { sqrt(1.0-($CCSTAR*$CCSTAR*2)) }]    ;#! sin(Gamma*)

    set A  "2 3 3      $a 0 0    0 $b 0    0 0 $c"
    set A1 "2 3 3     1.0 0 0    $CG [expr {$SASTAR*$SC}] [expr {-$CASTAR*$SC}]    $CB 0.0 $SB"
    #!This matrix is
    #!   (1.0      0.0            0.0             )
    #!   (cos(G)  sin(A*)*sin(G) -cos(A*)*sin(G)  )
    #!   (cos(B)   0.0            sin(B)          )
    return [La::transpose [La::mmult $A $A1]]
}

# compute the transformation matrix that converts a rigid body coordinates into fractional 
# coordinates
# arguments: 
#   rotations: a list of axes and angles to rotate: { {axis1 angle1} {axis2 angle2} ...} 
#              where axis1,... can be 1, 2 or 3 corresponding to the cartesian X, Y or Z axes
#   cellprms: a list with "a b c alpha beta gamma" in Angstroms and degrees
# returns a list that can be used as a matrix in the La package
proc CalcXformMatrix {rotations cellprms} {
    set prod {}
    foreach item $rotations {
	#puts $item
	set mat [eval RotMatrix $item]
	if {$prod == ""} {
	    set prod $mat
	} else {
	    set prod [La::mmult $prod $mat]
	}
    }
    #puts "--- rotation product ---"
    #puts [La::show $prod]

    set ortho [eval OrthoMatrix $cellprms]
    #puts "--- ortho ---"
    #puts [La::show $ortho]
    set deortho [La::msolve $ortho [La::mident 3] ]
    #puts "--- deortho ---"
    #puts [La::show $deortho]
    #puts "--- xform ---"
    set xform [La::mmult $deortho $prod]
    return $xform
}

# transforms a triplet of orthogonal coordinates into fractional ones using 
# arguments: 
#    xform: a transformation matrix from CalcXformMatrix
#    origin: a list of fraction coordinates {x y z} describing the location of the 
#            origin of the orthogonal coordinates in the crystal system
#    ortho: a triplet of othogonal coordinates
# returns a triplet of fractional coordinates
proc Ortho2Xtal {xform origin ortho} {
    set ocv "2 3 0 $ortho"
    set frac [La::mmult $xform $ocv]
    #puts [La::show [La::transpose $frac]]
    #puts $frac
    set frac [La::madd $frac "[lrange $frac 0 2] $origin"]
    #puts [La::show [La::transpose $frac]]
    return $frac
}

# compute the derivative of the transformation matrix (see CalcXformMatrix) 
# with respect to every rotation in the $rotations list
# arguments: 
#   rotations: a list of axes and angles to rotate: { {axis1 angle1} {axis2 angle2} ...} 
#              where axis1,... can be 1, 2 or 3 corresponding to the cartesian X, Y or Z axes
#   cellprms: a list with "a b c alpha beta gamma" in Angstroms and degrees
# returns a list of matrices where each matrix is a list that can be used as a 
# matrix in the La package
proc CalcDerivMatrix {rotations cellprms} {
    set ortho [eval OrthoMatrix $cellprms]
    set deortho [La::msolve $ortho [La::mident 3] ]
    set derivlist {}

    foreach item $rotations {
	#puts $item
	set mat [eval DerivRotMatrix $item]
	#puts $item
	#puts [La::show $mat]
	set xform [La::mmult $deortho $mat]
	lappend derivlist $xform
    }
    return $derivlist
}

# CalcBody: Calculate fractional coordinates using rigid body setting parameters
# arguments: 
#  Euler: a list of axes and angles to rotate: { {axis1 angle1} {axis2 angle2} ...} 
#              where axis1,... can be 1, 2 or 3 corresponding to the cartesian X, Y or Z axes
#  cell: a list with "a b c alpha beta gamma" in Angstroms and degrees
#  ortholist: list containing triplets with orthogonal coordinates 
#  origin: a list of fraction coordinates {x y z} describing the location of the 
#            origin of the orthogonal coordinates in the crystal system
#     note that the length of ortholist, useflag and fraclist should be the same
# Returns a list with the computed fractional coordinates for all atoms
proc CalcBody {Euler cell ortholist origin} {
    set xform [CalcXformMatrix $Euler $cell]
    set i 0
    set sumdvs 0
    set fracout {}
    set rmsout {}
    foreach oc $ortholist {
	set frac [lrange [Ortho2Xtal $xform $origin $oc] 3 end]
	lappend fracout $frac
    }
    return $fracout
}


# fit a rigid body's origin 
# arguments: 
#  Euler: a list of axes and angles to rotate: { {axis1 angle1} {axis2 angle2} ...} 
#              where axis1,... can be 1, 2 or 3 corresponding to the cartesian X, Y or Z axes
#  cell: a list with "a b c alpha beta gamma" in Angstroms and degrees
#  ortholist: list containing triplets with orthogonal coordinates 
#  useflag: list of flags to indicate if an atom should be used (1) or ignored (0)
#  fraclist: list containing triplets with fractional coordinates  
#  origin: a list of fraction coordinates {x y z} describing the location of the 
#            origin of the orthogonal coordinates in the crystal system
#     note that the length of ortholist, useflag and fraclist should be the same
# Returns a list with the following elements
#   0: a list with three new origin values
#   1: the root-mean square difference between the fraclist coordinates and those computed 
#      using the input values for those atoms where $use is one (in Angstroms)
#   2: the computed fractional coordinates for all atoms
#   3: individual rms values for all atoms (in Angstroms)
# note that items 1-3 are computed with the imput origin, not the revised one
proc FitBodyOrigin {Euler cell ortholist useflag fraclist origin} {
puts $fraclist
    set xform [CalcXformMatrix $Euler $cell]
    #puts "entering FitBodyOrigin"
    foreach var {x y z} {set sum($var) 0.0}
    set i 0
    set sumdvs 0
    set fracout {}
    set rmsout {}
    foreach oc $ortholist use $useflag coord $fraclist {
        #puts "ortho: $oc"
	set frac [lrange [Ortho2Xtal $xform $origin $oc] 3 end]
	lappend fracout $frac
	if {$use} {incr i}
	set dvs 0
	foreach var {x y z} v1 $frac v2 $coord abc [lrange $cell 0 2] {
	    #puts "v2 = $v2"
	    #puts "v1 = $v1"
	    #puts "abc = $abc"
	    set dv [expr {($v2 - $v1)*$abc}]
	    set dvs [expr {$dvs + $dv*$dv}]
	    set sumdvs [expr {$sumdvs + $dv*$dv}]
	    if {$use} {set sum($var) [expr {$sum($var) + $dv/$abc}]}
	    #puts "round and round"
	}
	lappend rmsout [expr {sqrt($dvs)}]
    }
    set rms 0
    if {$i > 1} {set rms [expr {sqrt($sumdvs)/$i}]}
    set neworig {}
    foreach var {x y z} o $origin {
	lappend neworig [expr {$o + ($sum($var)/$i)}]
    }
    return [list $neworig $rms $fracout $rmsout]
}

# fit a rigid body's Euler angles using least-squares
# arguments: 
#  Euler: a list of axes and angles to rotate: { {axis1 angle1} {axis2 angle2} ...} 
#              where axis1,... can be 1, 2 or 3 corresponding to the cartesian X, Y or Z axes
#  cell: a list with "a b c alpha beta gamma" in Angstroms and degrees
#  ortholist: list containing triplets with orthogonal coordinates 
#  useflag: list of flags to indicate if an atom should be used (1) or ignored (0)
#  fraclist: list containing triplets with fractional coordinates  
#  origin: a list of fraction coordinates {x y z} describing the location of the 
#            origin of the orthogonal coordinates in the crystal system
#     note that the length of ortholist, useflag and fraclist should be the same
# Returns a list of new Euler angles 
proc FitBodyRot {Euler cell ortholist useflag fraclist origin} {
    set xform [CalcXformMatrix $Euler  $cell]
    set derivlist [CalcDerivMatrix $Euler  $cell]
    set A "2 [expr 3*[llength $ortholist]] 3"
    foreach oc $ortholist use $useflag coord $fraclist {
	if {! $use} continue
	foreach deriv $derivlist {
	    foreach xyz [lrange [Ortho2Xtal $deriv "0 0 0" $oc] 3 end] {
		lappend A $xyz
	    }
	}
    }
    #puts "A: [La::show $A]"
    set y "2 [expr 3*[llength $ortholist]] 1"
    foreach oc $ortholist use $useflag coord $fraclist {
	if {! $use} continue
	set frac [lrange [Ortho2Xtal $xform $origin $oc] 3 end]
	foreach xyz $coord XYZ $frac {
	    lappend y [expr {$XYZ - $xyz}]
	}
    }

    set AtA [La::mmult [La::transpose $A] $A]
    set Aty [La::mmult [La::transpose $A] $y]
    
    set l {}
    #set shifts {}
    foreach delta [lrange [La::msolve $AtA $Aty] 3 end] item $Euler {
	#lappend shifts $delta
	lappend l "[lindex $item 0] [expr {$delta + [lindex $item 1]}]"
    }
    #puts "shifts = $shifts"
    return $l
}

# FitBody: fit a rigid body's Origin and Euler angles
# arguments: 
#  Euler: a list of axes and angles to rotate: { {axis1 angle1} {axis2 angle2} ...} 
#              where axis1,... can be 1, 2 or 3 corresponding to the cartesian X, Y or Z axes
#  cell: a list with "a b c alpha beta gamma" in Angstroms and degrees
#  ortholist: list containing triplets with orthogonal coordinates 
#  useflag: list of flags to indicate if an atom should be used (1) or ignored (0)
#  fraclist: list containing triplets with fractional coordinates  
#  origin: a list of fraction coordinates {x y z} describing the location of the 
#            origin of the orthogonal coordinates in the crystal system
#     note that the length of ortholist, useflag and fraclist should be the same
# Returns a list containing 
#   new origin
#   new Euler angles
#   total rms 
#   fractional coordinates
#   rms deviation in fractional coordinates of new Euler angles 
proc FitBody {Euler cell ortholist useflag fraclist origin "ncycle 5"} {
    #puts "start origin = $origin"
    foreach {
	origin 
	startrms 
	fracout 
	rmsout } [FitBodyOrigin $Euler $cell $ortholist $useflag $fraclist $origin] {}
    #puts "start rms = $startrms"
    set rmsprev $startrms
    #puts "new origin = $origin"
    for {set i 0} {$i < $ncycle} {incr i} {
	set Eulerprev $Euler
	set Euler [FitBodyRot $Euler $cell $ortholist $useflag $fraclist $origin]
	#puts "New Euler $Euler"
	#puts "after fit" 
	foreach {
	    origin 
	    rms 
	    fracout 
	    rmsout } [FitBodyOrigin $Euler $cell $ortholist $useflag $fraclist $origin] {}
	if {$rms > (1.1 * $rmsprev) + 0.01} {
	    #puts "rms = $rms, new origin = $origin"
	    set rmsprev $rms
	}
    } 
    #proc FitBodyOrigin {Euler cell ortholist useflag fraclist origin} 
    #return "$neworig $rms $fracout $rmsout"
    set fmt  {"%8.5f %8.5f %8.5f     %8.5f %8.5f %8.5f   %6.3f"}
    #foreach fracin $fraclist fraccalc $fracout rmsi $rmsout {
	#puts "[eval format $fmt $fracin $fraccalc $rmsi]"
    #}
    return [list $origin $Euler $rms $fracout $rmsout]
}

# zmat2coord: convert a z-matrix to a set of cartesian coordinates
#   a z-matrix is also known as "internal coordinates" or "torsion space"
#   (see Journal of Computational Chemistry, Vol 26, #10, p. 1063–1068, 2005 or
#    http://www.cmbi.ru.nl/molden/zmat/zmat.html)
# INPUT:
#   atmlist is a list of ascii lines where each line contains
#     lbl c1 distance c2 angle c3 torsion
#   where each atom is computed from the previous where the new atom is: 
#     distance $distance from atom $c1 (angstrom)
#     angle $angle from $c1--$c2 (degrees)
#     torsion $torsion from $c1--$c2--$c3 (degrees)
# OUTPUT:
#  zmat2coord returns a list of atom labels and cartesian coordinates, 
#  with 4 items in each element (label, x, y, z)
# this routine was tested against results from Babel via the web interface at 
# http://www.shodor.org/chemviz/zmatrices/babel.html and sample input at 
# http://iopenshell.usc.edu/howto/zmatrix/
proc zmat2coord {atmlist} { 
    set torad [expr {acos(0)/90.}]
    set i 0
    foreach line $atmlist {
	incr i
	foreach {lbl c1 dist c2 angle c3 torsion} $line {} 
	if {$i == 1} {
	    set atm(1) [list $lbl 0 0 0] ; # 1st atom is at origin
	} elseif {$i == 2} {
	    set dist1 $dist
	    set atm(2) [list $lbl $dist1 0 0] ; # 2nd atom is along x-axis
	} elseif {$i == 3} {
	    # 3rd atom can be bonded to the 1st or 2nd
	    if {$c1 == 1} {
		set atm(3) [list $lbl \
				[expr {$dist * cos($torad * $angle)}] \
				[expr {$dist * sin($torad * $angle)}] \
				0]
	    } else {
		set atm(3) [list $lbl \
				[expr {$dist1 - $dist * cos($torad * $angle)}] \
				[expr {$dist * sin($torad * $angle)}] \
				0]
	    }
	} else {
	    set atm($i) [concat $lbl \
			     [ahcat "atm" $c1 $dist $c2 $angle $c3 $torsion]]
	}
    }
    set coordlist {}
    foreach key [lsort -integer [array names atm]] {
	lappend coordlist $atm($key)
    }
    return $coordlist
}
# Compute the length of a vector
proc vlen {a} {
    set sum 0.0
    foreach ai $a {
	set sum [expr {$sum + $ai*$ai}]
    }
    return [expr sqrt($sum)]
}
# compute vector (a + z * b) and optionally normalize to length d
proc vadd {a b d z} {
    set c {}
    foreach ai $a bi $b {
        lappend c [expr {$bi + $z * $ai}]
    }
    set v [vlen $c]
    if {$d != 0} {
	set r {}
	foreach ci $c {
	    lappend r [expr {$d * $ci / $v}]
	}
	return [list $v $r]
    }
    return [list $v $c]
}
# normalize a vector
proc vnrm {x} {
    set v [vlen $x]
    if {abs($v) < 1e-8} {return [list 0 0 0]}
    set y {}
    foreach xi $x {
	lappend y [expr {$xi / $v}]
    }
    return $y
}
# compute the coordinates for an atom that is bonded:
#   distance $dist from atom $nc
#   angle $bondang from $nc--$nb
#   torsion $torsang from $nc--$nb--$na
#   coordinates are found in array $atmarr in the calling routine
# based on a Fortran routine provided by Peter Zavalij (Thanks Peter!)
proc ahcat {atmarr nc dist nb bondang na torsang} {
    upvar 1 $atmarr atm
    set xa [lrange $atm($na) 1 3]
    set xb [lrange $atm($nb) 1 3]
    set xc [lrange $atm($nc) 1 3]
    set torad [expr {acos(0)/90.}]
    # x = unit Vector A-B
    foreach {x1 x2 x3} [lindex [vadd $xb $xa 1. -1.] 1] {}
    # y = unit Vector C-B
    set y [lindex [vadd $xb $xc 1. -1.] 1]
    foreach {y1 y2 y3} $y {}
    set z1 [expr {$x2*$y3 - $x3*$y2}]
    set z2 [expr {$x3*$y1 - $x1*$y3}]
    set z3 [expr {$x1*$y2 - $x2*$y1}]
    set z [vnrm [list $z1 $z2 $z3]]
    set q1 [expr {$y2*$z3 - $y3*$z2}]
    set q2 [expr {$y3*$z1 - $y1*$z3}]
    set q3 [expr {$y1*$z2 - $y2*$z1}]
    set q [vnrm [list $q1 $q2 $q3]]
    set th [expr {$bondang * $torad}]
    set ph [expr {-1. * $torsang * $torad}]
    set cth [expr {cos($th)}]
    set sth [expr {sin($th)}]
    set cph [expr {cos($ph)}]
    set sph [expr {sin($ph)}]
    set xh {}
    foreach xci $xc xi $q zi $z yi $y {
	lappend xh [expr {
			  $xci +
			  $dist*($sth*($cph*$xi + $sph*$zi)-$cth*$yi)
		      }]
    }
    return $xh
}
 
# RB2cart: convert the rigid body representation reported as the 2nd element 
# in ReadRigidBody into cartesian coordinates
#   rblist: a list containing an element for each scaling factor
# in each element there are four items: 
#    a multiplier value for the rigid body coordinates
#    a damping value (0-9) for the refinement of the multiplier (not used)
#    a variable number if the multiplier will be refined (not used)
#    a list of cartesian coordinates coordinates 
# each cartesian coordinate contains 4 items: x,y,z and a label
# returns a list of coordinate triplets
proc RB2cart {rblist} {
    foreach item $rblist {
	foreach {mult damp ref coords} $item {}
	set i 0
	foreach xyz $coords {
	    foreach {x y z} [lrange $xyz 0 2] {}
	    foreach val [lrange $xyz 0 2] var {X Y Z} {
		if {[array names $var $i] == ""} {
		    set ${var}($i) [expr {$mult * $val}]
		} else {
		    set ${var}($i) [expr {[set ${var}($i)] + $mult * $val}]
		}
	    }
	    incr i
	}
    }
    set out ""
    foreach i [lsort -integer [array names X]] {
	lappend out [list $X($i) $Y($i) $Z($i)]
    }
    return $out
}

# get the name of the DRAWxtl application, if installed
proc GetDRAWxtlApp {} {
    # is DRAWxtl installed?
    set app {}
    if {![catch {set fp [open [file join $::env(HOME) .drawxtlrc] r]}]} {
	# line 12 is name of executable
	set i 0
	while {$i < 12} {
	    incr i
	    gets $fp appname
	}
	close $fp
	set app [auto_execok $appname]
    }
    if {$app != ""} {
	return $appname
    }
    return ""
}

# DRAWxtlPlotOrtho: plot orthogonal coordinates in DRAWxtl
# input:
#  filename: file name for the .str file to create
#  title: string for title in .str file
#  coords: cartesian coordinates
#  bondlist: list of bonds to draw as min, max length (A) and 
#      an optional color; for example: {{1.4 1.6} {1.2 1.3 Red}}
proc DRAWxtlPlotOrtho {filename title coords bondlist} {
    foreach {xmin ymin zmin} {"" "" ""} {}
    foreach {xmax ymax zmax} {"" "" ""} {}
    foreach xyz $coords {
	foreach {x y z} $xyz {}
	foreach s {x y z} {
	    foreach t {min max} {
		if {[set ${s}${t}] == ""} {set ${s}${t} [set $s]}
	    } 
	    if {[set ${s}min] > [set $s]} {set ${s}min [set $s]}
	    if {[set ${s}max] < [set $s]} {set ${s}max [set $s]}
	}
    }
    #puts "$xmin $xmax $ymin $ymax $zmin $zmax"
    set max $xmin
    foreach val "$xmin $xmax $ymin $ymax $zmin $zmax" {
	if {$max < abs($val)} {set max $val}
    }
    set scale [expr {4.*$max}]
    set a 10.
    lappend range [expr -0.01+($xmin/$scale)] [expr 0.01+($xmax/$scale)] \
	[expr -0.01+($ymin/$scale)] [expr 0.01+($ymax/$scale)] \
	[expr -0.01+($zmin/$scale)] [expr 0.01+($zmax/$scale)]
    set fp [open $filename w]
    puts $fp "title $title"
    puts $fp "box  0.000 Black"
    puts $fp "background White"
    #puts $fp "nolabels"
    puts $fp "cell $a $a $a 90 90 90"
    puts $fp "spgr P 1"
    puts $fp "pack $range"
    set i 0
    foreach xyz $coords {
	foreach {x y z} $xyz {}
	incr i
	puts $fp "atom c $i [expr {$x/$scale}] [expr {$y/$scale}] [expr {$z/$scale}]"
	puts $fp "labeltext [expr {0.02 + $x/$scale}] [expr {0.01 + $y/$scale}] [expr {0.01 + $z/$scale}] $i"
    }
    puts $fp "sphere c  [expr 0.100*($a/$scale)] Red"
    puts $fp "finish   0.70   0.30   0.08   0.01"
    foreach bondpair $bondlist {
	foreach {b1 b2 color} $bondpair {}
	if {$color == ""} {set color Red}
	puts $fp "bond c c [expr {0.01*$a/$scale}] [expr {$b1*$a/$scale}] [expr {$b2*$a/$scale}] $color"
    }
    puts $fp "frame"
    set range {}
    lappend range -0.01 [expr 0.01+(0.1*$a/$scale)] \
	-0.01 [expr 0.01+(0.1*$a/$scale)] \
	-0.01 [expr 0.01+(0.1*$a/$scale)]
    puts $fp "cell $a $a $a 90 90 90"
    puts $fp "spgr P 1"
    puts $fp "pack $range"
    puts $fp "atom o 1 0 0 0"
    puts $fp "atom o 2 [expr {0.1*$a/$scale}] 0 0"
    puts $fp "atom o 3 0 [expr {0.1*$a/$scale}] 0"
    puts $fp "atom o 4 0 0 [expr {0.1*$a/$scale}]"
    puts $fp "bond o o [expr {0.01*$a/$scale}] [expr {-0.1 + $a/$scale}] [expr {0.1 + $a/$scale}] Black"
    puts $fp "labelscale 0.5"
    puts $fp "labeltext [expr {0.11*$a/$scale}] 0 0 x"
    puts $fp "labeltext 0 [expr {0.11*$a/$scale}] 0 y"
    puts $fp "labeltext 0 0 [expr {0.11*$a/$scale}] z"
    puts $fp "sphere o [expr {0.02*$a/$scale}] Blue"
    puts $fp "origin   .0 .0 .0"
    puts $fp "end"
    close $fp
}

# PlotRBtype: plot a rigid body in DRAWxtl
# input:
#  rbtype: # of rigid body
#  bondlist: list of bonds to draw as min, max length (A) and 
#      an optional color; for example: {{1.4 1.6} {1.2 1.3 Red}}
#  file: file name for the .str file to create
proc PlotRBtype {rbtype "bondlist {}" "file {}"} {
    set app [GetDRAWxtlApp]
    if {$app == ""} {
	MyMessageBox -parent . -title "No DRAWxtl" \
		-message "Sorry, DRAWxtl is not installed" \
		-icon warning
	return
    }
    if {$::tcl_platform(platform) == "windows" && $file == ""} {
	set file [file join [pwd] rbplot.str]
    } else {
	set file "/tmp/rbplot.str"
    }
    set coords [RB2cart [lindex [ReadRigidBody $rbtype] 1]]
    DRAWxtlPlotOrtho $file "" $coords $bondlist
    if {$app != ""} {exec $app $file &}
}

# PlotRBcoords: plot orthogonal coordinates in DRAWxtl
# input:
#  coords: cartesian coordinates
#  bondlist: list of bonds to draw as min, max length (A) and 
#      an optional color; for example: {{1.4 1.6} {1.2 1.3 Red}}
#  file: file name for the .str file to create
proc PlotRBcoords {coords "bondlist {}" "file {}"} {
    set app [GetDRAWxtlApp]
    if {$app == ""} {
	MyMessageBox -parent . -title "No DRAWxtl" \
		-message "Sorry, DRAWxtl is not installed" \
		-icon warning
	return
    }
    if {$::tcl_platform(platform) == "windows" && $file == ""} {
	set file [file join [pwd] rbplot.str]
    } else {
	set file "/tmp/rbplot.str"
    }
    DRAWxtlPlotOrtho $file "" $coords $bondlist
    if {$app != ""} {exec $app $file &}
}

# DRAWxtlPlotRBFit: plot a set of fraction coordinates superimposed 
# on a structure read from a phase
# input:
#  RBcoords: fractional coordinates for rigid body
#  phase:# of phase to plot
#  firstatom: seq # of 1st atom in structure to be mapped to rigid body
#  allatoms: 0 to plot only atoms in phase that are in the rigid body, 
#      otherwise plot all atoms
#  bondlist: list of bonds to draw for the phase as min, max length (A) and 
#      an optional color; for example: {{1.4 1.6} {1.2 1.3 Red}}
#  rbbondlist: list of bonds to draw for the phase as min, max length (A) and 
#      an optional color; for example: {{1.4 1.6} {1.2 1.3 Red}}
#  file: optional file name for the .str file to create
proc DRAWxtlPlotRBFit {RBcoords phase firstatom "allatoms 0" \
			   "bondlist {}" "rbbondlist {}" "file {}"} {
    set natom [llength $RBcoords]
    set app [GetDRAWxtlApp]
    if {$app == ""} {
	MyMessageBox -parent . -title "No DRAWxtl" \
		-message "Sorry, DRAWxtl is not installed" \
		-icon warning
	return
    }
    if {$::tcl_platform(platform) == "windows" && $file == ""} {
	set file [file join [pwd] rbplot.str]
    } else {
	set file "/tmp/rbfit.str"
    }

    # get rigid body coordinate range
    foreach {xmin ymin zmin} {"" "" ""} {}
    foreach {xmax ymax zmax} {"" "" ""} {}
    foreach xyz $RBcoords {
	foreach {x y z} $xyz {}
	foreach s {x y z} {
	    foreach t {min max} {
		if {[set ${s}${t}] == ""} {set ${s}${t} [set $s]}
	    } 
	    if {[set ${s}min] > [set $s]} {set ${s}min [set $s]}
	    if {[set ${s}max] < [set $s]} {set ${s}max [set $s]}
	}
    }
    set rbrange {}
    foreach val [list [expr -0.01+$xmin] [expr 0.01+$xmax] \
		     [expr -0.01+$ymin] [expr 0.01+$ymax] \
		     [expr -0.01+$zmin] [expr 0.01+$zmax] ] {
	append rbrange [format " %8.4f" $val]
    }
    set rbcenter [list [expr {($xmin+$xmax)/2}] \
		      [expr {($ymin+$ymax)/2}] \
		      [expr {($zmin+$zmax)/2}] ]
    # get matching atoms coordinate range
    set firstind [lsearch $::expmap(atomlist_$phase) $firstatom]
    set matchedatomlist [lrange \
		      [lrange $::expmap(atomlist_$phase) $firstind end] \
		      0 [expr {$natom-1}]]
    foreach atom $matchedatomlist {
	foreach s {x y z} {
	    set $s [atominfo $phase $atom $s]
	    foreach t {min max} {
		if {[set ${s}${t}] == ""} {set ${s}${t} [set $s]}
	    } 
	    if {[set ${s}min] > [set $s]} {set ${s}min [set $s]}
	    if {[set ${s}max] < [set $s]} {set ${s}max [set $s]}
	}
    }
    # expand to cover at least one unit cell
    foreach var {xmin ymin zmin} { 
	if {[set $var] > 0.0} {set $var 0.0}
    }
    foreach var {xmax ymax zmax} { 
	if {[set $var] < 1.} {set $var 1.}
    }
    set range {}
    foreach val [list [expr -0.01+$xmin] [expr 0.01+$xmax] \
		     [expr -0.01+$ymin] [expr 0.01+$ymax] \
		     [expr -0.01+$zmin] [expr 0.01+$zmax]] {
	append range [format " %8.4f" $val]
    }

    set fp [open $file w]
    puts $fp "title structure/rigid-body fit plot"
    # plot the structure
    puts -nonewline $fp "cell"
    foreach p {a b c alpha beta gamma} {
	puts -nonewline $fp " [phaseinfo $phase $p]"
    }
    puts $fp ""
    puts $fp "spgp [phaseinfo $phase spacegroup]"
    puts $fp "pack $range"
    if {$allatoms != 0} {
	set atoms $::expmap(atomlist_$phase)
    } else {
	set firstind [lsearch $::expmap(atomlist_$phase) $firstatom]
	set atoms [lrange \
		       [lrange $::expmap(atomlist_$phase) $firstind end] \
		       0 [expr {$natom-1}]]
    }

    # set origin at center of rigid body
    puts $fp "origin  $rbcenter"
    # now loop over atoms
    foreach atom $atoms {
	set type [atominfo $phase $atom type]
	set typelist($type) 1
	set xyz ""
	foreach v {x y z} {
	    append xyz "[atominfo $phase $atom $v] "
	}
	puts $fp "atom $type $atom $xyz"
	if {[lsearch $matchedatomlist $atom] != -1} {
	    puts $fp "labeltext $xyz $atom"
	}
		
	set uiso [atominfo $phase $atom Uiso]
	# are there anisotropic atoms? If so convert them to Uequiv
	if {[atominfo $phase $atom temptype] == "A"} {
	    puts -nonewline $fp "Uij [atominfo $phase $atom type] $atom "
	    foreach v {U11 U22 U33 U12 U13 U23} {
		puts -nonewline $fp "[atominfo $phase $atom $v] "
	    }
	    puts $fp ""
	}
    }

    foreach type [array names typelist] color {Green Blue Magenta Cyan} {
	if {$type == ""} break
	puts $fp "sphere $type 0.1 $color"
    }
    foreach type [array names typelist] color1 {Green Blue Magenta Cyan} {
	foreach bondpair $bondlist {
	    foreach {b1 b2 color} $bondpair {}
	    if {$color == ""} {set color $color1}
	    puts $fp "bond $type $type 0.02 $b1 $b2 $color"
	}
	foreach type1 [array names typelist] {
	    if {$type1 == $type} break
	    foreach bondpair $bondlist {
		foreach {b1 b2 color} $bondpair {}
		if {$color == ""} {set color $color1}
		puts $fp "bond $type $type1 0.02 $b1 $b2 $color"
	    }
	}
    }
    # plot the rigid body
    puts $fp "frame"
    puts -nonewline $fp "cell"
    foreach p {a b c alpha beta gamma} {
	puts -nonewline $fp " [phaseinfo $phase $p]"
    }
    puts $fp ""
    puts $fp "background White"
    #puts $fp "nolabels"
    puts $fp "labelscale 0.5"
    puts $fp "spgr P 1"
    puts $fp "pack $rbrange"
    set i 0
    foreach xyz $RBcoords {
	foreach {x y z} $xyz {}
	incr i
	puts $fp "atom c $i $x $y $z"
	puts $fp "labeltext $x $y $z r$i"
    }
    foreach bondpair $rbbondlist {
	foreach {b1 b2 color} $bondpair {}
	if {$color == ""} {set color Red}
	puts $fp "bond c c 0.02 $b1 $b2 $color"
    }

    puts $fp "sphere c 0.05 Red"
    puts $fp "finish   0.70   0.30   0.08   0.01"
    puts $fp "end"

    #puts $fp "bond o o [expr {0.01*$a/$scale}] [expr {-0.1 + $a/$scale}] [expr {0.1 + $a/$scale}] Black"
    close $fp
    MyMessageBox -parent . -title "Info" \
		-message "Note that the phase is drawn in green, blue, cyan & magenta and the rigid body in red."
    if {$app != ""} {exec $app $file &}
}


#AddRigidBody {1} { {{0 0 0 xe} {1 1 1 o} {2 2 2 si+4}} }
#puts [GetRB 1 6 8 "1 2" "X 1 2" "Y 1 3"]
#puts [GetRB 1 4 8 "1" "X 1 2" "Z 3 4"]
#MapRigidBody 1 1 7 ".11 .22 .33" "11 12 13"


#AddRigidBody {1} { {
#    {1 1 1 o} {-1 1 1 o} {1 -1 1 o} {-1 -1 1 o} 
#    {1 1 -1 o} {-1 1 -1 o} {1 -1 -1 o} {-1 -1 -1 o} 
#} }
#set n [MapRigidBody 1 1 1 ".2 .3 .4" "13 17 19"]
#puts "body $n created"
#incr expgui(changed)
#RunRecalcRBCoords
#puts "press Enter to continue"
#gets stdin line
#MapRigidBody 1 1 $n ".5 .5 .5" "0 0 0"
#incr expgui(changed)
#RunRecalcRBCoords

#puts "Test FitBody"
set fraclist {
    { 0.5483305238484277 0.4887545024531055 0.6167996784631056 }
    { 0.1036801409356145 0.5954016321779562 0.5129448102437683 }
    { 0.26404665760133855 0.09455414439078394 0.612655365147539 }
    { -0.18060372531147473 0.20120127411563465 0.5088004969282018 }
    { 0.5806037253114747 0.3987987258843653 0.2911995030717982 }
    { 0.13595334239866147 0.5054458556092161 0.18734463485246095 }
    { 0.2963198590643855 0.004598367822043814 0.2870551897562318 }
    { -0.1483305238484277 0.1112454975468945 0.1832003215368945 }
}
set ortholist {
    {1 1 1} 
    {-1 1 1}
    {      1.000000   -1.000000    1.000000}
    {     -1.000000   -1.000000    1.000000}
    {      1.000000    1.000000   -1.000000}
    {     -1.000000    1.000000   -1.000000}
    {      1.000000   -1.000000   -1.000000}
    {     -1.000000   -1.000000   -1.000000} 
}
# test code, generates DRAWxtl imput file from orthogonal coordinate list
# with bonds of ~2, 2.8 and 3.4 A
#DRAWxtlPlotOrtho test4.str "test file" $ortholist {{1.9 2.1} {3.4 3.5 Blue} {2.8 2.83 Green} }

# test code, plots rigid body type #2 with bonds drawn at ~1.3 & 2 A
#PlotRBtype 2 {{1.9 2.1} {1.28 1.32}}

# test code, plots rigid body coords in ortholist with bonds @  ~2, 2.8 and 3.4 A
#PlotRBcoords $ortholist {{1.9 2.1} {3.4 3.5 Blue} {2.8 2.83 Green} }


set useflag {1 1 1 1 1 1 1 1}
set cell {4.  5.  6.  95.  100.  105.}
#set origin ".20 .30 .40"
set origin ".0 .0 .0"
#set Euler  {{1 13} {2 17} {3 19}}
#set Euler  {{1 0} {2 180} {3 0}}
set Euler  {{1 0} {2 0} {3 0}}

#puts [La::show $xform]
#puts "out: [FitBody $Euler $cell $ortholist $useflag $fraclist $origin 30]"


# test zmat2coord
set atmlist {
    {C1 0 0.0 0 0.0 0 0.0}
    {O2 1 1.20 0 0.0 0 0.0}
    {H3 1 1.10 2 120.0 0 0.0}
    {C4 1 1.50 2 120.0 3 180.0}
    {H5 4 1.10 1 110.0 2 0.00}
    {H6 4 1.10 1 110.0 2 120.0}
    {H7 4 1.10 1 110.0 2 -120.0}
}
#  C        0.00000        0.00000        0.00000
#  O        1.20000        0.00000        0.00000
#  H       -0.55000        0.95263        0.00000
#  C       -0.75000       -1.29904       -0.00000
#  H       -0.04293       -2.14169       -0.00000
#  H       -1.38570       -1.36644        0.89518
#  H       -1.38570       -1.36644       -0.89518
# set coordlist [zmat2coord $atmlist]
 set i 0
# puts "\nZmatrix in"
# foreach line $atmlist {
#     incr i
#     puts "$i) $line"
# }
# puts "Cartesian out"
# foreach line $coordlist {
#     puts [eval format "%-4s%10.5f%10.5f%10.5f" $line]
# }

# AddRigidBody {1 0.75} { 
#     {
# 	{1 1 1 c} 
# 	{-1 1 1 c}
# 	{      1.000000   -1.000000    1.000000 c}
# 	{     -1.000000   -1.000000    1.000000 c}
# 	{      1.000000    1.000000   -1.000000 c}
# 	{     -1.000000    1.000000   -1.000000 c}
# 	{      1.000000   -1.000000   -1.000000 c}
# 	{     -1.000000   -1.000000   -1.000000 c} 
# 	{1 1 1 h} 
# 	{1 -1 -1 h} 
# 	{-1 1 -1 h} 
# 	{-1 -1 1 h} 
#     } {
# 	{0 0 0 c }
# 	{0 0 0 c}
# 	{0 0 0 c}
# 	{0 0 0 c}
# 	{0 0 0 c}
# 	{0 0 0 c}
# 	{0 0 0 c}
# 	{0 0 0 c}
# 	{1 1 1 h} 
# 	{1 -1 -1 h} 
# 	{-1 1 -1 h} 
# 	{-1 -1 1 h} 
#     }
# }
# MapRigidBody 2 2 1 {0 0 0} {10 15 20}