# $Id: readinst.tcl 1251 2014-03-10 22:17:29Z toby $
# Routines to deal with reading and writing instrument parameter files

# test an argument if it is a valid number; reform the number to fit
proc validreal {val length decimal} {
    upvar $val value
    if [catch {expr {$value}}] {return 0}
    if [catch {
	# for small values, switch to exponential notation
	# 2 -> three sig figs.
	set pow [expr 2 - $decimal]
	if {abs($value) < pow(10,$pow) && $length > 6} {
	    if {$length - $decimal < 5} {set decimal [expr $length -5]}
	    set tmp [format "%${length}.${decimal}E" $value]
	} else {
	    set tmp [format "%${length}.${decimal}f" $value]
	}
	# if the string will not fit, use scientific notation & drop 
	# digits, as needed
	while {[string length $tmp] > $length && $decimal >= 0} {
	    # try to make it fit
	    set tmp [format "%${length}.${decimal}E" $value]
	    incr decimal -1
	}
	set value $tmp
    }] {return 0}
    return 1
}

# test an argument if it is a valid integer; reform the number into
# an integer, if appropriate -- be sure to pass the name of the variable not the value
proc validint {val length} {
    upvar $val value
    # FORTRAN type assumption: blank is 0
    if {$value == ""} {set value 0}
    if [catch {
	set tmp [expr {round($value)}]
	if {$tmp != $value} {return 0}
	set value [format "%${length}d" $tmp]
    }] {return 0}
    return 1
}

proc instload {instfile} {
    global instarray tcl_platform
    if [catch {set fil [open "$instfile" r]}] {
	tk_dialog .instFileErrorMsg "File Open Error" \
		"Unable to open file $instfile" error 0 "Exit" 
	return -1
    }
    fconfigure $fil -translation lf
    set len [gets $fil line]
    if {[string length $line] != $len} {
	tk_dialog .instConvErrorMsg "old tcl" \
		"You are using an old version of Tcl/Tk and your instrument parameter file has binary characters; run convstod or upgrade" \
		error 0 "Exit"
	return -1
    }
    catch {
	unset instarray
    }
    if {$len > 160} {
	set fmt 0
	# a UNIX-type file
	set i1 0
	set i2 79
	while {$i2 < $len} {
	    set nline [string range $line $i1 $i2]
	    incr i1 80
	    incr i2 80
	    set key [string range $nline 0 11]
	    set instarray($key) [string range $nline 12 end]
	}
    } else {
	set fmt 1
	while {$len > 0} {
	    set key [string range $line 0 11]
	    set instarray($key) [string range $line 12 79]
	    if {$len != 81 || [string range $line end end] != "\r"} {set fmt 2}
	    set len [gets $fil line]
	}
    }
    close $fil
    return $fmt
}

proc instInit {} {
    global instarray
    catch {unset instarray}
    # create a blank key to show columns, not required but sort of a tradition
    set key "            "
    foreach i {1 2 3 4 5 6} {
	append instarray($key) 1234567890
    }
}

# write the instrument parameter file
proc instwrite {instfile} {
    global instarray
    set blankline \
     "                                                                        "
    # count the number of "banks" and set the INS   BANK record accordingly
    set i 1
    set bank 0
    while {[instexistsrec [format "INS%3d*" $i]] != 0} {
	set bank $i
	incr i
    }
    set key "INS   BANK"
    if {[instexistsrec $key] == 0} {instmakerec $key}
    set value $bank
    validint value 5
    instsetrec $key $value 1 5

    # open the file and write all the records
    set fp [open ${instfile} w]
    fconfigure $fp -translation crlf -encoding ascii
    set keylist [lsort [array names instarray]]
    foreach key $keylist {
	puts $fp [string range \
		"$key$instarray($key)$blankline" 0 79]
    }
    close $fp
}

# return the value for a ISAM key
proc instgetrec {key} {
    global instarray
    # truncate long keys & pad short ones
    set key [string range "$key        " 0 11]
    if [catch {set val $instarray($key)}] {
	#global expgui
	#if $expgui(debug) {puts "Error accessing record $key"}
	return ""
    }
    return $val
}

