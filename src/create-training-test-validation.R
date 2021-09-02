##################################################################################
##################################################################################

### This script reads in the NAME plumes, both rotated and unrotated, and then divides them
### into a training set, and a validation set (and saves them).

### Note with the NAME plumes, by "training" we mean those plumes which we use to extract
### information, by putting them through the FLEXPART-trained CVAE, or using linear
### regression to find EOF coefficients. 
### We do not mean "training" as in to train the dimension reduction models.

### "Validation" refers to those plumes which we emulate & compare to their true forms. 

##################################################################################
##################################################################################

load("NAME-sims/NAME-UK-2014-rotated.rdata")
load("NAME-sims/NAME-UK-2014.rdata")

Plumes_rotated <- NAME_UK_2014_rotated$Plumes
Labels_rotated <- NAME_UK_2014_rotated$Labels
time_stamps_rotated <- NAME_UK_2014_rotated$time_stamps
dep_angle_rotated <- NAME_UK_2014_rotated$dep_angle
x_rotated <- NAME_UK_2014_rotated$x
y_rotated <- NAME_UK_2014_rotated$y

Plumes <- NAME_UK_2014$Plumes
Labels <- NAME_UK_2014$Labels
time_stamps <- NAME_UK_2014$time_stamps
dep_angle <- NAME_UK_2014$dep_angle
x <- NAME_UK_2014$x
y <- NAME_UK_2014$y


### Create index for training and validation sets. 

n_plumes <- ncol(Plumes)
remainder <- n_plumes %% 2
max_keep <- n_plumes - remainder

### Remove plumes to use in validation
to_train <- seq(0, max_keep, by = 2)
to_validate <- (1:n_plumes)[-to_train]

Plumes_validate_rotated <- Plumes_rotated[, to_validate]
Labels_validate_rotated <- Labels_rotated[to_validate]
time_stamps_validate_rotated <- time_stamps_rotated[to_validate]
dep_angle_validate_rotated <- dep_angle_rotated[to_validate]
x_validate_rotated <- x_rotated[to_validate]
y_validate_rotated <- y_rotated[to_validate]

Plumes_validate <- Plumes[, to_validate]
Labels_validate <- Labels[to_validate]
time_stamps_validate <- time_stamps[to_validate]
dep_angle_validate <- dep_angle[to_validate]
x_validate <- x[to_validate]
y_validate <- y[to_validate]

# Create validation set

validation_plumes_rotated <- list(Plumes = Plumes_validate_rotated,
                                    Labels = Labels_validate_rotated,
                                    time_stamps = time_stamps_validate_rotated,
                                    dep_angle = dep_angle_validate_rotated,
                                    x = x_validate_rotated,
                                    y = y_validate_rotated)

validation_plumes_unrotated <- list(Plumes = Plumes_validate,
                   Labels = Labels_validate,
                   time_stamps = time_stamps_validate,
                   dep_angle = dep_angle_validate,
                   x = x_validate,
                   y = y_validate)

# Build training set on rotated space also. 

Plumes_train <- Plumes[, to_train]
Labels_train <- Labels[to_train]
time_stamps_train <- time_stamps[to_train]
dep_angle_train <- dep_angle[to_train]
x_train <- x[to_train]
y_train <- y[to_train]

training_plumes <- list(Plumes = Plumes_train,
                    Labels = Labels_train,
                    time_stamps = time_stamps_train,
                    dep_angle = dep_angle_train,
                    x = x_train,
                    y = y_train)

### save the data sets

save(training_plumes, file = "training-plumes.rdata")
save(validation_plumes_rotated, file = "validation-plumes-rotated.rdata")
save(validation_plumes_unrotated, file = "validation-plumes-unrotated.rdata")

