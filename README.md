This repository contains MATLAB files to preprocess, analyze, and visualize comparisons between SWOT water surface elevation (WSE) and significant wave height (SWH) and in-situ measurements collected at the Army Corps of Engineers Field Research Facility in Duck, NC

Here is a general overview of how to replicate this analysis:
1. Download the SWOT data locally. L2 products can be found here https://podaac.jpl.nasa.gov/SWOT?sections=data and the L3 product can be found here https://www.aviso.altimetry.fr/en/data.html
   *Note: Downloading the files locally is not the recommended way to handle SWOT data, streaming the data from the cloud is the preferred method. Information on this can be found here: https://podaac.github.io/tutorials/notebooks/datasets/DirectCloud_Access_SWOT_Oceanography.html
2. Retrieve in-situ data from chldata.erdc.dren.mil
* For the data that can be retrieved programmatically, the codes are provided in folder "In-situ Data Retrieval and processing"
* The in-situ data preprocessing happens inside these codes
3. Preprocess SWOT data. Codes are available in folder "SWOT Data Preprocessing"
4. Analyze and visualize SWOT vs in-situ SWH and WSE separately. Code is available in folder "Main Analysis"
5. Conduct feature important analysis on which factors are most correlated with SWOT vs in-situ WSE and SWH comparison error. Codes for this are in folder "Feature Importance"
6. Helper functions to run these codes are in folder "Helper Functions"
