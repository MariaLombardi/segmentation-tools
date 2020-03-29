function [cls_scores  pred_boxes] = Detect(im, classes, cnn_model, cls_model, bbox_model, detect_thresh, show_regions, portRegs)
%INFERENCE Summary of this function goes here
%   Detailed explanation goes here

    %% Region proposals
%     regions_tic = tic;
    
    % test proposal
    [boxes, scores]             = proposal_im_detect(cnn_model.proposal_detection_model.conf_proposal, cnn_model.rpn_net, im);
    aboxes                      = boxes_filter([boxes, scores], cnn_model.opts.per_nms_topN, cnn_model.opts.nms_overlap_thres, ...
                                                cnn_model.opts.after_nms_topN, cnn_model.opts.use_gpu);
    if show_regions
        b = portRegs.prepare();
        b.clear();
        for i = 1:length(aboxes)
                % Prepare list
                reg_list = b.addList();
                % Add bounding box coordinates, score and string label of detected the object
                reg_list.addDouble(aboxes(i,1));       % x_min
                reg_list.addDouble(aboxes(i,2));       % y_min
                reg_list.addDouble(aboxes(i,3));       % x_max
                reg_list.addDouble(aboxes(i,4));       % y_max
                reg_list.addDouble(aboxes(i,5));       % score objectness
        end
        portRegs.write();
    end
%     fprintf('--Region proposal prediction required %f seconds\n', toc(regions_tic));

    %feature extraction from regions    
%     feature_tic = tic;
    if cnn_model.proposal_detection_model.is_share_feature
           features             = cnn_features_shared_conv(cnn_model.proposal_detection_model.conf_detection, im, aboxes(:, 1:4), cnn_model.fast_rcnn_net, cls_model.training_opts.feat_layer, ...
                                                           cnn_model.rpn_net.blobs(cnn_model.proposal_detection_model.last_shared_output_blob_name));
    else
           features             = cnn_features_demo(cnn_model.proposal_detection_model.conf_detection, im, aboxes(:, 1:4), ...
                                                    cnn_model.fast_rcnn_net, [], cls_model.training_opts.feat_layer);                                                
    end
%     fprintf('--Feature extraction required %f seconds\n', toc(feature_tic));
    
    %% Regions classification and scores thresholding
%     cls_tic = tic;
    features = gather(features);
    [cls_boxes, cls_scores, inds] = predict_FALKON(features, cls_model, 0.0, aboxes(:, 1:4));
%     fprintf('--Region classification required %f seconds\n', toc(cls_tic));

    %% Bounding boxes refinement
%     bbox_tic = tic;
    pred_boxes = predict_bbox_refinement( bbox_model, features, cls_boxes, length(classes), inds );
%     fprintf('--Bounding box refinement required %f seconds\n', toc(bbox_tic));
    
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
