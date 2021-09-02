##################################################################################
##################################################################################

### This function adjusts the location of the observation towers to match the 
### grid. For example, if the grid is built using the lower left corner of each 
### cell, while observation tower locations are slightly off this, the function 
### adjusts the coordinates of the observation tower to match.

### Two arguments: locs_grid is the full spatial gridded domain, 
###                tower_locations is the locations of all the observation 
###                  towers (one x-y set per column).

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
