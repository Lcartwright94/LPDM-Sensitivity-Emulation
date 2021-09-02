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

### This script will zero the location of plumes (such that they depart from the 
### origin. Then, it will rotate the plumes so that their departure mid-line is 
### the x-axis.

##################################################################################
##################################################################################

######## Variables you'll need to change ###########

## Okay, actually this is littered with things to change:
# - the three directly below
# - a bunch of arguments in the idw function
# - the arguments in the adjust_locations function
# - n_plumes
# - name of data file at the end.

file_name <- "FLEXPART-sims/surface-EU/FP-sims-EU.rdata"
file_out <- "FLEXPART-sims/surface-EU/FP-sims-EU-rotated.rdata"
grid_name <- "FLEXPART-sims/surface-EU/EU.rdata"

############################################

library(gstat)
library(parallel)
library(dplyr)

# Set your working directory to be the folder where the FLEXPART simulations are

source("../src/adjust-tower-locations.R") # Might need to adjust these paths if you change the folder structure
source("../src/rotate-plumes-to-zero.R")

load("grid-new.rdata")

############################################

load(file_name)
load(grid_name)
tower_locations <- rbind(FP_sims_EU$x_orig, FP_sims_EU$y_orig)
tower_locations_adj <- rbind(FP_sims_EU$x, FP_sims_EU$y)

# Zero and rotate plumes

n_plumes <- ncol(FP_sims_EU$Plumes)

rotate_parallel <- mclapply(1:n_plumes, function(i) {
  
  location_id <- as.numeric(FP_sims_EU$Labels[i])
  
  rot <- rotate_to_zero(plume = FP_sims_EU$Plumes[, i],
                        adj_loc = tower_locations_adj[, location_id],
                        dep_ang = FP_sims_EU$dep_angle[i],
                        orig_grid = grid_locations,
                        new_grid = grid_new)
  
  print(i)
  return(rot)
}, mc.cores = 60)

# Put rotated plumes together in a matrix

rotated_plumes <- NULL
for (i in 1:n_plumes) {
  rotated_plumes <- cbind(rotated_plumes, rotate_parallel[[i]])
  print(i)
}

FP_sims_EU_rotated <- list(Plumes = rotated_plumes,
                             Labels = FP_sims_EU$Labels,
                             time_stamps = FP_sims_EU$time_stamps,
                             dep_angle = FP_sims_EU$dep_angle,
                             x = FP_sims_EU$x,
                             y = FP_sims_EU$y,
                             x_orig = FP_sims_EU$x_orig,
                             y_orig = FP_sims_EU$y_orig)

save(FP_sims_EU_rotated, file = file_out)









