#!/bin/bash


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
