##################################################################################
##################################################################################

### This function will zero and rotate the plumes so that their departure mid-line 
### is the x-axis.

### Arguments: plume = the plume to rotate
###            adj_loc = the location of the measurement tower of the plume,
###                      adjusted to the closest grid cell
###            dep_ang = estimated departure angle of the plume
###            orig_grid = x, y coordinates on the original spatial domain
###            new_grid = x, y coordinates on the new spatial domain

##################################################################################
##################################################################################

rotate_to_zero <- function(plume, adj_loc, dep_ang, orig_grid, new_grid) {
  
  # Put spatial locs together with plume
  grid <- cbind(orig_grid, plume)
  names(grid) <- c("x", "y", "plume")
  
  # Zero departure point of plume
  grid$x <- grid$x - adj_loc[1]
  grid$y <- grid$y - adj_loc[2]
  
  # Create rotated coords
  grid$rot_x <- grid$x * cos(dep_ang) + grid$y * sin(dep_ang)
  grid$rot_y <- -grid$x * sin(dep_ang) + grid$y * cos(dep_ang)
  
  # Re-order grid to group by y-vals. Needed for the re-gridding
  grid <- arrange(grid, y)
  
  # re-grid
  rotated <- gstat::idw(formula = plume ~ 1, # dependent var
                        locations = ~ rot_x + rot_y, # inputs
                        data = grid, 
                        newdata = new_grid, # new 64 x 64 grid
                        idp = 6) 
  
  return(rotated$var1.pred)
}





