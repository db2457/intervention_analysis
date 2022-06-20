function [summary_stats] = intervention_analysis(cohort_file,intervention_file,data_dir,epoch_size,side,plot_interventions)
%INTERVENTION_ANALYSIS 
% DESCRIPTION:
%   Produces before and after summary statistics for time-stamped interventions 
%   that occur during ICM+ neuromonitoring.

% INPUT (REQUIRED):
%   cohort_file - (table) table containing cohort data
%
%   intervention_file - (table) table containing time-stamped interventions 
%   for all patients
%
%   data_dir - (char) directory where ICM+ CSV files are stored. Each CSV
%   filename must be matched to "id" column in intervention_file and
%   cohort_file
%
%   epoch_size - (integer) length of before&after window (minutes)
%
%   side - (binary) side=0 if analyzing left-sided NIRS data. side=1 if 
%   analyzing right-sided NIRS data.
%
%   plot - (binary) plot=1 if you want the code to save plots of each intervention. 
%   
% OUTPUT:
%   summary_stats - (table) table containing before and after summary
%   statistics for each intervention
%

%% CUSTOMIZATION SETTINGS

VIABLE_THRESHOLD = 0.8; % proportion of data that must be present 

covariates_kim = {'event_id','pt_id','date','percent_below_before','percent_below_after','mean_before','mean_after','median_before','median_after','min_before',...
                  'min_after','max_before','max_after','auc_below_before','auc_below_after'};       

%% CODE

original_dir = cd;
mkdir('plots')
mkdir('data')

fs = 0.1
          
epoch_file_kim  = cell2table(cell(0,length(covariates_kim)));  epoch_file_kim.Properties.VariableNames = covariates_kim; % initialize empty epoch file



