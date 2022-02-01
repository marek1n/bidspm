function expectedOptions = defaultOptions(taskName)
  %
  % (C) Copyright 2021 CPP_SPM developers

  expectedOptions.verbosity = 1;
  expectedOptions.dryRun = false;

  expectedOptions.bidsFilterFile = struct( ...
                                          'fmap', struct('modality', 'fmap'), ...
                                          'bold', struct('modality', 'func', 'suffix', 'bold'), ...
                                          't2w',  struct('modality', 'anat', 'suffix', 'T2w'), ...
                                          't1w',  struct('modality', 'anat', ...
                                                         'space', '', ...
                                                         'suffix', 'T1w'), ...
                                          'roi',  struct('modality', 'roi', 'suffix', 'roi'));

  expectedOptions.pipeline.type =  '';
  expectedOptions.pipeline.name = 'cpp_spm';

  expectedOptions.anatOnly = false;

  expectedOptions.space = {'individual'    'IXI549Space'};

  expectedOptions.useBidsSchema = false;

  expectedOptions.fwhm.func = 6;
  expectedOptions.fwhm.contrast = 6;

  expectedOptions.stc.sliceOrder = [];
  expectedOptions.stc.referenceSlice = [];
  expectedOptions.stc.skip = false;

  expectedOptions.dir = struct('input', '', ...
                               'output', '', ...
                               'derivatives', '', ...
                               'raw', '', ...
                               'preproc', '', ...
                               'stats', '', ...
                               'jobs', '');

  expectedOptions.funcVoxelDims = [];

  expectedOptions.funcVolToSelect = [];

  expectedOptions.groups = {''};
  expectedOptions.subjects = {[]};

  expectedOptions.query.modality = {'anat', 'func'};

  expectedOptions.segment.force = false;

  expectedOptions.skullstrip.threshold = 0.75;
  expectedOptions.skullstrip.mean = false;

  expectedOptions.realign.useUnwarp = true;
  expectedOptions.useFieldmaps = true;

  expectedOptions.taskName = {''};

  expectedOptions.zeropad = 2;

  expectedOptions.rename = true;

  expectedOptions.QA.glm.do = true;
  expectedOptions.QA.anat.do = true;
  expectedOptions.QA.func.carpetPlot = true;
  expectedOptions.QA.func.Motion = 'on';
  expectedOptions.QA.func.FD = 'on';
  expectedOptions.QA.func.Voltera = 'on';
  expectedOptions.QA.func.Globals = 'on';
  expectedOptions.QA.func.Movie = 'off';
  expectedOptions.QA.func.Basics = 'on';

  expectedOptions.glm.roibased.do = false;
  expectedOptions.glm.maxNbVols = Inf;
  expectedOptions.glm.useDummyRegressor = false;

  expectedOptions.model.file = '';
  expectedOptions.model.designOnly = false;
  expectedOptions.contrastList = {};

  expectedOptions.result.Nodes = returnDefaultResultsStructure();

  if nargin > 0
    expectedOptions.taskName = taskName;
  end
  if ~iscell(expectedOptions.taskName)
    expectedOptions.taskName = {expectedOptions.taskName};
  end

  if  checkToolbox('ALI', 'verbose', expectedOptions.verbosity > 0)
    expectedOptions = setFields(expectedOptions, ALI_my_defaults());
  end
  expectedOptions = setFields(expectedOptions, rsHRF_my_defaults());
  expectedOptions = setFields(expectedOptions, MACS_my_defaults());

  expectedOptions = orderfields(expectedOptions);

  expectedOptions = setDirectories(expectedOptions);

end
