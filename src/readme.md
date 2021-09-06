# Scripts for pre/post-processing and emulation

Below is a list detailing the function of each script in this folder. These scripts describe the emulation process beginning with raw FLEXPART outputs. It details converting the outputs into the cumulated sensitivity plumes, rotating and translating both the FLEXPART and NAME plumes, training the CVAE and fitting the EOFs, the emulation process along with Monte Carlo sampling and rotations/translations back onto the original space, the calculation of final metrics, and the production of comparison plots. 

## Functions

* ***adjust-tower-locations:*** hh
* ***cart-to-polar:*** hh
* covariances:
* emulator-gp:
* estimate-dep-angle:
* filter-plumes: 
* get-GP-mean-var:
* get-MLE-params: This function finds the optimised spatial length scale, temporal length scale, and signal variance for one coefficient or angle. This function is part of the optimise-GP-params.R script, and is where the actual optimisation takes place.
* metrics:
* neg-log-like: This function computes the negative log-likelihood, Gaussian mean zero. Note this will add (epsilon * I) to the covariance (for MLE). 
* optimise-GP-params-HPC: This function finds the optimised spatial length scales, temporal length scales, and signal variances for each coefficient, as well as sin theta and cos theta.
* plot-plume: These functions will produce various plots of the plumes, depending on arguments.
* time-to-numeric: This function turns the time stamps into numerical values representing hours since Jan 1st 00:00:00 2010. 
* unrotate-plume: This function rotates the emulated plume back to the original space.
