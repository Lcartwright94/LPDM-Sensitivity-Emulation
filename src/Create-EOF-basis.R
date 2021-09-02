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

### This script creates the EOF basis for the NAME UK plumes.
### Values for coefficients are computed via ordinary least squares
### regression.

### Output will save the output as a list, with U, D, and V, as well as the vector
### of spatial means which were subtracted prior to the SVD.

### Each row of U represents the set of coefficients for 1 plume
### D is a diagonal matrix of eigenvalues
### Each column in V is a basis function

##################################################################################
##################################################################################

load("training-plumes.rdata")
load("EOF-trained.rdata")

V <- EOF_trained$V
D <- EOF_trained$D

spatial_means <- EOF_trained$spatial_means
training_plumes_centred <- training_plumes$Plumes

for (k in 1:ncol(training_plumes_centred)) {
  training_plumes_centred[, k] <- training_plumes_centred[, k] - spatial_means
}

### Let:
## N = number of grid cells
## q = number of plumes
## p = number of EOFs

# training plumes is N * q
# D is p * p
# V is N * p
# U is q * p
# X = D * t(V) is p * N

# Linear model: training_plumes = X' U_coeffs_t
# where U_coeffs_t must be p * q

# For EOF basis we want to find U of dimension q * p

X <- D %*% t(V)
X_t <- t(X)

U_coeffs_t <- solve(t(X_t) %*% X_t) %*% t(X_t) %*% training_plumes_centred
U_coeffs <- t(U_coeffs_t)

EOF_basis <- list(U = U_coeffs,
                  V = V,
                  D = D,
                  spatial_means = spatial_means)

save(EOF_basis, file = "EOF-basis.rdata")

