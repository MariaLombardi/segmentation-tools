
function script_faster_rcnn_ICUB_ZF()
% script_faster_rcnn_VOC0712_ZF()
% Faster rcnn training and testing with Zeiler & Fergus model
% --------------------------------------------------------
% Faster R-CNN
% Copyright (c) 2015, Shaoqing Ren
% Licensed under The MIT License [see LICENSE for details]
% --------------------------------------------------------

clc;
%clear mex;
clear is_valid_handle; % to clear init_key
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'startup'));
%% -------------------- CONFIG --------------------
opts.caffe_version          = 'caffe_faster_rcnn';
opts.gpu_id                 = auto_select_gpu; %ELISA: todo
active_caffe_mex(opts.gpu_id, opts.caffe_version);

% do validation, or not 
opts.do_val                 = false; %ELISA: changed
% model
model                       = Model.ZF_for_Faster_RCNN_ICUB; %ELISA: changed
% cache base
cache_base_proposal         = 'faster_rcnn_ICUB_ZF'; %ELISA: changed
cache_base_fast_rcnn        = '';
% train/test data
dataset                     = [];
use_flipped                 = true;
dataset                     = Dataset.icub_trainval(dataset, 'train', use_flipped); %ELISA: changed
dataset                     = Dataset.icub_test(dataset, 'test', false); %ELISA: changed

%% -------------------- PRETRAIN --------------------
% conf
conf_proposal               = proposal_config('image_means', model.mean_image, 'feat_stride', model.feat_stride);
fprintf('proposal_config\n');
conf_fast_rcnn              = fast_rcnn_config('image_means', model.mean_image);
fprintf('fast_rcnn_config\n');
% set cache folder for each stage
model                       = Faster_RCNN_Train.set_cache_folder(cache_base_proposal, cache_base_fast_rcnn, model); %ELISA: to look if it is correct
fprintf('Faster_RCNN_Train.set_cache_folder\n');

% generate anchors and pre-calculate output size of rpn network 
[conf_proposal.anchors, conf_proposal.output_width_map, conf_proposal.output_height_map] ...
                            = proposal_prepare_anchors(conf_proposal, model.stage1_rpn.cache_name, model.stage1_rpn.test_net_def_file); %ELISA: to look if it is correct
fprintf('proposal_prepare_anchors\n');

%%  stage one proposal
fprintf('\n***************\n stage one proposal \n***************\n');
% train
model.stage1_rpn            = Faster_RCNN_Train.do_proposal_train(conf_proposal, dataset, model.stage1_rpn, opts.do_val);
fprintf('Faster_RCNN_Train.do_proposal_train');

% test
dataset.roidb_train        	= cellfun(@(x, y) Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage1_rpn, x, y), dataset.imdb_train, dataset.roidb_train, 'UniformOutput', false);

% dataset.roidb_test        	= Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage1_rpn, dataset.imdb_test, dataset.roidb_test);

%%  stage one fast rcnn
fprintf('\n***************\n stage one fast rcnn\n***************\n');
% train
model.stage1_fast_rcnn      = Faster_RCNN_Train.do_fast_rcnn_train(conf_fast_rcnn, dataset, model.stage1_fast_rcnn, opts.do_val);
% test
% opts.mAP                    = Faster_RCNN_Train.do_fast_rcnn_test(conf_fast_rcnn, model.stage1_fast_rcnn, dataset.imdb_test, dataset.roidb_test);

%%  stage two proposal
% net proposal
fprintf('\n***************\n stage two proposal\n***************\n');
% train
model.stage2_rpn.init_net_file = model.stage1_fast_rcnn.output_model_file;
model.stage2_rpn            = Faster_RCNN_Train.do_proposal_train(conf_proposal, dataset, model.stage2_rpn, opts.do_val);
% test
dataset.roidb_train       	= cellfun(@(x, y) Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage2_rpn, x, y), dataset.imdb_train, dataset.roidb_train, 'UniformOutput', false);
% dataset.roidb_test       	= Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage2_rpn, dataset.imdb_test, dataset.roidb_test);

%%  stage two fast rcnn
fprintf('\n***************\n stage two fast rcnn\n***************\n');
% train
% model.stage2_fast_rcnn.init_net_file = model.stage1_fast_rcnn.output_model_file;
model.stage2_fast_rcnn.init_net_file = model.stage2_rpn.output_model_file;
model.stage2_fast_rcnn      = Faster_RCNN_Train.do_fast_rcnn_train(conf_fast_rcnn, dataset, model.stage2_fast_rcnn, opts.do_val);

%% -------------------- TRAIN RLS --------------------
%features extraction
dataset.roidb_train_rls     = Faster_RCNN_Train.do_proposal_test(conf_proposal, model.feature_extraction.rpn, dataset.imdb_train_TASK2, dataset.roidb_train_rls);


%% final test
fprintf('\n***************\n final test\n***************\n');
     
model.stage2_rpn.nms        = model.final_test.nms;
dataset.roidb_test          = Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage2_rpn, dataset.imdb_test, dataset.roidb_test);
opts.final_mAP              = Faster_RCNN_Train.do_fast_rcnn_test(conf_fast_rcnn, model.stage2_fast_rcnn, dataset.imdb_test, dataset.roidb_test);

% save final models, for outside tester
Faster_RCNN_Train.gather_rpn_fast_rcnn_models(conf_proposal, conf_fast_rcnn, model, dataset);
end

function [anchors, output_width_map, output_height_map] = proposal_prepare_anchors(conf, cache_name, test_net_def_file)
    [output_width_map, output_height_map] ...                           
                                = proposal_calc_output_size(conf, test_net_def_file);
    anchors                = proposal_generate_anchors(cache_name, ...
                                    'scales',  2.^[3:5]);
end