# return the number of records matching ISAM key (may contain wildcards)
proc instexistsrec {key} {
    global instarray
    # key can contain wild cards so don't pad
    return [llength [array names instarray $key]]
}

# replace a section of the instarray with $value 
#   replace $char characters starting at character $start (numbered from 1)
proc instsetrec {key value start chars} {
    global instarray
    # truncate long keys & pad short ones
    set key [string range "$key        " 0 11]
    if [catch {set instarray($key)}] {
	#global expgui
	#if $expgui(debug) {puts "Error accessing record $key"}
	return ""
    }

    # pad value to $chars 
    set l0 [expr {$chars - 1}]
    set value [string range "$value                                           " 0 $l0]

    if {$start == 1} {
	set ret {}
	set l1 $chars
    } else {
	set l0 [expr {$start - 2}]
	set l1 [expr {$start + $chars - 1}]
	set ret [string range $instarray($key) 0 $l0]
    }
    append ret $value [string range $instarray($key) $l1 end]
    set instarray($key) $ret
}

proc instmakerec {key} {
    global instarray
    # truncate long keys & pad short ones
    set key [string range "$key        " 0 11]
    if [catch {set instarray($key)}] {
	# set to 68 blanks
	set instarray($key) [format %68s " "]
    }
}

# delete an inst record
# returns 1 if OK; 0 if not found
proc instdelrec {key} {
    global instarray
    # truncate long keys & pad short ones
    set key [string range "$key        " 0 11]
    if [catch {unset instarray($key)}] {
	return 0
    }
    return 1
}

# get/set info from instrument parameter file
#    bank & type 
proc instinfo {parm "action get" "value {}"} {
    switch ${parm}-$action {
	bank-get {
	   return [string trim [string range [instgetrec "INS   BANK"] 0 4]]
	}
	type-get {
	   return [string range [instgetrec "INS   HTYPE"] 2 5]
	}
	type-set {
	    set key "INS   HTYPE"
	    if {[instexistsrec $key] == 0} {instmakerec $key}
	    instsetrec $key $value 3 4 	    
	}
	default {
	    set msg "Unsupported instinfo access: parm=$parm action=$action"
	    tk_dialog .badinst "Error in instinfo" $msg error 0 Exit 
	}
    }
    return 1
}

# get/set parameters for a bank
#   rad (radiation type) 0 to 5: other, Cr, Fe, Cu, Mo or Ag K

#   header (spectrum header)
#   name (used in GSAS2CIF)
#   itype (incident spectrum type) "ITYP,TMIN,TMAX,CHKSUM"  (0, 0, 180, 1 for CW)
#   icons (instrument constants)  "DIFC,DIFA,ZERO,POLA,IPOLA,KRATIO"
#                                 "WAV1,WAV2,ZERO,POLA,IPOLA,KRATIO"

