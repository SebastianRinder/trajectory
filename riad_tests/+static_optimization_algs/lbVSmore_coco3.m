clear variables;
close all;

% local bayes vs more 
DIM = 3;

rootPlot = '+static_optimization_algs/xp_coco3/';
if(~exist(rootPlot,'dir'))
    mkdir(rootPlot);
end

%%% generating the functions
selectedFuns = [8, 15:24];
nbFun = length(selectedFuns);
funsAll = benchmarks('handles');
funs = cell(nbFun, 1);

for k = 1:nbFun    
    funs{k} = static_optimization_algs.CocoWrapper(funsAll{selectedFuns(k)}, ['f' num2str(selectedFuns(k))]);
end

%%% the algorithms
algs =  {static_optimization_algs.More; static_optimization_algs.LocalBayes;};

%%% settings
%common settings
nbAlgs = length(algs);
settings = cell(nbAlgs, 1);
initVar = 3;
mu = zeros(DIM, 1);
covC = eye(DIM) * initVar;

for k = 1:nbAlgs
    settings{k}.initVar = initVar;
    settings{k}.initDistrib = static_optimization_algs.Normal(mu, covC);
    
    settings{k}.epsiKL = .05;
    settings{k}.entropyReduction = .05;
    
    settings{k}.nbSamplesPerIter = 10;
    settings{k}.nbInitSamples = 10;
    settings{k}.nbIter = 100;    
    settings{k}.maxIterReuse = 20;    
end

%more settings
settings{1}.useImportanceSampling = 1;
settings{1}.regularization = 1e-6;

%lb settings
settings{2}.gpStuffPath = 'GPstuff-4.7/';
settings{2}.nbPStarSamples = 100;
settings{2}.minProbaReuse = inf;
settings{2}.gpHyperOption = 'MCMC';
settings{2}.samplingOption = 'Acquisition';
settings{2}.kernelType = 'sexp';
settings{2}.featureFunction = [];
settings{2}.featureName = 'noFeature';
settings{2}.yCenteringType = 'min';

%%%%%%%%%%%%%%%%% calling the optimizers %%%%%%%%%%%%%%%%%%%
save(fullfile(rootPlot, 'xp_settings'), 'funs', 'algs', 'settings');
[all_perfs, all_evals] = static_optimization_algs.batchTestOptim(funs, algs, settings);
save(fullfile(rootPlot, 'allPerfsAndEvals'), 'all_perfs', 'all_evals');

% plottings
alg_signatures = cell(nbAlgs, 1);
for algi = 1:nbAlgs
    alg_signatures{algi} = algs{algi}.getSignature(settings{algi});
end

for k = 1:nbFun
    fname = fullfile(rootPlot, ['perfOn_' funs{k}.getSignature()]);
    hnd = figure;
    hold on;
    for algi = 1:nbAlgs
        plot(all_perfs{k, algi}(:, 1), all_perfs{k, algi}(:, 2));        
    end    
    legHnd = legend(alg_signatures{:}, 'Location','southeast');
    set(legHnd, 'interpreter', 'none');
    set(legHnd, 'FontSize', 7);
    hgexport(hnd, [fname '.eps']);
end