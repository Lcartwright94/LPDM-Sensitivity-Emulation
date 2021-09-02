##################################################################################
##################################################################################

### This script will zero the location of plumes (such that they depart from the 
### origin. Then, it will rotate the plumes so that their departure mid-line is 
### the x-axis.

##################################################################################
##################################################################################

file_name <- "NAME-sims/NAME-UK-2014.rdata"
file_out <- "NAME-sims/NAME-UK-2014-rotated.rdata"
grid_name <- "NAME-sims/NAME-UK-2014-grid.rdata"

############################################

library(gstat)
library(parallel)
library(dplyr)

source("../src/adjust-tower-locations.R") # Might need to adjust these paths if you change the folder structure
source("../src/rotate-plumes-to-zero.R")

load("grid-new.rdata")

############################################

load(file_name)
load(grid_name)
tower_locations <- rbind(c(-9.9, -2.54, 1.14, -2.99),
                         c(53.33, 52.00, 52.52, 56.56))

# Adjust observation tower location coords so zero-ing works properly

tower_locations_adj <- adjust_locations(locs_grid = NAME_UK_2014_grid, 
                                        tower_locs = tower_locations)

# Zero and rotate plumes

n_plumes <- ncol(NAME_UK_2014$Plumes)

rotate_parallel <- mclapply(1:n_plumes, function(i) {
  
  location_id <- as.numeric(NAME_UK_2014$Labels[i])
  
  rot <- rotate_to_zero(plume = NAME_UK_2014$Plumes[, i],
                        adj_loc = tower_locations_adj[, location_id],
                        dep_ang = NAME_UK_2014$dep_angle[i],
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

NAME_UK_2014_rotated <- list(Plumes = rotated_plumes,
                             Labels = NAME_UK_2014$Labels,
                             time_stamps = NAME_UK_2014$time_stamps,
                             dep_angle = NAME_UK_2014$dep_angle,
                             x = NAME_UK_2014$x,
                             y = NAME_UK_2014$y,
                             x_orig = NAME_UK_2014$x_orig,
                             y_orig = NAME_UK_2014$y_orig)

save(NAME_UK_2014_rotated, file = file_out)









