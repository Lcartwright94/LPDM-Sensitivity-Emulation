##################################################################################
##################################################################################

### This function will compute the covariance matrix for the GP emulator.

### Arguments: X1 = x and y coords for first argument to cov( , )
###            X2 = x and y coords for second argument to cov( , )
###            Tp1 = time vector for first argument to cov( , )
###            Tp2 = time vector for second argument to cov( , )
###            ls = spatial length scale
###            lt = temporal length scale
###            sig_0 = signal variance

##################################################################################
##################################################################################


cov_small <- function(X1, X2, Tp1, Tp2, ls, lt, sig_0) {
  
  space_dist_mat <- fields::rdist(as.matrix(X1), as.matrix(X2))
  time_dist_mat <- fields::rdist(as.matrix(Tp1), as.matrix(Tp2))
  
  space_COV <- sig_0 * exp(-0.5 * space_dist_mat ^ 2 / (ls  ^ 2))
  time_COV <- exp(-0.5 * time_dist_mat ^ 2 / (lt ^ 2))
  Cov <- space_COV * time_COV
  
  return(Cov) 
}
