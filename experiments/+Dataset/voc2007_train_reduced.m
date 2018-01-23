function dataset = voc2007_train_reduced(dataset, usage, use_flip, removed_classes)
% Pascal voc 2007 trainval set
% set opts.imdb_train opts.roidb_train 
% or set opts.imdb_test opts.roidb_train

% change to point to your devkit install
devkit                      = voc2007_devkit();

switch usage
    case {'train'}
        dataset.imdb_train    = {  imdb_from_voc_reduced(devkit, 'train', '2007', use_flip) };
        dataset.roidb_train   = cellfun(@(x) x.roidb_func(x,  'removed_classes', removed_classes), dataset.imdb_train, 'UniformOutput', false);
    case {'test'}
        dataset.imdb_test     = imdb_from_voc(devkit, 'train', '2007', use_flip) ;
        dataset.roidb_test    = dataset.imdb_test.roidb_func(dataset.imdb_test);
    otherwise
        error('usage = ''train'' or ''test''');
end

end