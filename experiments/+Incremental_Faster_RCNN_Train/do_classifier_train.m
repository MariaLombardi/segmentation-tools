function [ model_classifier ] = do_classifier_train(conf, cnn_model, cls_mod, options, imdb_train )

% -------------------- CONFIG --------------------
% net_file     = './data/caffe_nets/finetune_voc_2007_trainval_iter_70k';
% cache_name   = 'v1_finetune_voc_2007_trainval_iter_70k';
% cls_mod can be 'SVMs' or 'incRLS'
crop_mode    = 'warp';
crop_padding = 16;
layer        = 7;
k_folds      = 0;

switch cls_mod
    case {'SVMs'}
           fprintf('svm classifier chosen\n')
           [model_classifier, model_classifier_kfold] = ...
           svm_classifiers_train(conf, imdb_train, cnn_model, ...
          'layer',        layer, ...
          'k_folds',      k_folds, ...
          'crop_mode',    crop_mode, ...
          'crop_padding', crop_padding);
        
    case {'gurls'}
        fprintf('gurls classifier chosen \n')
        model_classifier = GURLS_classifiers_train(options, conf, cnn_model, imdb_train);
        
    case {'rls'}
        fprintf('rls classifier chosen \n')
        model_classifier = Faster_with_RLS_train(options, conf, cnn_model, imdb_train);
    
    case {'rls_randBKG'}
        fprintf('rls classifier with random background samples chosen \n')
        model_classifier = Faster_with_RLS_train_randBKG(options, conf, cnn_model, imdb_train);


    otherwise
        error('classifier unknown');
end

