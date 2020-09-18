% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function [matlabbatch, voxDim] = setBatchRealign(matlabbatch, BIDS, subID, opt)

    matlabbatch{end + 1}.spm.spatial.realign.estwrite.eoptions.weight = {''};

    [sessions] = getInfo(BIDS, subID, opt, 'Sessions');

    sesCounter = 1;

    for iSes = 1:nbSessions

        % get all runs for that subject across all sessions
        [runs, nbRuns] = getInfo(BIDS, subID, opt, 'Runs', sessions{iSes});

        for iRun = 1:nbRuns

            % get the filename for this bold run for this task
            [fileName, subFuncDataDir] = getBoldFilename( ...
                BIDS, ...
                subID, sessions{iSes}, runs{iRun}, opt);

            % check that the file with the right prefix exist and we get and
            % save its voxeldimension
            prefix = getPrefix('preprocess', opt);
            files = inputFileValidation(subFuncDataDir, prefix, fileName);
            [voxDim, opt] = getFuncVoxelDims(opt, subFuncDataDir, prefix, fileName);

            fprintf(1, ' %s\n', files{1});

            matlabbatch{end}.spm.spatial.realign.estwrite.data{sesCounter} = ...
                cellstr(files);

            sesCounter = sesCounter + 1;

        end
    end

    % The following lines are commented out because those parameters
    % can be set in the spm_my_defaults.m
    % matlabbatch{end}.spm.spatial.realign.estwrite.eoptions.quality = 1;
    % matlabbatch{end}.spm.spatial.realign.estwrite.eoptions.sep = 2;
    % matlabbatch{end}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    % matlabbatch{end}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    % matlabbatch{end}.spm.spatial.realign.estwrite.eoptions.interp = 2;
    % matlabbatch{end}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    % matlabbatch{end}.spm.spatial.realign.estwrite.roptions.which = [0 1];
    % matlabbatch{end}.spm.spatial.realign.estwrite.roptions.interp = 3;
    % matlabbatch{end}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    % matlabbatch{end}.spm.spatial.realign.estwrite.roptions.mask = 1;

end
