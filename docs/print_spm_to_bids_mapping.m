% (C) Copyright 2022 Remi Gau

% TODO all mapping (one for preprocessing...) should be added here

opt = checkOptions(struct('verbosity', 0));
opt = set_spm_2_bids_defaults(opt);

opt.spm_2_bids.print_mapping(fullfile('source', 'mapping.md'));
% opt.spm_2_bids.print_mapping(fullfile('mapping.json'));
