function [  ] = Predict( imageset, classes, cnn_model, cls_model, bbox_model, gpu_id )
%INFERENCE Summary of this function goes here
%   Detailed explanation goes here

%% -------------------- CONFIG --------------------
opts.caffe_version          = 'caffe_faster_rcnn';
opts.gpu_id                 = gpu_id;
active_caffe_mex(opts.gpu_id, opts.caffe_version);

opts.per_nms_topN           = 6000;
opts.nms_overlap_thres      = 0.7;
opts.after_nms_topN         = 300;
opts.use_gpu                = true;

opts.test_scales            = 600;


%% -------------------- INIT_MODEL --------------------
proposal_detection_model    = load_proposal_detection_model(cnn_model.model_dir);
proposal_detection_model.conf_proposal.test_scales = opts.test_scales;
proposal_detection_model.conf_detection.test_scales = opts.test_scales;
if opts.use_gpu
    proposal_detection_model.conf_proposal.image_means = gpuArray(proposal_detection_model.conf_proposal.image_means);
    proposal_detection_model.conf_detection.image_means = gpuArray(proposal_detection_model.conf_detection.image_means);
end

% proposal net
rpn_net = caffe.Net(cnn_model.rpn.net_definition, 'test');
rpn_net.copy_from(cnn_model.rpn.net_model);
% fast rcnn net
fast_rcnn_net = caffe.Net(cnn_model.fast_rcnn.net_definition, 'test');
fast_rcnn_net.copy_from(cnn_model.fast_rcnn.net_model);

% caffe.init_log(fullfile(pwd, 'caffe_log'));
% proposal net
% rpn_net = caffe.Net(proposal_detection_model.proposal_net_def, 'test');
% rpn_net.copy_from(proposal_detection_model.proposal_net);
% % fast rcnn net
% fast_rcnn_net = caffe.Net(proposal_detection_model.detection_net_def, 'test');
% fast_rcnn_net.copy_from(proposal_detection_model.detection_net);

% set gpu/cpu
if opts.use_gpu
    caffe.set_mode_gpu();
else
    caffe.set_mode_cpu();
end       

%% -------------------- START PREDICTION --------------------
prediction_tic = tic;


image_ids = textread(sprintf(VOCopts.imgsetpath, image_set), '%s');
dataset_path = '/home/IIT.LOCAL/emaiettini/workspace/Repos/Incremental_Faster_RCNN/datasets/iCubWorld-Transformations'

for j = 1:length(image_ids)
    %% Fetch image
    fetch_tic = tic;
    
    im = imread(fullfile(dataset_path, image_ids{j}));    
    im = gpuArray(im);
    
    fprintf('fetching images required %f seconds', toc(fetch_tic));

    %% Region proposals and features extraction
    feature_tic = tic;
    
    % test proposal
    [boxes, scores]             = proposal_im_detect(proposal_detection_model.conf_proposal, rpn_net, im);
    aboxes                      = boxes_filter([boxes, scores], opts.per_nms_topN, opts.nms_overlap_thres, opts.after_nms_topN, opts.use_gpu);

    if proposal_detection_model.is_share_feature
        [boxes, scores]             = fast_rcnn_conv_feat_detect(proposal_detection_model.conf_detection, fast_rcnn_net, im, ...
            rpn_net.blobs(proposal_detection_model.last_shared_output_blob_name), ...
            aboxes(:, 1:4), opts.after_nms_topN);
    else
        [boxes, scores]             = fast_rcnn_im_detect(proposal_detection_model.conf_detection, fast_rcnn_net, im, ...
            aboxes(:, 1:4), opts.after_nms_topN);
    end

    fprintf('feature extraction and region proposal prediction required %f seconds', toc(feature_tic));
    
    %% Regions classification
    cls_tic = tic;
    %
    %Stuff
    %
    fprintf('Region classification required %f seconds', toc(cls_tic));

    %% Thresholding
    th_tic = tic;
    %
    %Stuff
    %
    fprintf('Thresholding bounding boxes required %f seconds', toc(th_tic));

    %% Bounding boxes refinement
    bbox_tic = tic;
    %
    %Stuff
    %
    fprintf('Bounding box refinement required %f seconds', toc(bbox_tic));

    %% Detections visualization
    vis_tic = tic;
    boxes_cell = cell(length(classes), 1);
    thres = 0.5;
    for i = 1:length(boxes_cell)
        boxes_cell{i} = [boxes(:, (1+(i-1)*4):(i*4)), scores(:, i)];
        boxes_cell{i} = boxes_cell{i}(nms(boxes_cell{i}, 0.3), :);
        
        I = boxes_cell{i}(:, 5) >= thres;
        boxes_cell{i} = boxes_cell{i}(I, :);
    end
    f = figure(j);
    showboxes(im, boxes_cell, classes, 'voc');
    fprintf('Bounding box refinement required %f seconds', toc(vis_tic));

    fprintf('Prediction required %f seconds', toc(prediction_tic));
end


end


function proposal_detection_model = load_proposal_detection_model(model_dir)
    ld                          = load(fullfile(model_dir, 'model'));
    proposal_detection_model    = ld.proposal_detection_model;
    clear ld;
    
    proposal_detection_model.proposal_net_def ...
                                = fullfile(model_dir, proposal_detection_model.proposal_net_def);
    proposal_detection_model.proposal_net ...
                                = fullfile(model_dir, proposal_detection_model.proposal_net);
    proposal_detection_model.detection_net_def ...
                                = fullfile(model_dir, proposal_detection_model.detection_net_def);
    proposal_detection_model.detection_net ...
                                = fullfile(model_dir, proposal_detection_model.detection_net);
    
end

function aboxes = boxes_filter(aboxes, per_nms_topN, nms_overlap_thres, after_nms_topN, use_gpu)
    % to speed up nms
    if per_nms_topN > 0
        aboxes = aboxes(1:min(length(aboxes), per_nms_topN), :);
    end
    % do nms
    if nms_overlap_thres > 0 && nms_overlap_thres < 1
        aboxes = aboxes(nms(aboxes, nms_overlap_thres, use_gpu), :);       
    end
    if after_nms_topN > 0
        aboxes = aboxes(1:min(length(aboxes), after_nms_topN), :);
    end
end