proc instbankinfo {parm bank "action get" "value {}"} {
    set key [format INS%3d $bank]
    switch ${parm}-$action {
	rad-get {
	    return [string trim [string range [instgetrec "${key} IRAD"] 0 4]]
	}
	rad-set {
	    append key " IRAD"
	    if {[instexistsrec $key] == 0} {instmakerec $key}
	    if ![validint value 5] {return 0}
	    instsetrec $key $value 1 5
	}
	head-get {
	    return [string trim [string range [instgetrec "${key}I HEAD"] 2 end]]
	}
	head-set {
	    append key "I HEAD"
	    if {[instexistsrec $key] == 0} {instmakerec $key}
	    instsetrec $key $value 3 68
	}
	name-get {
	    return [string trim [string range [instgetrec "${key}INAME"] 2 end]]
	}
	name-set {
	    append key "INAME"
	    if {[instexistsrec $key] == 0} {instmakerec $key}
	    instsetrec $key $value 3 68
	}
	itype-get {
	    set line [instgetrec "${key}I ITYP"]
	    return [list \
		    [string trim [string range $line 0 4]] \
		    [string trim [string range $line 5 14]] \
		    [string trim [string range $line 15 24]] \
		    [string trim [string range $line 30 34]] \
		    ]
	}
	itype-set {
	    append key "I ITYP"
	    if {[instexistsrec $key] == 0} {instmakerec $key}
	    set line {}
	    foreach v $value fmt "%5d %10.4f %10.4f %10d" {
		if {[catch {
		    if {[string trim $v] == ""} {set v 0}
		    append line [format $fmt $v]
		} err]} {catch {puts $err}; return 0}
	    }
	    instsetrec $key $line 1 35
	}
	icons-get {
	    set line [instgetrec "${key} ICONS"]
	    return [list \
		    [string trim [string range $line 0 9]] \
		    [string trim [string range $line 10 19]] \
		    [string trim [string range $line 20 29]] \
		    [string trim [string range $line 40 49]] \
		    [string trim [string range $line 50 54]] \
		    [string trim [string range $line 55 64]] \
		    ]
	}
	icons-set {
	    append key " ICONS"
	    if {[instexistsrec $key] == 0} {instmakerec $key}
	    set line {}
	    foreach v $value \
		    fmt {%10.4f %10.4f %10.4f "          %10.3f" %5d %10.3f} {
		if {[catch {
		    if {[string trim $v] == ""} {set v 0}
		    append line [format $fmt $v]
		} err]} {return 0}
	    }
	    instsetrec $key $line 1 65
	}
	default {
	    set msg "Unsupported instinfo access: parm=$parm action=$action"
	    tk_dialog .badinst "Error in instbankinfo" $msg error 0 Exit 
	}
    }
    return 1
}

# read and set the profile terms
proc instprofinfo {bank profile "action get" "value {}"} {
    set key [format INS%3d $bank]PRCF[format %1d $profile]
    if {$action == "get"} {
	if {[instexistsrec "$key "] == 0} {return}
	set line [instgetrec "${key} "]
	set type [string trim [string range $line 0 4]]
	set terms [string trim [string range $line 5 9]]
	if {$terms == ""} {set terms 0}
	set cutoff [string trim [string range $line 10 19]]
	set termlist {}
	catch {
	    set i 1
	    set j 0
	    while {$j < $terms} {
		if {($j % 4) == 0} {
		    set line {}
		    if {[instexistsrec "$key "] != 0} {
			set line [instgetrec "${key}$i"]
		    }
		}
		set col1 [expr {($j % 4) * 15}]
		set col2 [expr {$col1 + 15}]
		set p [string trim [string range $line $col1 $col2]]
		if {$p == ""} {set p 0.0}
		lappend termlist $p
		if {($j % 4) == 3} {
		    incr i
		}
		incr j
	    }
	}
	return [list $type $cutoff $termlist]
    } elseif {$action == "set"} {
	if {[instexistsrec "$key "] == 0} {instmakerec "$key "}
	foreach {type cutoff termlist} $value {}
	set terms [llength $termlist]
	if ![validint type 5] {return 0}
	if ![validint terms 5] {return 0}
	if ![validreal cutoff 10 5] {return 0}
	instsetrec "$key " ${type}${terms}${cutoff} 1 20
	set line {}
	set j 1
	set i 0
	foreach p $termlist {
	    if {$i == 4} {
		set i 0
		set key1 ${key}$j
		if {[instexistsrec $key1] == 0} {instmakerec $key1}
		instsetrec $key1 $line 1 60
		set line {}
		incr j
	    }
	    if ![validreal p 15 6] {return 0}
	    append line $p
	    incr i
	}
	set key1 ${key}$j
	if {[instexistsrec $key1] == 0} {instmakerec $key1}
	instsetrec $key1 $line 1 60
    } else {
	set msg "Unsupported instinfo access: action=$action"
	tk_dialog .badinst "Error in instprofinfo" $msg error 0 Exit 
    }
    return 1
}
