function script_faster_rcnn_ICUB_ZF_voc_meanImage()

clc;
clear mex;
clear is_valid_handle; % to clear init_key
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'startup'));
%% -------------------- CONFIG --------------------
opts.caffe_version          = 'caffe_faster_rcnn';
opts.gpu_id                 = 2;
active_caffe_mex(opts.gpu_id, opts.caffe_version);
addpath('./datasets/VOCdevkit2007/VOCcode_incremental');

% do validation, or not 
opts.do_val                 = false;
% model
model                       = Model.ZF_for_Faster_RCNN_ICUB_from_voc_voc_meanImage;
% cache base
cache_base_proposal         = 'faster_rcnn_ICUB_ZF';
cache_base_fast_rcnn        = '';
%dataset
dataset.TASK1                     = [];
use_flipped                 = false;
imdb_cache_name = 'cache_iCWT_TASK1_voc_meanImage';
mkdir(['imdb/' imdb_cache_name]);
chosen_classes = {'cellphone1','cellphone2', 'mouse2', 'mouse5', 'perfume1', 'perfume4', ...
                  'remote4', 'remote5', 'soapdispenser1', 'soapdispenser4', 'sunglasses4', ...
                  'sunglasses5',  'glass6', 'glass8', 'hairbrush1', 'hairbrush4', 'ovenglove1', ...
                  'ovenglove7', 'squeezer5', 'squeezer8'};
              
dataset.TASK1                     = Dataset.icub_dataset(dataset.TASK1, 'train', use_flipped, imdb_cache_name, 'train_TASK1_20objs', chosen_classes);
dataset.TASK1                     = Dataset.icub_dataset(dataset.TASK1, 'test', false, imdb_cache_name, 'test_TASK1_20objs', chosen_classes);
output_dir                        = 'output_iCWT_TASK1_firtune_from_voc_voc_meanImage';

%% -------------------- TRAIN --------------------
% conf
fprintf('preparing configurations...\n');
conf_proposal               = proposal_config('image_means', model.mean_image, 'feat_stride', model.feat_stride);
conf_fast_rcnn              = fast_rcnn_config('image_means', model.mean_image);

% set cache folder for each stage
fprintf('Setting cache folders...\n');
model                       = Faster_RCNN_Train.set_cache_folder(cache_base_proposal, cache_base_fast_rcnn, model);

% generate anchors and pre-calculate output size of rpn network 
fprintf('Generating proposals anchors...\n');
[conf_proposal.anchors, conf_proposal.output_width_map, conf_proposal.output_height_map] ...
                            = proposal_prepare_anchors(conf_proposal, model.stage1_rpn.cache_name, model.stage1_rpn.test_net_def_file); %ELISA: to look if it is correct

%%  stage one proposal
fprintf('\n***************\n stage one proposal \n***************\n');
% train
model.stage1_rpn            = Faster_RCNN_Train.do_proposal_train(conf_proposal, dataset.TASK1, model.stage1_rpn, opts.do_val, output_dir);
% test
dataset.TASK1.roidb_train        	= cellfun(@(x, y) Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage1_rpn, output_dir, x, y), dataset.TASK1.imdb_train, dataset.TASK1.roidb_train, 'UniformOutput', false);

%%  stage one fast rcnn
fprintf('\n***************\n stage one fast rcnn\n***************\n');
% train
model.stage1_fast_rcnn      = Faster_RCNN_Train.do_fast_rcnn_train_finetune(conf_fast_rcnn, dataset.TASK1, model.stage1_fast_rcnn, opts.do_val, output_dir);

%%  stage two proposal
fprintf('\n***************\n stage two proposal\n***************\n');
% train
model.stage2_rpn.init_net_file = model.stage1_fast_rcnn.output_model_file;
model.stage2_rpn            = Faster_RCNN_Train.do_proposal_train(conf_proposal, dataset.TASK1, model.stage2_rpn, opts.do_val, output_dir);
% test
dataset.TASK1.roidb_train       	= cellfun(@(x, y) Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage2_rpn, output_dir, x, y), dataset.TASK1.imdb_train, dataset.TASK1.roidb_train, 'UniformOutput', false);

%%  stage two fast rcnn
fprintf('\n***************\n stage two fast rcnn\n***************\n');
% train
model.stage2_fast_rcnn.init_net_file = model.stage1_fast_rcnn.output_model_file;
% model.stage2_fast_rcnn.init_net_file = model.stage2_rpn.output_model_file;
model.stage2_fast_rcnn      = Faster_RCNN_Train.do_fast_rcnn_train_finetune(conf_fast_rcnn, dataset.TASK1, model.stage2_fast_rcnn, opts.do_val, output_dir);

%% final test
fprintf('\n***************\nfinal test\n***************\n');
model.stage2_rpn.nms        = model.final_test.nms;
fprintf('saving workspace...');
save('workspaces/ZF_iCWT_TASK1_voc_meanImage', '-v7.3');

fprintf('saving models...');
%Faster_RCNN_Train.gather_rpn_fast_rcnn_models(conf_proposal, conf_fast_rcnn, model, dataset.TASK1);

if isstruct(dataset.TASK1.roidb_test)
   tmp_roi = dataset.TASK1.roidb_test;
   dataset.TASK1 = rmfield(dataset.TASK1,'roidb_test');
   dataset.TASK1.roidb_test{1} = tmp_roi;
end
if isstruct(dataset.TASK1.imdb_test)
   tmp_imdb = dataset.TASK1.imdb_test;
   dataset.TASK1 = rmfield(dataset.TASK1,'imdb_test');
   dataset.TASK1.imdb_test{1} = tmp_imdb;
end
dataset.TASK1.roidb_test       	= cellfun(@(x, y) Faster_RCNN_Train.do_proposal_test(conf_proposal, model.stage2_rpn,output_dir, x, y), dataset.TASK1.imdb_test, dataset.TASK1.roidb_test, 'UniformOutput', false);
opts.final_mAP                  = cellfun(@(x, y) Faster_RCNN_Train.do_fast_rcnn_test(conf_fast_rcnn, model.stage2_fast_rcnn, output_dir, x, y), dataset.TASK1.imdb_test, dataset.TASK1.roidb_test, 'UniformOutput', false);
save('workspaces/ZF_iCWT_TASK1_voc_meanImage', '-v7.3');

end

function [anchors, output_width_map, output_height_map] = proposal_prepare_anchors(conf, cache_name, test_net_def_file)
    [output_width_map, output_height_map] ...                           
                                = proposal_calc_output_size(conf, test_net_def_file);
    anchors                = proposal_generate_anchors(cache_name, ...
                                    'scales',  2.^[3:5]);
end
