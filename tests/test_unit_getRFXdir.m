% (C) Copyright 2020 CPP BIDS SPM-pipeline developers

function test_suite = test_unit_getRFXdir %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_getRFXdirBasic()

  funcFWHM = 0;
  conFWHM = 0;

  opt = setOptions('funcLocalizer');
  opt = setDerivativesDir(opt);

  rfxDir = getRFXdir(opt, funcFWHM, conFWHM);

  expectedOutput = fullfile( ...
                            fileparts(mfilename('fullpath')), ...
                            'dummyData', ...
                            'derivatives', ...
                            'cpp_spm', ...
                            'group', ...
                            'task-funcLocalizer_funcFWHM-0_conFWHM-0');

  assertEqual(exist(expectedOutput, 'dir'), 7);

end