for patient = 1:height(cohort_file)
    
    
    id = num2str(cohort_file.pt_id{patient}); % get this patient's id
    
     
    if isfinite(cohort_file.exclude(patient)) && cohort_file.exclude(patient) %   % if patient is excluded, don't bother importing... 
        reason = cohort_file.status(patient);
        reason = reason{1};
        disp([id, ' excluded: ',reason,'. Skipping.'])
        continue % skip this patient
        
    else % import
        
        cd(data_dir)
       
        try 
            
            data = readtable([id,'.csv']);

        catch err
            

            if (strcmp(err.identifier,'MATLAB:textio:textio:FileNotFound'))

                warning([id, ': CSV file does not exist']) 
         
            else
                
                warning([id,': unable to import CSV file. ',err.message])

            end

            continue % skip
            
        end
        
        if isempty(data)
            warning([id,': CSV file is empty. Skipping.'])
        end
        
        
    end 
    
      
    time = data.DateTime;
    
    

    % Do ICP-derived LA exist? If so, save them.
    if any(contains(data.Properties.VariableNames,'LLA_PRx')) && any(contains(data.Properties.VariableNames,'ULA_PRx'))

        lla_icp = data.LLA_PRx;
        ula_icp = data.ULA_PRx;


    else

        lla_icp = [];
        ula_icp = [];


    end

    % Do NIRS-derived LA exist? If so, save them.
    if any(contains(data.Properties.VariableNames,'LLA_L')) && any(contains(data.Properties.VariableNames,'LLA_R')) % do NIRS-derived limits exist (just checks left)



        if side

            lla_nirs = data.LLA_R; 
            ula_nirs = data.ULA_R;


        else

            lla_nirs = data.LLA_L; 
            ula_nirs = data.ULA_L;

        end


    else

        lla_nirs = [];
        ula_nirs = [];
        cox = [];


    end

    % Choose whether we use NIRS or ICP-derived autoregulatory data

    if isempty(lla_icp) || isempty(ula_icp) % if no ICP data...

        if isempty(lla_nirs) || isempty(ula_nirs) % AND no NIRS data,,,

            warning([id, ': neither ICP nor NIRS-derived autoregulation data exist. Skipped.'])
            continue
        end

       % use NIRS data
        upper_mean = table(ula_nirs); upper_mean.Properties.VariableNames = {'upper'};
        lower_mean = table(lla_nirs); lower_mean.Properties.VariableNames = {'lower'};


        if any(contains(data.Properties.VariableNames,'MAPopt_flex_R_mmHg_')) % annoying naming convention

            if side

                mapopt_mean = table(data.MAPopt_flex_R_mmHg_); mapopt_mean.Properties.VariableNames = {'mapopt'};


            else

                mapopt_mean = table(data.MAPopt_flex_L); mapopt_mean.Properties.VariableNames = {'mapopt'};
            end



        else

             if side

                mapopt_mean = table(data.MAPopt_flex_R); mapopt_mean.Properties.VariableNames = {'mapopt'};


            else

                mapopt_mean = table(data.MAPopt_flex_L); mapopt_mean.Properties.VariableNames = {'mapopt'};
             end

        end

        data = [data lower_mean upper_mean mapopt_mean];



    elseif isempty(lla_nirs) || isempty(ula_nirs) % if we have ICP data but no NIRS..

        % use ICP data
         upper_limit = table(data.ULA_PRx); upper_limit.Properties.VariableNames = {'upper'};
         lower_limit = table(data.LLA_PRx); lower_limit.Properties.VariableNames = {'lower'};
         mapopt_icp = table(data.MAPopt_PRx); mapopt_icp.Properties.VariableNames = {'mapopt'};
         data = [data upper_limit lower_limit mapopt_icp];

    else % we have ICP and NIRS derived data

        % compare which is better

        nirs_quality_index = sum(isnan(lla_nirs)) + sum(isnan(ula_nirs)); % higher the number, the more missing data...
        icp_quality_index = sum(isnan(lla_icp)) + sum(isnan(ula_icp));


        if nirs_quality_index > icp_quality_index % if NIRS signal is worse...

              % use ICP data
             upper_limit = table(data.ULA_PRx); upper_limit.Properties.VariableNames = {'upper'};
             lower_limit = table(data.LLA_PRx); lower_limit.Properties.VariableNames = {'lower'};
             mapopt_icp = table(data.MAPopt_PRx); mapopt_icp.Properties.VariableNames = {'mapopt'};
             data = [data upper_limit lower_limit mapopt_icp];



        else

            % use NIRS data
            upper_mean = table(ula_nirs); upper_mean.Properties.VariableNames = {'upper'};
            lower_mean = table(lla_nirs); lower_mean.Properties.VariableNames = {'lower'};


            if any(contains(data.Properties.VariableNames,'MAPopt_flex_R_mmHg_')) % annoying naming convention

                if side

                    mapopt_mean = table(data.MAPopt_flex_R_mmHg_); mapopt_mean.Properties.VariableNames = {'mapopt'};


                else

                    mapopt_mean = table(data.MAPopt_flex_L); mapopt_mean.Properties.VariableNames = {'mapopt'};
                end



            else

                if side

                    mapopt_mean = table(data.MAPopt_flex_R); mapopt_mean.Properties.VariableNames = {'mapopt'};


                else

                    mapopt_mean = table(data.MAPopt_flex_L); mapopt_mean.Properties.VariableNames = {'mapopt'};
                end

            end

            data = [data lower_mean upper_mean mapopt_mean];
            nirs_data_used_indicator = 1;


        end


    end
        
        

    % define ABP variable b.c. Hemosphere files have MAP not ABP :/
    if any(contains(data.Properties.VariableNames,'ABP'))
        ABP = 'ABP';
    elseif any(contains(data.Properties.VariableNames,'MAP'))
        ABP = 'MAP';
    end

    % match patient with intervention data
    intervention_indices = strcmp(intervention_file.pt_id,id); % logical indices
    admins = intervention_file(intervention_indices,:); % slices intervention data for just this patient

      
    % Iterate through all interventions for this one patient
    for intervention = 1:height(admins) 



       % collect information for this one intervention
        row = admins(intervention,:);
%         med = row.intervention;
        time_taken = row.time_taken;
