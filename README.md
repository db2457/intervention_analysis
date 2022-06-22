# Intervention Analysis for Autoregulatory Data
 
![Capture](https://user-images.githubusercontent.com/95881960/174530929-0a0e1c40-0750-4a45-9ad9-0210fd267cb6.PNG)

### Introduction

The objective of this code is to compute summary statistics for autoregulatory data before and after an intervention. 

### Method
This project was created with MATLAB R2022a and interfaces with .CSV files exported from ICM+. In brief, this code analyzes ICM+ data belonging to a given patient before and after a given time-stamped intervention. If sufficient ICM+ data is present both before and after the intervention, the code generates summary statistics of the ICM+ data. Otherwise, the code skips the intervention. The code iteratively repeats this analysis for all interventions across all patients.

Lists of patients and interventions to be considered for analysis are stored in separate excel spreadsheets. Summary statistics computed are means and medians for blood pressure, percent time spent below the lower limit of autoregulation (LLA), and area of the MAP curve (AUC) under the lower limit of autoregulation. AUC was computed using trapezoidal integration with `trapz` command. When `AUC < 0`, there is more area above the LLA. When `AUC > 0`, there is more area below the LLA.

Note: for patients who have both NIRS and ICP-derived autoregulatory data, this code chooses the type for which most data is present (i.e. not missing). 

### Usage
Clone this repo to your desktop. The intervention analysis takes place in three steps:

1. Load cohort file and intervention file into MATLAB with `readtable()`.
   * The cohort file is an excel spreadsheet of all patients to be considered for the analysis. Each row is a different patient. This file must contain a column `pt_id` that refers to any identification of type `double` or `char`. Historically, this was just a patient's MRN. 
   * The intervention file is an excel spreadsheet of all interventions (across all patients) to be considered for analysis. Each row is a different intervention. This file must contain a column      `pt_id` that matches the identification scheme in the cohort file. This file must also contain a column `time_taken` that refers to time-stamps for each intervention (in the format of Excel serial numbers) and a column `event_id` that refers to a unique identification number of of type `double` for each intervention.


2. Run intervention analysis with `intervention_analysis()`
   * `epoch_size` is a double that refers to the duration (min) of data used before and after an intervention to compute summary statistics. Historically, this has been 60 minutes.
   * `side` is a binary that refers to the side (left or right) used for NIRS-derived autoregulatory data. `side=1` for right, `side=0` for left.
   * `plot_interventions` is a binary that refers to whether or not you want plots of each intervention generated. If `plot_interventions=1`, the code will create two new directories `plots` and `data` that contain .jpg graphs of each intervention and corresponding time-series data, respectively.


3. Save output to an excel spreadsheet using `writetable()`

Note: All ICM+ CSV files must follow naming scheme `pt_id.csv`, where "pt_id" is the patients corresponding identification in the cohort file. The code will return an error if this is not the case. 

### Example
Open `example.m`. This script uses the example spreadsheets `cohort_file.xlsx` and `intervention_file.xlsx` to run intervention analysis on a dummy patient with `pt_id=MR12345`. This patient has 282 interventions listed in `intervention.xlsx`. After analysis, summary statistics for 184/282 interventions are generated in a spreadsheet `Results.xlsx`. 98 interventions were excluded from analysis because insufficient ICM+ data were present. 

### Customization
Change specifications in `intervention_analysis.m`
* `VIABLE_THRESHOLD` refers to the minimum percent (decimal) of data that must be present in the epoch before and after a given intervention for it to be considered for analysis. For example, if `epoch_size=60` and `viable_threshold=0.50`, then all interventions must have at least 30 minutes of data present in the hour before and after to be considered for analysis. Historically, `epoch_size=60` and `viable_threshold=0.80`.

* To change which summary statistics are generated, you must add computations in the "CALCULATE COVARIATES" section of the code and change variables `covariates_kim` and `covar_kim_data` accordingly. This might be confusing, so feel free to submit an issue if you'd like me to add it. I am happy to do that.

### Real data for Yale SAH patients

I used this code for SAH patients receiving nimodipine during their hospital admission. Yale folks can [download my cohort and intervention spreadsheets and ICM+ CSV files on Yale Box.](https://yale.box.com/s/q4rgnzs4injtxjsp5girgekorle5fg19)

### References
None.
