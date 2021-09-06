# Scripts for pre/post-processing and emulation

Below is a list detailing the function of each script in this folder. These scripts describe the emulation process beginning with raw FLEXPART outputs. It details converting the outputs into the cumulated sensitivity plumes, rotating and translating both the FLEXPART and NAME plumes, training the CVAE and fitting the EOFs, the emulation process along with Monte Carlo sampling and rotations/translations back onto the original space, the calculation of final metrics, and the production of comparison plots. 

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