%         dose = row.dose;
        event_id = row.event_id;

        % Pull time indexes from ICM data
        start_index = find(abs(time-time_taken) <= seconds(5)); %  time index of dose

        if isempty(start_index) % if dose time is out of bounds, skip to next admin
            continue
        else
            start_index = start_index(1);
        end

         % window data into before and after epochs
        cushion = round(fs * (epoch_size * 60)); % index size of cushion



        if start_index + cushion > height(data) % check for out of right bounds

            continue; % skip this admin because this epoch is inappropriate

        elseif start_index - cushion <= 1 % check for out of left bounds

            continue; % skip this admin because this epoch is inappropriate


        else

             win_before = data(start_index - cushion : start_index,:);
             win_after = data(start_index : start_index + cushion,:);

        end


        win_before_half = win_before(round((height(win_before))/2):end,:);
        viable_before = (sum(~any(isnan([win_before_half.lower,win_before_half.upper,win_before_half.(ABP)]),2)) / fs) / (height(win_before_half)/fs);



        viable_after = (sum(~any(isnan([win_after.lower,win_after.upper,win_after.(ABP)]),2)) / fs) / (height(win_after)/fs); 


        if viable_before < VIABLE_THRESHOLD || viable_after < VIABLE_THRESHOLD % if >90% of data is availabe on both sides

    %                 fprintf(['\n',MR, ', Event ID: ', num2str(event_id),', Side: ',num2str(side),', Epoch: ', num2str(epoch),' is not viable for analysis (',num2str(viable_before*100),',',num2str(viable_after*100),')']);

            continue % skip this med admin
        end

      % -------- START: CALCULATE COVARIATES -----------------------------




        cd(original_dir) % to access needed .m files
        

        [PERCENT_BELOW_BEFORE, PERCENT_ABOVE_BEFORE] = outside_limits(win_before,epoch_size*60);
        [PERCENT_BELOW_AFTER, PERCENT_ABOVE_AFTER,TIME_BELOW] = outside_limits(win_after,epoch_size*60);


        MEAN_ABP_BEFORE = mean(win_before.(ABP),'omitnan');
        MEDIAN_ABP_BEFORE = median(win_before.(ABP),'omitnan');
        MAX_ABP_BEFORE = max(win_before.(ABP));
        MIN_ABP_BEFORE = min(win_before.(ABP));

        MEAN_ABP_AFTER = mean(win_after.(ABP),'omitnan');
        MEDIAN_ABP_AFTER = median(win_after.(ABP),'omitnan');
        MAX_ABP_AFTER = max(win_after.(ABP));
        MIN_ABP_AFTER = min(win_after.(ABP));


        coord_valid_before = find(~any(isnan([win_before.lower,win_before.(ABP)]),2)); % 1 where valid signal exists
        coord_valid_after = find(~any(isnan([win_after.lower,win_after.(ABP)]),2));
        AUC_before = trapz(coord_valid_before ./ fs, win_before.lower(coord_valid_before)) - trapz(coord_valid_before ./ fs, win_before.(ABP)(coord_valid_before)); %X = uniform spacing between samples (s) = sampling period = 1/fs
        AUC_after = trapz(coord_valid_after ./ fs, win_after.lower(coord_valid_after)) - trapz(coord_valid_after ./ fs, win_after.(ABP)(coord_valid_after)); %X = uniform spacing between samples (s) = sampling period = 1/fs

        % -------- END: CALCULATE COVARIATES -----------------------------

    

       % package requested covariatses
        covar_kim_data = {event_id,id,time_taken,PERCENT_BELOW_BEFORE*100,PERCENT_BELOW_AFTER*100, MEAN_ABP_BEFORE, MEAN_ABP_AFTER, MEDIAN_ABP_BEFORE, MEDIAN_ABP_AFTER,...
                          MIN_ABP_BEFORE,MIN_ABP_AFTER,MAX_ABP_BEFORE,MAX_ABP_AFTER,AUC_before,AUC_after};

        epoch_file_kim = [epoch_file_kim ; covar_kim_data];
        
        if plot_interventions
            
            
            cd(original_dir)
            cd('plots')
            
        
             % create and save requested plots
            concat_data = [win_before ; win_after]; % vert concat before and after data windows
            time_mod = concat_data.DateTime - time_taken;    time_mod.Format = 'm';
            x_ticks = time_mod(1):seconds(5*60):time_mod(end);

            time_mod.Format = 'm'; x_ticks = round(x_ticks,'minutes');


            fig = figure('Renderer', 'painters', 'Position', [10 10 1000 500],'visible','off');
            plot(time_mod,concat_data.(ABP),'black','LineWidth',1.5); hold on;
            plot(time_mod,concat_data.lower,'Color',[0 0.4470 0.7410]);
            plot(time_mod,concat_data.upper,'Color',[0 0.4470 0.7410]);
            plot(time_mod,concat_data.mapopt);
            xticks(x_ticks)


            xlabel('Time (min)'); ylabel('MAP (mmHg)'); title(['Event: ', num2str(event_id),', Time taken: ',datestr(time_taken)])
            saveas(fig,[num2str(event_id),'.jpg'])
            close all


            cd(original_dir);
            cd('data')
            
            time_mod_table = table(time_mod);  time_mod_table.Properties.VariableNames = {['time']};
            abp = table(concat_data.(ABP)); abp.Properties.VariableNames = {['abp']};
            lla = table(concat_data.lower); lla.Properties.VariableNames = {['lla']};
            ula = table(concat_data.upper); ula.Properties.VariableNames = {['ula']};
            mapopt = table(concat_data.mapopt); mapopt.Properties.VariableNames = {['mapopt']};

            master_table = [time_mod_table,abp,lla,ula,mapopt];
            writetable(master_table,[num2str(event_id),'.csv'])
            
            cd(original_dir)


            
        end


      


    end

   



end



summary_stats = epoch_file_kim;
    

        
end







