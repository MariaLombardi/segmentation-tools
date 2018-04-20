function [  ] = Demo_forward_yarp()
%DEMO_FORWARD Summary of this function goes here
%   Detailed explanation goes here

%% -------------------- CONFIG --------------------
yarp_initialization_forward;

configuration_script_forward;

active_caffe_mex(cnn_model.opts.gpu_id, cnn_model.opts.caffe_version);

%% -------------------- INIT_MODEL --------------------

% classifier
disp('Loading classifier model...');
load(cls_model_path);  %------------------------------------------------------------------- %TO-CHECK
if ~isempty(setdiff(model_cls{1}.classes, classes))
    error('classes provided are not the same used for training');
end

% bbox regressor
disp('Loading bbox regressor model...');
load(bbox_model_path); %-------------------------------------------------------------------%TO-CHECK

% cnn model
disp('Loading cnn model paths...');
cnn_model.proposal_detection_model    = load_proposal_detection_model(cnn_model_path);
cnn_model.proposal_detection_model.conf_proposal.test_scales = cnn_model.opts.test_scales;
cnn_model.proposal_detection_model.conf_detection.test_scales = cnn_model.opts.test_scales;
if cnn_model.opts.use_gpu
   cnn_model.proposal_detection_model.conf_proposal.image_means = gpuArray(cnn_model.proposal_detection_model.conf_proposal.image_means);
   cnn_model.proposal_detection_model.conf_detection.image_means = gpuArray(cnn_model.proposal_detection_model.conf_detection.image_means);
end

% proposal net
disp('Setting RPN...');
cnn_model.rpn_net = caffe.Net(cnn_model.proposal_detection_model.proposal_net_def, 'test');
cnn_model.rpn_net.copy_from(cnn_model.proposal_detection_model.proposal_net);
% fast rcnn net
disp('Setting Fast R-CNN...');
cnn_model.fast_rcnn_net = caffe.Net(cnn_model.proposal_detection_model.detection_net_def, 'test');
cnn_model.fast_rcnn_net.copy_from(cnn_model.proposal_detection_model.detection_net);

% set gpu/cpu
if cnn_model.opts.use_gpu
    caffe.set_mode_gpu();
else
    caffe.set_mode_cpu();
end   

%% -------------------- START PREDICTION --------------------

h=480;
w=640;
pixSize=3;
tool=yarp.matlab.YarpImageHelper(h, w);

while (true)
    
    %% Fetch image
    total_tic = tic;
    fetch_tic = tic;
   
    
    disp('Waiting image from port...');
    yarpImage=portImage.read(true); % get the yarp image from port
    if (sum(size(yarpImage)) ~= 0)  % check size of bottle 
        
         TEST = reshape(tool.getRawImg(yarpImage), [h w pixSize]); % need to reshape the matrix from 1D to h w pixelSize       
         im=uint8(zeros(h, w, pixSize)); % create an empty image with the correct dimentions
         im(:,:,1)= cast(TEST(:,:,1),'uint8'); % copy the image to the previoulsy create matrix
         im(:,:,2)= cast(TEST(:,:,2),'uint8');
         im(:,:,3)= cast(TEST(:,:,3),'uint8');        
%          im_gpu = gpuArray(im);               %TO-CHECK

         fprintf('Fetching images required %f seconds\n', toc(fetch_tic));

         %% Performing detection
         prediction_tic = tic;

         [cls_scores boxes] = Detect(im, classes, cnn_model, model_cls{1}, model_bbox, detect_thresh);
         fprintf('Prediction required %f seconds\n', toc(prediction_tic));

         %% Sending detections        
         send_tic = tic;
         boxes_cell = cell(length(classes), 1);
         for i = 1:length(boxes_cell)
           boxes_cell{i} = [boxes{i}, cls_scores{i}];
         end
         is_dets_per_class = cell2mat(cellfun(@(x) ~isempty(x), boxes_cell, 'UniformOutput', false));
         if sum(is_dets_per_class)
            sendDetections(boxes_cell, portDets, portImg, im, classes, tool, [h,w,pixSize]);
         end
         
         fprintf('Sending image and detections required %f seconds\n', toc(send_tic));
         fprintf('Complete process required %f seconds\n\n', toc(total_tic));
     end
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
% function sendDetectedImage(image, port, tool, img_dims)
%      yarp_img = yarp.ImageRgb();                                                 % create a new yarp image to send results to ports
%      yarp_img.resize(img_dims(2),img_dims(1));                                   % resize it to the desired size
%      yarp_img.zero();                                                            % set all pixels to black
%      image = reshape(image, [img_dims(1)*img_dims(2)*img_dims(3) 1]);            % reshape the matlab image to 1D
%      tempImg = cast(image ,'int16');                                             % cast it to int16
%      yarp_img = tool.setRawImg(tempImg, img_dims(1), img_dims(2), img_dims(3));  % pass it to the setRawImg function (returns the full image)
%      port.write(yarp_img);                                                       % send it off 
% end

function sendDetections(detections, detPort, imgPort, image, classes, tool, img_dims)
    
    b = detPort.prepare();
    b.clear();
    
    % Prepare bottle b with detections and labels
    for i = 1:length(detections)
        for j = 1:size(detections{i},1)
            % Prepare list
            det_list = b.addList();
            % Add bounding box coordinates, score and string label of detected the object
            det_list.addDouble(detections{i}(j,1));       % x_min
            det_list.addDouble(detections{i}(j,2));       % y_min
            det_list.addDouble(detections{i}(j,3));       % x_max
            det_list.addDouble(detections{i}(j,4));       % y_max
            det_list.addDouble(detections{i}(j,5));       % score
            det_list.addString(classes{i}); % string label
        end
    end
    
    % Prepare image to send
    yarp_img = yarp.ImageRgb();                                                 % create a new yarp image to send results to ports
    yarp_img.resize(img_dims(2),img_dims(1));                                   % resize it to the desired size
    yarp_img.zero();                                                            % set all pixels to black
    image = reshape(image, [img_dims(1)*img_dims(2)*img_dims(3) 1]);            % reshape the matlab image to 1D
    tempImg = cast(image ,'int16');                                             % cast it to int16
    yarp_img = tool.setRawImg(tempImg, img_dims(1), img_dims(2), img_dims(3));  % pass it to the setRawImg function (returns the full image)
    
    % Set timestamp for the two ports
    stamp = yarp.Stamp();
    detPort.setEnvelope(stamp);
    imgPort.setEnvelope(stamp);
    
    % Send detections and image
    detPort.write();
    imgPort.write(yarp_img);
end

function closePorts(portImage,port,portFilters)

    disp('Going to close the port');
    portImage.close;
    port.close;
    portFilters.close;
    portDets.close;
    
end