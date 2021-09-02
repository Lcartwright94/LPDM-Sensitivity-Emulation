#!/bin/bash

##################################################################################
##################################################################################

# Reproducible code for "Emulation of greenhouse-gas sensitivities using variational autoencoders", 
# by Laura Cartwright, Andrew Zammit-Mangion, and Nicholas M. Deutscher.  
# Copyright (c) 2021 Laura Cartwright  
# Author: Laura Cartwright (lcartwri@uow.edu.au)

# This program is free software; you can redistribute it and/or modify it under the terms 
# of the GNU General Public License as published by the Free Software Foundation; either 
# version 2 of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU General Public License for more details.


##################################################################################
##################################################################################
##################################################################################
##################################################################################

### This script will cycle through all of the sampled information in the specified 
### 'samps-...' file, and complete a FLEXPART simulation for each set of values. 
### To begin, ensure you have put the COMMAND and RELEASES files containing values 
### of 00.00 for the lat, lon, date, and time variables. The script will then update
### these values automatically for each subsequent run. 

### You will also need to ensure the correct values are given in OUTGRID. 

### To produce a different set of simulations, simply update the filename to one of 
### the other given files, or create your own. 

##################################################################################
##################################################################################

filename='samps-Europe-1.txt'

lon1strprev="LON1    =          00.00"
lon2strprev="LON2    =          00.00"	
lat1strprev="LAT1    =          00.00"
lat2strprev="LAT2    =          00.00"
idate1strprev="IDATE1  =       00.00" 
idate2strprev="IDATE2  =       00.00" 
itime1strprev="ITIME1  =         00.00" 
itime2strprev="ITIME2  =         00.00" 
ibdatestrprev="IBDATE=         00.00" 
iedatestrprev="IEDATE=         00.00"   
ibtimestrprev="IBTIME=           00.00" 
ietimestrprev="IETIME=           00.00" 

while read line; do
# reading each line
	x=(${line})
	lon1str="LON1    =          ${x[0]}"
	lon2str="LON2    =          ${x[0]}"	
	lat1str="LAT1    =          ${x[1]}"
	lat2str="LAT2    =          ${x[1]}"
	idate1str="IDATE1  =       ${x[4]}" # Start date of particle release (end of backward run)
	idate2str="IDATE2  =       ${x[4]}" # End date of particle release (end of backward run)
	itime1str="ITIME1  =         ${x[5]}" # Start time of particle release
	itime2str="ITIME2  =         ${x[5]}" # End time of particle release
	ibdatestr="IBDATE=         ${x[2]}" # Start date of the simulation
	iedatestr="IEDATE=         ${x[4]}" # End date of the simulation  
 	ibtimestr="IBTIME=           ${x[3]}" # Start time of the simulation
	ietimestr="IETIME=           ${x[5]}" # End time of the simulation

	sed -i -e "s/${lon1strprev}/${lon1str}/g" RELEASES
	sed -i -e "s/${lon2strprev}/${lon2str}/g" RELEASES
	sed -i -e "s/${lat1strprev}/${lat1str}/g" RELEASES
	sed -i -e "s/${lat2strprev}/${lat2str}/g" RELEASES
	sed -i -e "s/${idate1strprev}/${idate1str}/g" RELEASES
	sed -i -e "s/${idate2strprev}/${idate2str}/g" RELEASES
	sed -i -e "s/${itime1strprev}/${itime1str}/g" RELEASES
	sed -i -e "s/${itime2strprev}/${itime2str}/g" RELEASES
	sed -i -e "s/${ibdatestrprev}/${ibdatestr}/g" COMMAND
	sed -i -e "s/${iedatestrprev}/${iedatestr}/g" COMMAND
	sed -i -e "s/${ibtimestrprev}/${ibtimestr}/g" COMMAND
	sed -i -e "s/${ietimestrprev}/${ietimestr}/g" COMMAND

	cd .. 
	./src/FLEXPART
	cd options

	lon1strprev=${lon1str}
	lon2strprev=${lon2str}
	lat1strprev=${lat1str}
	lat2strprev=${lat2str}
	idate1strprev=${idate1str}
	idate2strprev=${idate2str}
	itime1strprev=${itime1str}
	itime2strprev=${itime2str}
	ibdatestrprev=${ibdatestr}
	iedatestrprev=${iedatestr}
	ibtimestrprev=${ibtimestr}
	ietimestrprev=${ietimestr}
	
done < $filename
