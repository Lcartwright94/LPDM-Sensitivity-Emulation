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

### This function adjusts the location of the measurement sites to match the 
### grid. For example, if the grid is built using the lower left corner of each 
### cell, while observation tower locations are slightly off this, the function 
### adjusts the coordinates of the measurement site to match.

### Two arguments: locs_grid is the full spatial gridded domain, 
###                tower_locations is the locations of all the measurement sites
###                (one x-y set per column).

##################################################################################
##################################################################################

adjust_locations <- function(locs_grid, tower_locs) {
  
  for (m in 1:ncol(tower_locs)) {
    id <- which(abs(locs_grid$x - tower_locs[1, m]) == 
                  min(abs(locs_grid$x - tower_locs[1, m])) &
                  abs(locs_grid$y - tower_locs[2, m]) == 
                  min(abs(locs_grid$y - tower_locs[2, m])))
    if (length(id) > 1) {
      tower_locs[1, m] <- locs_grid$x[id[1]]
      tower_locs[2, m] <- locs_grid$y[id[1]]
    } else {
      tower_locs[1, m] <- locs_grid$x[id]
      tower_locs[2, m] <- locs_grid$y[id]
    }
  }
  
  return(tower_locs)
}
