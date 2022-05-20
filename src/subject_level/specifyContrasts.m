function contrasts = specifyContrasts(SPM, model)
  %
  % Specifies the first level contrasts
  %
  % USAGE::
  %
  %   contrasts = specifyContrasts(SPM, taskName, model)
  %
  % :param SPM: content of SPM.mat
  % :type SPM: structure
  % :param opt:
  % :type opt: structure
  %
  % :returns: - :contrasts: (type) (dimension)
  %
  % To know the names of the columns of the design matrix, type :
  % ``strvcat(SPM.xX.name)``
  %
  %
  % (C) Copyright 2019 CPP_SPM developers

  % TODO refactor code duplication between run level and subject level

  % TODO refactor with some of the functions from the bids-model folder ?

  contrasts = struct('C', [], 'name', []);
  counter = 0;

  if numel(model.Nodes) < 1
    errorHandling(mfilename(), 'wrongStatsModel', 'No node in the model', true, true);
  end

  % check all the nodes specified in the model
  for iNode = 1:length(model.Nodes)

    node = model.Nodes(iNode);

    if iscell(node)
      node = node{1};
    end

    [contrasts, counter] = specifyDummyContrasts(contrasts, node, counter, SPM, model);

    switch lower(node.Level)

      case 'run'

        [contrasts, counter] = specifyRunLvlContrasts(contrasts, node, counter, SPM);

      case 'subject'

        if ~checkGroupBy(node)
          continue
        end

        [contrasts, counter] = specifySubLvlContrasts(contrasts, node, counter, SPM);

    end

  end

  if numel(contrasts) == 1 && isempty(contrasts.C)
    msg = 'No contrast to build';
    errorHandling(mfilename(), 'noContrast', msg, false, true);
  end

end

function [contrasts, counter] = specifyDummyContrasts(contrasts, node, counter, SPM, model)

  if ~isfield(node, 'DummyContrasts')
    return
  end

  level = lower(node.Level);

  if ismember(level, {'session', 'dataset'})
    % not implemented
    return
  end

  if strcmp(level, 'subject') && ~checkGroupBy(node)
    % only "GroupBy": ["contrast", "subject"] supported
    return
  end

  if ~isTtest(node.DummyContrasts)
    notImplemented(mfilename(), ...
                   'Only t test implemented for DummyContrasts', ...
                   true);
    return
  end

  dummyContrastsList = getDummyContrastsList(node, model);

  contrastsList = {};
  if ~isfield(node.DummyContrasts, 'Contrasts')
    % try to grab ContrastsList from design matrix or from previous Node
    contrastsList = getContrastsList(node, model);
  end

  % first the contrasts to compute automatically against baseline
  for iCon = 1:length(dummyContrastsList)

    cdtName = dummyContrastsList{iCon};
    [cdtName, regIdx] = getRegressorIdx(cdtName, SPM);

    switch level

      case 'subject'

        C = newContrast(SPM, cdtName);
        C.C(end, regIdx) = 1;
        [contrasts, counter] = appendContrast(contrasts, C, counter);
        clear regIdx;

      case 'run'

        % For each run of each condition, create a seperate contrast
        regIdx = find(regIdx);
        for iReg = 1:length(regIdx)

          % Use the SPM Sess index for the contrast name
          % TODO could be optimized
          for iSess = 1:numel(SPM.Sess)
            if ismember(regIdx(iReg), SPM.Sess(iSess).col)
              break
            end
          end

          C = newContrast(SPM, [cdtName, '_', num2str(iSess)]);

          % give each event a value of 1
          C.C(end, regIdx(iReg)) = 1;
          [contrasts, counter] = appendContrast(contrasts, C, counter);

        end

        clear regIdx;

    end

  end

  % set up DummyContrasts at subject level
  % that are based on contrast from previous level
  for iCon = 1:length(contrastsList)

    this_contrast = contrastsList{iCon};

    if isempty(this_contrast)
      continue
    end

    switch level

      case 'subject'

        C = newContrast(SPM, this_contrast.Name);

        ConditionList = this_contrast.ConditionList;

        % get regressors index corresponding to the HRF of that condition
        for iCdt = 1:length(ConditionList)

          cdtName = ConditionList{iCdt};

          [~, regIdx{iCdt}] = getRegressorIdx(cdtName, SPM);

          regIdx{iCdt} = find(regIdx{iCdt});

          C.C(end, regIdx{iCdt}) = this_contrast.Weights(iCdt);

        end
        clear regIdx;

    end

    [contrasts, counter] = appendContrast(contrasts, C, counter);

  end

