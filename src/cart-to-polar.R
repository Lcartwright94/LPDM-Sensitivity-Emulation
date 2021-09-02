##################################################################################
##################################################################################

### This function converts the data frame used in departure angle estimation from 
### Cartesian coordinates to polar coordinates on [0, 360).

### Argument: Points = data frame with cols "x" and "y".

##################################################################################
##################################################################################



cart_to_polar <- function(Points){
  Points_polar <- Points
  names(Points_polar) <- c("r", "theta")
  Points_polar$r <- sqrt((Points$x ^ 2) + (Points$y ^ 2))
  Points_polar$theta <- atan2(Points$y, Points$x)
  Points_polar$theta[Points_polar$theta < 0] <- Points_polar$theta[Points_polar$theta < 0] + 2 * pi
  Points_polar$theta <- Points_polar$theta * 180 / pi # convert to degrees
  return(Points_polar)
}
