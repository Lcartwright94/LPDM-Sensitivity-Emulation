# Scripts for pre/post-processing and emulation

Below is a list detailing the function of each script in this folder. Further individual instructions are contained within each script. Also in this folder are the collection of weights and basis functions corresponding to the trained encoder for the means (encoder-mean.h5), the trained encoder for the log variances (encoder-log-var.h5), and the trained decoder/generator (generator.h5).

These scripts describe the emulation process beginning with raw FLEXPART outputs. It details converting the outputs into the cumulated sensitivity plumes, rotating and translating both the FLEXPART and NAME plumes, training the CVAE and fitting the EOFs, the emulation process along with Monte Carlo sampling and rotations/translations back onto the original space, the calculation of final metrics, and the production of comparison plots. 

## Functions

* ***adjust-tower-locations:*** This function adjusts the location of the measurement sites to match the grid. For example, if the grid is built using the lower left corner of each cell, while observation tower locations are slightly off this, the function adjusts the coordinates of the measurement site to match.
* ***cart-to-polar:*** This function converts the data frame used in departure angle estimation from Cartesian coordinates to polar coordinates on the interval from 0 to 360.
* ***covariances:*** This function will compute the covariance matrix for the GP emulator.
* ***emulator-gp:*** This function uses a Gaussian Process emulator to emulate values for the coefficients, sin(theta), and cos(theta). 
* ***estimate-dep-angle:*** This function estimates the departure angle of a plume. It works using the normalised values of the sensitivity.
* ***filter-plumes:*** This function removes any plumes which go too much off the grid.
* ***get-GP-mean-var:*** This function obtains the posterior means and variances from the GP emulator.
* ***get-MLE-params:*** This function finds the optimised spatial length scale, temporal length scale, and signal variance for one coefficient or angle. This function is part of the optimise-GP-params.R script, and is where the actual optimisation takes place.
* ***metrics:*** This function computes the sum of the mean squared errors for all plumes given, or the individual mean absolute errors between the EOF and VAE approaches. The get_mses function also returns the individual MSEs per plume, and the average MSE for the largest 10% of MSEs.
* ***neg-log-like:*** This function computes the negative log-likelihood, Gaussian mean zero. Note this will add (epsilon * I) to the covariance (for MLE). 
* ***optimise-GP-params-HPC:*** This function finds the optimised spatial length scales, temporal length scales, and signal variances for each coefficient, as well as sin theta and cos theta.
* ***plot-plume:*** These functions will produce various plots of the plumes, depending on arguments.
* ***time-to-numeric:*** This function turns the time stamps into numerical values representing hours since Jan 1st 00:00:00 2010. 
* ***unrotate-plume:*** This function rotates the emulated plume back to the original space.

## Processing of FLEXPART and NAME data

* ***get-FLEXPART-plumes-for-training:*** This script reads in the raw FLEXPART outputs. It builds the plume by summing over the output and converting to ns/g.
* ***get-NAME-plumes:*** This script reads in the NAME output from Anita. It then puts the plumes all together with one column per plume.
* ***create-rotated-plumes-for-training:*** This script will zero the location of the FLEXPART plumes (such that they depart from the origin). Then, it will rotate the plumes so that their departure mid-line is the x-axis.
* ***create-rotated-plumes-for-application:*** This script will zero the location of the NAME plumes (such that they depart from the origin). Then, it will rotate the plumes so that their departure mid-line is the x-axis.

## Training the CVAE and fitting the EOFs

* ***create-trianing-test-validation:*** This script reads in the NAME plumes, both rotated and unrotated, and then divides them into a training set, and a validation set (and saves them).
* ***create-CVAE-basis:*** This script creates the VAE basis by running the data to use in the emulation through a pre-trained and loaded-in Encoder.
* ***create-EOF-basis:*** This script creates the EOF basis for the NAME UK plumes. Values for coefficients are computed via ordinary least squares regression.
* ***train-CVAE:*** This script fits & trains the CVAE which will be used to send plumes onto a 20-dim latent space.
* ***train-EOFs:*** This script creates the EOF basis by doing the full singular-value-decomposition. Only the desired number of EOFs are saved. If the number changes, or the data to be input changes, you'll need to re-run this script.

## Emulation & post-processing

* ***Main:*** This script is the main wrapper for the emulation. Within this script, the emulation occurs, MLE if needed, the unrotation, and construction of some basic comparison plots. 