end

function contrastsList = getContrastsList(node, model)

  contrastsList = {};

  switch lower(node.Level)

    case 'subject'

      % TODO relax those assumptions

      % assumptions
      assert(checkGroupBy(node));
      assert(node.Model.X == 1);

      sourceNode = getSourceNode(model, node.Name);

      % TODO transfer to BIDS model as a get_contrasts_list method
      if isfield(sourceNode, 'Contrasts')
        for i = 1:numel(sourceNode.Contrasts)
          contrastsList{end + 1} = checkContrast(sourceNode, i);
        end
      end

  end

end

function dummyContrastsList = getDummyContrastsList(node, model)

  dummyContrastsList = {};

  if isfield(node.DummyContrasts, 'Contrasts')

    dummyContrastsList = node.DummyContrasts.Contrasts;

  else

    switch lower(node.Level)

      case 'run'
        % TODO this assumes "GroupBy": ["run", "subject"] or ["run", "session", "subject"]
        dummyContrastsList = node.Model.X;

      case 'subject'

        % TODO relax those assumptions

        % assumptions
        assert(checkGroupBy(node));
        assert(node.Model.X == 1);

        sourceNode = getSourceNode(model, node.Name);

        % TODO transfer to BIDS model as a get_contrasts_list method
        if isfield(sourceNode.DummyContrasts, 'Contrasts')
          dummyContrastsList = sourceNode.DummyContrasts.Contrasts;
        end

    end

  end

end

function sourceNode = getSourceNode(bm, destinationName)

  % TODO transfer to BIDS model as a get_source method
  if ~isfield(bm, 'Edges') || isempty(bm.Edges)
    bm = bm.get_edges_from_nodes;
  end

  for i = 1:numel(bm.Edges)
    if strcmp(bm.Edges{i}.Destination, destinationName)
      source = bm.Edges{i}.Source;
      break
    end
  end

  sourceNode = bm.get_nodes('Name', source);

  if iscell(sourceNode)
    sourceNode = sourceNode{1};
  end

end

function [contrasts, counter] = specifyRunLvlContrasts(contrasts, node, counter, SPM)

  if ~isfield(node, 'Contrasts')
    return
  end

  % then the contrasts that involve contrasting conditions
  % amongst themselves or something inferior to baseline
  for iCon = 1:length(node.Contrasts)

    this_contrast = checkContrast(node, iCon);

    if isempty(this_contrast)
      continue
    end

    % get regressors index corresponding to the HRF of that condition
    ConditionList = this_contrast.ConditionList;
    for iCdt = 1:length(ConditionList)
      cdtName = ConditionList{iCdt};
      [~, regIdx{iCdt}] = getRegressorIdx(cdtName, SPM);
      regIdx{iCdt} = find(regIdx{iCdt});
    end

    % make sure all runs have all conditions
    % TODO possibly only skip the runs that are missing some conditions and not
    % all of them.
    nbRuns = unique(cellfun(@numel, regIdx));

    if length(nbRuns) > 1
      msg = sprintf('Skipping contrast %s: runs are missing condition %s', ...
                    this_contrast.Name, cdtName);
      errorHandling(mfilename(), 'runMissingCondition', msg, true, true);

      continue
    end

    % give them the value specified in the model
    for iRun = 1:nbRuns

      % Use the SPM Sess index for the contrast name
      % TODO could be optimized
      for iSess = 1:numel(SPM.Sess)
        if ismember(regIdx{1}(iRun), SPM.Sess(iSess).col)
          break
        end
      end

      C = newContrast(SPM, [this_contrast.Name, '_', num2str(iSess)]);

      for iCdt = 1:length(this_contrast.ConditionList)
        C.C(end, regIdx{iCdt}(iRun)) = this_contrast.Weights(iCdt);
      end

      [contrasts, counter] = appendContrast(contrasts, C, counter);

    end
    clear regIdx;

  end

