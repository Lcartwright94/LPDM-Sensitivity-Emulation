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

### This function turns the time stamps into numerical values representing hours 
### since Jan 1st 00:00:00 2010. This baseline date can be changed by altering
### the variable base_line below. If the time stamp in question is not a whole
### number of hours, the returned value will simply be a decimal.

### One argument: time_stamps = vector of time stamps. The format is very important.
### They should be of POSIXct type: yyyy-mm-dd HH:MM:SS, and set to time zone UTC.

##################################################################################
##################################################################################

time_to_numeric <- function(time_stamps) {
  base_line <- as.POSIXct(paste0(2010,"/",01,"/",01," ",00,":",00), tz = "UTC")
  base_line <- as.numeric(base_line)
  
  time_stamps_numeric <- as.numeric(time_stamps)
  time_stamps_numeric_sub <- time_stamps_numeric - base_line
  time_stamps_numeric_sub_hour <- time_stamps_numeric_sub / 3600
  return(time_stamps_numeric_sub_hour)
}
