
COHORT_FILENAME = 'cohort_file.xlsx';
INTERVENTION_FILENAME = 'intervention_file.xlsx';
DATA_DIR = cd; % directory where ICM+ csv files are stored

EPOCH_SIZE = 60; % Compute summary statistics for 60 min before and after intervention

%% Step 1: Load cohort and intervention files

cohort_file = readtable(COHORT_FILENAME);
intervention_file = readtable(INTERVENTION_FILENAME); intervention_file.time_taken = datetime(intervention_file.time_taken,'ConvertFrom','excel');

%% Step 2: Run intervention analysis, choosing left side for analysis.

SIDE = 0; 
PLOT_INTERVENTIONS = 0;

summary_data = intervention_analysis(cohort_file,intervention_file,DATA_DIR,EPOCH_SIZE,SIDE,PLOT_INTERVENTIONS);

%% Step 3: Save summary data 

writetable(summary_data,'Results.xlsx')