end

function [contrasts, counter] = specifySubLvlContrasts(contrasts, node, counter, SPM)
  %
  % dead code for now but will be reused later
  %

  if ~isfield(node, 'Contrasts')
    return
  end

  % only averaging run level contrasts supported for now.
  assert(node.Model.X == 1);

  % then the contrasts that involve contrasting conditions
  % amongst themselves or something inferior to baseline
  for iCon = 1:length(node.Contrasts)

    this_contrast = checkContrast(node, iCon);

    if isempty(this_contrast)
      continue
    end

    C = newContrast(SPM, this_contrast.Name);

    for iCdt = 1:length(this_contrast.ConditionList)

      % get regressors index corresponding to the HRF of that condition
      cdtName = this_contrast.ConditionList{iCdt};
      [~, regIdx, status] = getRegressorIdx(cdtName, SPM);

      if ~status
        break
      end

      % give them the value specified in the model
      C.C(end, regIdx) = this_contrast.Weights(iCdt);

      clear regIdx;

    end

    % do not create this contrast if a condition is missing
    if ~status
      msg = sprintf('Skipping contrast %s: runs are missing condition %s', ...
                    this_contrast.Name, cdtName);
      errorHandling(mfilename(), 'runMissingCondition', msg, true, true);
    else
      [contrasts, counter] = appendContrast(contrasts, C, counter);
    end

  end

end

function C = newContrast(SPM, conName)
  C.C = zeros(1, size(SPM.xX.X, 2));
  C.name = conName;
end

function [contrasts, counter] = appendContrast(contrasts, C, counter)
  counter = counter + 1;
  contrasts(counter).C = C.C;
  contrasts(counter).name = C.name;
end

function  [cdtName, regIdx, status] = getRegressorIdx(cdtName, SPM)
  % get regressors index corresponding to the HRF of of a condition

  % get condition name
  cdtName = strrep(cdtName, 'trial_type.', '');

  % get regressors index corresponding to the HRF of that condition
  regIdx = strfind(SPM.xX.name', [' ' cdtName '*bf(1)']);
  regIdx = ~cellfun('isempty', regIdx);  %#ok<*STRCL1>

  status = checkRegressorFound(regIdx, cdtName);

end

function status = checkRegressorFound(regIdx, cdtName)
  status = true;
  regIdx = find(regIdx);
  if all(~regIdx)
    status = false;
    msg = sprintf('No regressor found for condition ''%s''', cdtName);
    errorHandling(mfilename(), 'missingRegressor', msg, true, true);
  end
end

function contrast = checkContrast(node, iCon)
  %
  % put some of that in bids.Model

  if ~isTtest(node.Contrasts(iCon))
    notImplemented(mfilename(), ...
                   'Only t test implemented for DummyContrasts', ...
                   true);
    contrast = [];
    return
  end

  contrast = node.Contrasts(iCon);
  if iscell(contrast)
    contrast = contrast{1};
  end

  if ~isfield(contrast, 'Weights')
    msg = sprintf('No weights specified for Contrast %s of Node %s', ...
                  node.Contrasts(iCon).Name, node.Name);
    errorHandling(mfilename, 'weightsRequired', msg, false);
  end

  if numel(contrast.Weights) ~= numel(contrast.ConditionList)
    msg = sprintf('Number of Weights and Conditions unequal for Contrast %s of Node %s', ...
                  node.Contrasts(iCon).Name, node.Name);
    errorHandling(mfilename, 'numelWeightsConditionMismatch', msg, false);
  end

end

function status = checkGroupBy(node)
  status = true;
  node.GroupBy = sort(node.GroupBy);
  if not(all([strcmp(node.GroupBy{1}, 'contrast') strcmp(node.GroupBy{2}, 'subject')]))
    status = false;
    notImplemented(mfilename, ...
                   'only "GroupBy": ["contrast", "subject"] supported Subject node level', ...
                   true);
  end
end
