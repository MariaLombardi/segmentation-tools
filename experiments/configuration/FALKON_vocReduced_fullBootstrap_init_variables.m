%% Add paths for evaluation Pascal Code and for FALKON classifier
addpath('./datasets/VOCdevkit2007/VOCdevkit/VOCcode_incremental');
addpath(genpath('../FALKON_paper'));

%% Loading workspace 
fprintf('loading training workspace..\n')
load('workspace_20k10k'); %---------------------------------------------------------------------------------------------

%% Dataset format
fprintf('Dataset format preparing...\n');

if isstruct(dataset.roidb_test)
   tmp_roi = dataset.roidb_test;
   dataset = rmfield(dataset,'roidb_test');
   dataset.roidb_test{1} = tmp_roi;
   clear tmp_roi;
end
if isstruct(dataset.imdb_test)
   tmp_imdb = dataset.imdb_test;
   dataset = rmfield(dataset,'imdb_test');
   dataset.imdb_test{1} = tmp_imdb;
   clear tmp_imdb
end

%% Faster and features settings
model.stage2_rpn.nms                  = model.final_test.nms;
model.feature_extraction.binary_file  = model.stage2_fast_rcnn.output_model_file;
model.feature_extraction.net_def_file = model.stage2_fast_rcnn.test_net_def_file;
feature_layer                         = 'fc7';

model.feature_extraction.cache_name = 'feature_extraction_cache'; %-----------------------------------------------------

model.classifiers.binary_file = model.feature_extraction.binary_file;
model.classifiers.net_def_file = model.feature_extraction.net_def_file;
model.classifiers.training_opts.cache_name = model.feature_extraction.cache_name;
model.classifiers.classes = dataset.imdb_test{1}.classes;

fprintf('Creating results and output directories...\n');
results_dir = ['results_FALKON_vocReduced_fullbootStrap/']; %----------------------------------------------------------------
results_file_name = ['results.txt']; %unused
% imdb_val_cache_name = imdb_cache_name; %-------------------------------------------------------------------------------------------

boxes_dir = ['cachedir/vocReduced_test_FALKON_fullbootStrap/']; %------------------------------------------------------------------
bbox_model_suffix = 'full_bootstrap_reduced'; %---------------------------------------------------------------------------------------

mkdir(results_dir);
mkdir(boxes_dir);

conf_fast_rcnn.boxes_dir = boxes_dir;


%% Classifier options
fprintf('Classifier options setting...\n');
cls_mode = 'rls_falkon_fullBootstrap'; %---------------------------------------------------------------------------------------------

train_classifier_options = struct;
train_classifier_options.cross_validation = struct;
train_classifier_options.cross_validation.required = true;

% negatives_selection.policy = 'bootStrap';
% negatives_selection.btstr_size = 5000;
% negatives_selection.iterations = 3;
rebalancing = 'inv_freq';

%FALKON options -----------------------------------------------------------------------------------------------------------
train_classifier_options.cache_dir = '';
train_classifier_options.memToUse = 10;          % GB of memory to use (using "[]" will allow the machine to use all the free memory)
train_classifier_options.useGPU = 1;             % flag for using or not the GPU
% train_classifier_options.T= iterations;
