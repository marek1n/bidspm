function test_suite = test_reportBIDS %#ok<*STOUT>
  %
  % (C) Copyright 2021 CPP_SPM developers

  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_reportBIDS_smoke_test()

  opt = setOptions('vismotion');

  reportBIDS(opt);
  
  if isGithubCi
    return
  end

  assertEqual(exist(fullfile(opt.dir.preproc, ...
                             'sub-ctrl01', ...
                             'reports', ...
                             'dataset-cpp_spm-preproc_bids-matlab_report.md'), ...
                    'file'), ...
              2);

end
