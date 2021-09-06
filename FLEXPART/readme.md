# Reproducing the FLEXPART outputs

To reproduce the FLEXPART runs we ultimately used to train our emulator, please see the below instructions. 

The collection of files named "samps-###-##.txt" each contain a collection of randomly generated lat-lon coordinates to indicate the origin of a simulation, along with randomly generated start and finish times for that simulation. Rather than manually generating each singular plume, the script "flexpart-run.sh" will read off each set of sampled coordinates/times and perform the corresponding FLEXPART run, before moving onto the next simulation automatically. 

The file "domain-info.txt" contains all the information held constant across each of the four spatial regions over which simulations were run. Values stored are the lat-lon coordinates for the limits of the spatial domain over each region, along with the specified resolution of the grid, and the beginning and end of the 5-6 month time frame over which simulation times were drawn. In addition, the required conversion factors to transform the spatial grid from lat-lon to cartesian coordinates are given for each region. 

Note that there are three separate sets of values specified for the spatial grid over each region. This was because a larger region was used to run the flex_extract meta data extraction, and a smaller subset of each region was used to sample the coordinates of simulation origins, to ensure no simulation began too close to the edge of the spatial domain. 

Below are the steps necessary to reproduce the raw FLEXPAT outputs. 

* First, you will need to install FLEXPART. We used FLEXPART v10.4, which can be downloaded and installed [here](https://www.flexpart.eu/downloads). Corresponding documentation to assist with the installation can be found [here](https://gmd.copernicus.org/articles/12/4955/2019/). Note that you will also require [flex_extract](https://www.flexpart.eu/flex_extract/).

* You will now need to run flex_extract to obtain meta data over the domain and time frame of interest. Note that as we are performing backward simulations over 30 days, your flex_extract data needs to cover 30 days prior to your earliest FLEXPART simulation, at a minimum. For our work, we extracted ERA-Interim data. To extract the same data as we did, replace the "CONTROL_EI.public" and "run.sh" files in your flex_extract folders with those from this repository. Currently, the files are set to extract data over Europe, but you can easily change to any of the other three regions by adjusting "CONTROL_EI.public" according to "domain-info.txt". Note that if you change the prefix to something other than the one given in "domain-info.txt", you will need to manually create your own "AVAILABLE" file. To run flex_extract, navigate to the "Run" folder, and in a terminal/command line, run 

```diff 
./run.sh
```

* Once you have the necessary meta data, ensure that you have correctly set the paths in "pathnames". Then, replace "COMMAND" and "RELEASES" in your FLEXPART folders with those from this repository. You will need to do this each time you begin a looped run to reproduce these outputs. This is because the versions saved in this repository have a number of values set to 00.00, which allows the automatic loop of simulations to begin. 

* Choose the appropriate "AVAILABLE-######" file from this repository, and replace AVAILABLE in your FLEXPART folder with this one, at the same time renaming it to simply "AVAILABLE". 

* Now take the "OUTGRID" file from this repository and replace OUTGRID in your FLEXPART repository with this one. Currently OUTGRID is set up for Europe simulations. If you would like to produce simulations over one of the other three regions, you will need to update the lat-lon values in line with "domain-info.txt". 

* Download "FLEXPART-run.sh" from this repository, and place it in the "options" folder of your FLEXPART folders. Run the simulations by navigating to "options", and in a terminal/command line running 

```diff
./FLEXPART-run.sh
```

Some time later, your output folder should contain the output file from each of the runs. 

# Post-processing

Scripts to post-process the raw FLEXPART output, and turn it into the sensitivity plumes used to train the CVAE and fit the EOFs can be found in the "src" folder of this repository. 
