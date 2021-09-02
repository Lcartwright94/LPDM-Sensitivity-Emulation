##################################################################################
##################################################################################

### This script creates the EOF basis by doing the full singular-value-decomposition.
### Only the desired number of EOFs are saved. If the number changes, or the data 
### to be input changes, you'll need to re-run this script.

### It will save the output as a list, with U, D, and V, as well as the vector
### of spatial means which were subtracted prior to the SVD.

### Each row of U represents the set of coefficients for 1 plume
### D is a diagonal matrix of eigenvalues
### Each column in V is a basis function

### This SVD is done on the same 20000 FLEXPART plumes used to train the VAE
### Coefficients for the NAME UK plumes are obtained in the script "create-EOF-basis.R"
### via linear regression.

##################################################################################
##################################################################################


num_EOFs <- 20

load("FLEXPART-sims/surface-EU/FP-sims-EU-rotated.rdata")
load("FLEXPART-sims/surface-Aus/FP-sims-Aus-rotated.rdata")
load("FLEXPART-sims/surface-Canada/FP-sims-Canada-rotated.rdata")
load("FLEXPART-sims/surface-UK/FP-sims-UK-rotated.rdata")
Plumes <- cbind(FP_sims_EU_rotated$Plumes,
                FP_sims_Aus_rotated$Plumes,
                FP_sims_Canada_rotated$Plumes,
                FP_sims_UK_rotated$Plumes)

# Normalise 

Plumes_normalised <- Plumes / max(Plumes)
ids <- NULL

for (i in 1:ncol(Plumes)) {
  if (sum(Plumes_normalised[, i] > 0.005) < 10) {
    ids <- c(ids, i)
  }
}

Plumes <- Plumes[, -ids]

### Get out only training set to match VAE training

RNGkind(sample.kind = "Rounding")
set.seed(1365)

n_plumes <- ncol(Plumes)
n_dim_test <- 0.3 * n_plumes

### Remove plumes in to the CVAE test set
to_test <- sort(sample(1:n_plumes, round(n_dim_test, 0)))
x_test <- Plumes[, to_test]

### Create training set
ids <- sort(c(to_test))
to_train <- (1:n_plumes)[-ids]
x_train <- Plumes[, to_train]

# Subtract spatial means
spatial_means <- rowMeans(x_train)
Plumes_centred <- x_train

for (k in 1:ncol(Plumes_centred)) {
  Plumes_centred[, k] <- Plumes_centred[, k] - spatial_means
}

# Transpose data
Plumes_centred_t <- t(Plumes_centred)
E <- svd(Plumes_centred_t)

U <- E$u[, 1:num_EOFs]
V <- E$v[, 1:num_EOFs]
D <- diag(E$d[1:num_EOFs])

EOF_trained <- list(U = U,
                    V = V,
                    D = D,
                    spatial_means = spatial_means)


### check metrics


source("../src/metrics.R")

training_EOF <- EOF_trained$U %*% EOF_trained$D %*% t(EOF_trained$V)
training_EOF <- t(training_EOF)
for (i in 1:ncol(training_EOF)) {
  training_EOF[, i] <- training_EOF[, i] + EOF_trained$spatial_means
}

metrics_EOF_training <- get_metrics(x_train, training_EOF)
metrics_EOF_training$sum_mses


save(EOF_trained, file = "EOF-trained.rdata")
save(EOF_vals_training, file = "EOF-vals-training.rdata")
