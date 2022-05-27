% (C) Copyright 2019 CPP_SPM developers

clear;
clc;

addpath(fullfile(pwd, '..', '..'));
cpp_spm();

opt = get_option_preprocess();

reportBIDS(opt);

bidsCopyInputFolder(opt, 'unzip', true);

bidsSTC(opt);

bidsSpatialPrepro(opt);

bidsSmoothing(opt);
