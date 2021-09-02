##################################################################################
##################################################################################

### This function computes the negative log-likelihood, Gaussian mean zero. 
### Note this will add (epsilon * I) to the covariance, so it is good for the MLE.
### The only time we use this function is in the MLE

### Seven arguments: log_theta = the log of the length scales (updated through MLE)
###                  X = x-coordinates of observation towers in the data to build 
###                      the emulator with
###                  Y = y-coordinates of observation towers in the data to build 
###                      the emulator with
###                  Tp = the time points in data to build emulator
###                  Z = observed data to emulate from (e.g. Coeffs for one EOF)
###                  N = number of observations in data to build emulator with
###                  sig_0 = signal variance. Set to 1 since it can be solved
###                          for analytically in the MLE.

##################################################################################
##################################################################################





### Compute negative log-likelihood, Gaussian mean zero. 
### Note this will add (epsilon * I) to the covariance, so it is good for the MLE.
### I think the only time we use this function is in the MLE

neg_log_like <- function(log_theta, X, Y, Tp, Z, N, sig_0 = 1){ # theta = length scale
  
  theta <- exp(log_theta)
  
  # get covariance matrix
  
  sigma <- cov_small(X1 = data.frame(X, Y), 
                     X2 = data.frame(X, Y), 
                     Tp1 = Tp, 
                     Tp2 = Tp, 
                     ls = theta[1], 
                     lt = theta[2], 
                     sig_0) + 
    0.0001 * diag(rep(1, N))
  
  # get inverse covariance
  A <- chol(sigma)
  L_sig_0 <- t(A)
  L_sig_0_inv <- solve(L_sig_0)
  V_sig_0 <- L_sig_0_inv %*% Z
  
  sig_0 <- (t(V_sig_0) %*% V_sig_0) / N
  
  A <- as.numeric(sqrt(sig_0)) * A
  L <- t(A)
  L_inv <- solve(L)
  V <- L_inv %*% Z
  
  # compute log-likelihood density
  dens <- - (N / 2) * log(2 * pi) - sum(log(diag(L))) - 0.5 * t(V) %*% V
  
  # compute negative log-likelihood
  neg_dens <- (-1) * dens
  return(neg_dens)
}
