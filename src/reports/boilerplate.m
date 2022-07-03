function outputFile = boilerplate(varargin)
  %
  % USAGE::
  %
  %     outputFile = boilerplate(opt, ...
  %                             'outputPath', outputPath, ...
  %                             'pipelineType', pipelineType, ...
  %                             'partialsPath', partialsPath, ...
  %                             'verbosity', 2)
  %
  % :type opt:  structure
  % :param opt: Options chosen for the analysis.
  %             See  also: checkOptions
  % :type opt: structure
  %
  % :param outputPath:
  % :type outputPath: char
  %
  % :param pipelineType: ``'preproc'`` or ``'stats``
  % :type pipelineType: char
  %
  % :param partialsPath:
  % :type partialsPath: path
  %
  % :param verbose:
  % :type verbose: boolean
  %
  %
  % EXAMPLE::
  %
  %   opt.model.file = path_to_model;
  %   opt.designType = 'event';
  %   opt = checkOptions(opt);
  %
  %   outputFile = boilerplate(opt, ...
  %                             'outputPath', pwd, ...
  %                             'pipelineType', 'stats', ...
  %                             'verbosity', 2)
  %
  %
  % (C) Copyright 2022 CPP_SPM developers

  defaultPartialsPath = fullfile(fileparts(mfilename('fullpath')), 'partials');

  args = inputParser;

  args.addRequired('opt', @isstruct);
  args.addParameter('outputPath', '', @ischar);
  args.addParameter('pipelineType', 'spatial_preproc', @ischar);
  args.addParameter('partialsPath', defaultPartialsPath, @isdir);
  args.addParameter('verbosity', 2);

  args.parse(varargin{:});

  opt = args.Results.opt;
  outputPath = args.Results.outputPath;
  pipelineType = args.Results.pipelineType;
  partialsPath = args.Results.partialsPath;
  opt.verbosity = args.Results.verbosity;

  %% get info
  [OS, generatedBy] = getEnvInfo(opt);
  opt.OS = OS;
  opt.generatedBy = generatedBy;

  if strcmp(OS.name, 'GLNXA64')
    opt.OS.name = 'unix';
  end

  if strcmp(pipelineType, 'spatial_preproc')

    opt.normalization = false;
    if ismember('IXI549Space', opt.space)
      opt.normalization = true;
    end

    opt.unwarp = false;
    if opt.realign.useUnwarp
      opt.unwarp = true;
    end

    opt.smoothing = true;
    if opt.fwhm.func == 0
      opt.smoothing = false;
    end

  elseif strcmp(pipelineType, 'stats')

    opt.smoothing = true;
    if opt.fwhm.contrast == 0
      opt.smoothing = false;
    end

    bm = BidsModel('file', opt.model.file);

    opt.taskName = strjoin(bm.Input.task, ', ');

    if isfield(bm.Input, 'space')
      opt.space = bm.Input.space;
    end

    opt.HighPassFilterCutoffSecs = round(bm.getHighPassFilter());

    opt.SerialCorrelationCorrection = bm.getSerialCorrelationCorrection;
    opt.FAST = false;
    if strcmpi(opt.SerialCorrelationCorrection, 'fast')
      opt.FAST = true;
    end

    opt = setConvolve(opt, bm);

    opt = setDerivatives(opt, bm);

    opt = setConfounds(opt, bm);

    opt.group_level = false;
    if ~isempty(bm.get_nodes('Level', 'dataset'))

      contrasts = genList('name', getDummyContrastsList('dataset_level', bm));

      opt.group_level = struct('contrasts', {contrasts});

    end

  end

  %% render
  if strcmp(pipelineType, 'preproc')
    fileToRender = fullfile(fileparts(mfilename('fullpath')), 'boilerplate_preprocess.mustache');

  elseif strcmp(pipelineType, 'stats')
    fileToRender = fullfile(fileparts(mfilename('fullpath')), 'boilerplate_stats.mustache');

  end

  output = octache(fileToRender, ...
                   'data', opt, ...
                   'partials_path', partialsPath, ...
                   'partials_ext', 'mustache', ...
                   'l_del', '{{', ...
                   'r_del', '}}', ...
                   'warn', true, ...
                   'keep', true);

  % hack because octache may sometimes return cells and not arrays
  % if something in the data is a cell
  if iscell(output)
    output = strjoin(output);
  end

  %% print to screen
  printToScreen(output, opt);

  %% print to file
  outputFile = printToFile(output, outputPath, pipelineType);

end

function list = genList(name, elements)

  list = '';

  if ~isempty(elements) && iscell(elements)
    for i = 1:numel(elements)
      list{i} = struct(name, elements{i});
    end
  end

end

function opt = setConfounds(opt, bm)

  opt.confounds = false;

  rootNode = bm.getRootNode();
  designMatrix = rootNode.Model.X;
  designMatrix = removeIntercept(designMatrix);

  variablesToConvolve = bm.getVariablesToConvolve();

  confoundsIdx = ~ismember(designMatrix, variablesToConvolve);
  if sum(confoundsIdx) > 0

    confounds = struct('motion', false, ...
                       'tissue', false, ...
                       'scrubbing', false);

    confoundsNames = designMatrix(confoundsIdx);

    motionRegressorRegexp = '^(rot)|(trans)|(std_dvars)|(dvars)|(framewise_displacement).*';
    isMotionRegressor = ~cellfun('isempty', regexp(confoundsNames, ...
                                                   motionRegressorRegexp, ...
                                                   'match'));
    if any(isMotionRegressor)
      confounds.motion = true;
    end

    isTissueRegressor = ~cellfun('isempty', regexp(confoundsNames, ...
                                                   '^(csf)|(white_matter)|(global_signal).*', ...
                                                   'match'));
    if any(isTissueRegressor)
      confounds.tissue = true;
    end

    isOutlier = ~cellfun('isempty', regexp(confoundsNames, ...
                                           '^.*outlier.*$', ...
                                           'match'));
    if any(isOutlier)
      confounds.scrubbing = true;
    end

    confounds.variables = genList('name', confoundsNames);

    opt.confounds = confounds;
  end

end

function opt = setConvolve(opt, bm)

  opt.convolve = false;

  variablesToConvolve = bm.getVariablesToConvolve();

  variablesToConvolve = regexprep(variablesToConvolve, 'trial_type.', '');

  opt.convolve = genList('variablesToConvolve', variablesToConvolve);

end

function opt = setDerivatives(opt, bm)

  opt.derivatives = false;

  derivatives = bm.getHRFderivatives();

  if any(derivatives)
    if all(derivatives == [1 0])
      derivatives = struct('type', 'temporal');
      opt.derivatives = derivatives;
    elseif all(derivatives == [1 1])
      derivatives = struct('type', 'temporal and dispersion');
      opt.derivatives = derivatives;
    end

  end
end

function outputFile = printToFile(output, outputPath, pipelineType)

  outputFile = '';

  if ~isempty(outputPath)

    spm_mkdir(outputPath);

    if strcmp(pipelineType, 'preproc')
      outputFile = 'preprocess.md';
    elseif strcmp(pipelineType, 'stats')
      outputFile = 'stats.md';
    end

    outputFile = fullfile(outputPath, outputFile);

    fid = fopen(outputFile, 'wt');
    if fid == -1
      error('Unable to open file "%s" for writing.', outputFile);
    end
    fprintf(fid, '%s', output);
    fclose(fid);

  end

end
