function [status, output] = saveAndRunWorkflow(matlabbatch, batchName, opt, subLabel)
  %
  % Saves the SPM matlabbatch and runs it
  %
  % USAGE::
  %
  %   saveAndRunWorkflow(matlabbatch, batchName, opt, [subLabel])
  %
  % :param matlabbatch: list of SPM batches
  % :type matlabbatch: structure
  %
  % :param batchName: name of the batch
  % :type batchName: char
  %
  % :type opt:  structure
  % :param opt: Options chosen for the analysis.
  %             See :func:`checkOptions`.
  % :type opt: structure
  %
  % :param subLabel: subject label
  % :type subLabel: char
  %
  % :rtype: status
  % :rtype: output - files generated for each batch
  %

  % (C) Copyright 2019 bidspm developers

  if nargin < 4
    subLabel = [];
  end

  status = true;
  output = {};

  if ~isempty(matlabbatch)
    % TODO pass these somehow; hardcoded for now <<<<<<<
    matlabbatch{1,1}.spm.stats.fmri_spec.timing.fmri_t = 72;
    matlabbatch{1,1}.spm.stats.fmri_spec.timing.fmrit0 = 54;
    if isfield(matlabbatch{1, 1}.spm.stats.fmri_spec, 'mask')
        matlabbatch{1, 1}.spm.stats.fmri_spec = rmfield(matlabbatch{1, 1}.spm.stats.fmri_spec, 'mask');
    end

    saveMatlabBatch(matlabbatch, batchName, opt, subLabel);

    if ~opt.dryRun
      output = spm_jobman('run', matlabbatch);
    else
      status = false;
    end

  else
    status = false;

    id = 'emptyBatch';
    msg  = 'This batch is empty & will not be run.';
    logger('WARNING', msg, 'id', id, 'filename', mfilename());

  end

end
