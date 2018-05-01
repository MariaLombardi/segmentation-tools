%% TRAIN OPTIONS
disp('Adding required paths...');
addpath(genpath('../FALKON_paper'));

%% PATHS
disp('Configuring required paths...');
current_path    = pwd;
cnn_model_path          = [current_path '/output_iCWT_TASK1_10objs_40k20k_newBatchSize/faster_rcnn_final']; %-------------------------------------------
feature_statistics_path = [current_path '/Demo/Conf/statistics_T1features_forT2.mat' ]; % We need to calculate again feature statistics


%% FILES
default_dataset_name      = 'def_dataset.mat'; %---------------------------------------------------------------------------------------------------------------
default_model_name        = 'def_model.mat'; %---------------------------------------------------------------------------------------------------------------

%% CAFFE
cnn_model.opts.caffe_version           = 'caffe_faster_rcnn';
cnn_model.opts.gpu_id                  = 1;

%% RPN PARAMS
disp('Configuring RPN params...');
cnn_model.opts.per_nms_topN            = 6000;
cnn_model.opts.nms_overlap_thres       = 0.7;
after_nms_topN_train                   = 900; %---------------------------------------------------------------------------------------------------------------
after_nms_topN_test                    = 300; %---------------------------------------------------------------------------------------------------------------
cnn_model.opts.use_gpu                 = true;
cnn_model.opts.test_scales             = 600;

%% FEATURES PARAMS
disp('Configuring Features params...');
ld = load(feature_statistics_path);
statistics.standard_deviation          = ld.standard_deviation;
statistics.mean_feat                   = ld.mean_feat;
statistics.mean_norm                   = ld.mean_norm;
clear ld;

%% Classifier options
fprintf('Classifier options setting...\n');
cls_opts = struct;
cls_opts.cls_mod = 'FALKON';
max_img_per_class                      = 700; %---------------------------------------------------------------------------------------------------------------

negatives_selection.policy             = 'bootStrap';
negatives_selection.batch_size         = 1500; %---------------------------------------------------------------------------------------------------------------
negatives_selection.iterations         = 10; %---------------------------------------------------------------------------------------------------------------
negatives_selection.neg_ovr_thresh     = 0.3;
negatives_selection.evict_easy_thresh  = -0.6;
negatives_selection.select_hard_thresh = -0.5;
cls_opts.negatives_selection           = negatives_selection;

detect_thresh                          = 0.5; %---------------------------------------------------------------------------------------------------------------

%FALKON options -----------------------------------------------------------------------------------------------------------
train_classifier_options               = struct;
train_classifier_options.memToUse      = 10;          % GB of memory to use (using "[]" will allow the machine to use all the free memory)
train_classifier_options.useGPU        = 1;           % flag for using or not the GPU
train_classifier_options.T             = 150;
train_classifier_options.M             = 250;
train_classifier_options.lambda        = 0.001;
train_classifier_options.sigma         = 10;
train_classifier_options.kernel        = gaussianKernel(train_classifier_options.sigma); 
cls_opts.train_classifier_options      = train_classifier_options;
cls_opts.statistics                    = statistics;

%% Bbox regression options
bbox_opts = struct;
bbox_opts.min_overlap = 0.6;
