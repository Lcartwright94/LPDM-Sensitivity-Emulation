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

### This function finds the optimised spatial length scale, temporal length scale, 
### and signal variance for one coeeficient or angle. This function is part of the
### optimise-GP-params.R script, and is where the actual optimisation takes place.

### Use this function to do MLE separately. If you want to do it as part of the 
### emulation, then just don't set a value for the hyperparams in the emulation
### function, and the MLE will happen during the emulation. 

### Six arguments: z = observed data to emulate from (e.g. coeffs for one EOF)
###                inits = inital values for optimisation
###                X = x-coordinates of observation towers in the data to use
###                    to build the emulator
###                Y = y-coordinates of observation towers in the data to use
###                    to build the emulator
###                Tp = time points in data to use to build emulator
###                N = number of observations in data to build emulator

##################################################################################
##################################################################################



get_MLE_params <- function(z, inits, X, Y, Tp, N) {
  
  ops <- optim(par = inits, 
               fn = neg_log_like, 
               X = X, 
               Y = Y, 
               Tp = Tp, 
               Z = z, 
               N = N,
               control = list(trace = 6))
  
  est_ls <- exp(ops$par[1])
  est_lt <- exp(ops$par[2])
  
  COV_sub <- cov_small(X1 = data.frame(X, Y), 
                       X2 = data.frame(X, Y), 
                       Tp1 = Tp, 
                       Tp2 = Tp, 
                       ls = est_ls, 
                       lt = est_lt, 
                       sig_0 = 1) + 
             0.0001 * diag(rep(1, N))
  A_sub <- chol(COV_sub)
  L_sub <- t(A_sub)
  L_inv <- solve(L_sub)
  V <- L_inv %*% z
  
  est_sig_0 <- (t(V) %*% V) / N
  
  return(list(ls = est_ls, lt = est_lt, sigma = est_sig_0))
  
}
