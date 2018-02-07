%1. install anaconda
% path in bash
% python version -> Anaconda

%%%% Plot data with varying size according to reward
% figure
% minMarkerSize = 4;
% maxMarkerSize = 30;
% hold on;
% for k = 1:length(allVals)
% plot(allSamples(k, 1), allSamples(k, 2), '.r', 'MarkerSize', (maxMarkerSize - minMarkerSize) * (allVals(k) - min(allVals)) / max(allVals) + minMarkerSize);
% end
%%%

function testOptim()

% close all;
% clear variables;
%clc;
% set(0, 'DefaultFigureVisible', 'off')

%% seed control
% rng('default');
% rng('shuffle');
% seed = rng;
% seed = seed.State(1)
% seed = 534948956
% seed = 59823194
% seed = 3268008736;
%  seed = 2420527175 %good showcase for reward switch. bad quad model at iteration ~46
% seed = 3143574292 %local vs global, very good illustration
%seed = 1892178703 %local vs global optim for different kls
%seed = 2345272402 %disconnected
%seed = 3916729757
%seed = 1563644028 %bad m-projection
%seed = 3088878663 %very good m-projection (nbGauss = 50)
% rng(seed);
rootPlot = '+static_optimization_algs/plots/';
if(~exist(rootPlot,'dir'))
    mkdir(rootPlot);
end

%% objective function
% nbGauss = 25;
% muRange = 10;
% minSigma = 2;
% func = static_optimization_algs.RandomGaussianMixtureFunction(nbGauss, muRange, minSigma);
% tmpFunc = problemOptions('sexp','randGauss');
% func.opts = tmpFunc.opts;
% func.opts.dim = 2;

% %%% plotting objective
% hnd = figure(1);
% func.plot();

% funSignature = 'testOptim';
% fname = [rootPlot 'objective_' funSignature];
% hgexport(hnd, [fname '.eps']); %this works better than saveas and print





%% optimization algo
optimizers = {...
      %static_optimization_algs.RepsBandits; ...
%     static_optimization_algs.RepsBanditsIProjection; ...
%     static_optimization_algs.RepsBanditsIProjectionChol; ...
    %     static_optimization_algs.RepsBanditsDecay, ...
%     static_optimization_algs.RepsTrueGrid, ...
    % static_optimization_algs.RepsTrueGaussian,  ...
    %static_optimization_algs.RepsTrueGaussianIProjection; ...
%       static_optimization_algs.RepsBanditsGrad; ...
%       static_optimization_algs.RepsBanditsGradNonParamIS; ...
      %      static_optimization_algs.RepsBanditsGradHoeffding; ...
%     static_optimization_algs.AdaptiveMore;

%     static_optimization_algs.AdaptiveMoreMW_Rotate;
%     static_optimization_algs.AdaptiveMoreWithModelSwitch;
%   
%     static_optimization_algs.AdaptiveMoreAndersonWithModelSwitch;
%     static_optimization_algs.AdaptiveMoreStudent_Rotate;
%    static_optimization_algs.AdaptiveMoreStudentEntropy;
%     static_optimization_algs.AdaptiveMoreStudent;
%     static_optimization_algs.LocalBayes;
%     static_optimization_algs.DensityWeightedBO;
    static_optimization_algs.DensityWeightedBO_trajectory;
%     static_optimization_algs.CMAESWrapper;
%     static_optimization_algs.More;

%     static_optimization_algs.ConservativeAdaptiveMore;
%      static_optimization_algs.AdaptiveMoreIProj;
      %     static_optimization_algs.RepsBanditsGradChol; ...
%     static_optimization_algs.RepsBanditsGradReverse; ...
    };
%!!! change logDetP and how KL is computed using it

all_perfs = {};
all_kls = {};
all_signatures = {};

% init distribution and co.

optimizerInput.initVar = 1;
%mu = [0 0];
%covC = eye(2) * optimizerInput.initVar;

optimizerInput.minEpsiKL = .01;
optimizerInput.epsiKL = .05;
optimizerInput.entropyReduction = .05;
optimizerInput.nbSamplesPerIter = 4;
optimizerInput.nbInitSamples = 5;
optimizerInput.nbIter = 100;
optimizerInput.maxEvals = 500; %cmaes wrapper only depends on this.
%optimizerInput.maxIterReuse = optimizerInput.nbIter;
optimizerInput.maxIterReuse = 30;
optimizerInput.sampleDecay = .8;
optimizerInput.nbBinPerDim = 100;

optimizerInput.useImportanceSampling = 1;

optimizerInput.confidenceMW = .1;
optimizerInput.confidenceStudent = .1;

optimizerInput.confidenceCMW = .5;
optimizerInput.regularization = 1e-6;

%local bayes settings
optimizerInput.gpStuffPath = 'GPstuff-4.7/';
optimizerInput.nbPStarSamples = 100;
optimizerInput.minProbaReuse = inf;
% optimizerInput.gpHyperOption = 'MCMC';
optimizerInput.gpHyperOption = 'MAP';

optimizerInput.samplingOption = 'Acquisition';
%optimizerInput.samplingOption = 'Random';

% optimizerInput.kernelType = 'linear';
% optimizerInput.kernelType = 'sexp';
optimizerInput.kernelType = 'matern52';

% optimizerInput.featureFunction = @(x) [ones(size(x, 1), 1) x];
% optimizerInput.featureFunction = @(data) static_optimization_algs.Quadratic.getQuadFeatures(data, 1, 1);
optimizerInput.featureFunction = [];

optimizerInput.featureName = 'noFeature';
% optimizerInput.featureName = 'quadratic';

% optimizerInput.yCenteringType = 'min'; %EI maybe
optimizerInput.yCenteringType = 'mean'; %thompson sampling
% optimizerInput.yCenteringType = 'max';

optimizerInput.videoFile = [];

% seed = rng;
% seedStartOpt = seed.State(2)

% for k = 1:length(optimizers)
%     rng(seedStartOpt);
%     all_signatures{end+1} = [optimizers{k}.getSignature(optimizerInput) '_' funSignature];
% %     optimizerInput.videoFile = VideoWriter([rootPlot 'policy_search_' all_signatures{end}]);%, 'Uncompressed AVI');
% %     optimizerInput.videoFile.FrameRate = 4;
%     disp(['starting ' all_signatures{end}]);
%     tic
%     [all_perfs{end+1}] = optimizers{k}.optimizeStruct(optimizerInput, func);
%     toc
% end

% optimizerType = 'local';
optimizerType = 'global';

trials = 5;
cores = 4;
useParallel = 0;
kernel = {'sexp','matern52','trajectory'};

verbose = 1;

% platform = 'pygym';
platform = 'matlab';

% env = 'mountainCarContinuous';
% env = 'acroBot';
% env = 'mountainCar';
env = 'cartPole';


addpath('pygym');
addpath('auxiliary');
addpath('cartPole');
 
hrs = datestr(now,'dd-mm-yyyy_HH-MM');
dirStr = sprintf('results/%s_%s_%s_%s', optimizerType, env, platform, hrs);

%for ed = 10.^[0:-1:-5]

for kernelIdx = 3:3
    seedInit = setRandom(32145);
    func = problemOptions(kernel{kernelIdx},platform,env, optimizerType);
    optimizerInput.fun = func;
    mu = zeros(1,func.opts.dim);
    covC = eye(func.opts.dim) * optimizerInput.initVar;
    optimizerInput.initDistrib = static_optimization_algs.Normal(mu, covC);
    
    func.opts.verbose = verbose;
    
    func.opts.optimizerType = optimizerType;
    func.opts.cores = cores;
    func.opts.trajectoriesPerSample = 1;
    func.opts.hyperOptimize = 1;
    func.opts.hyperPlot = 1;
    func.opts.acquisitionPlot = 0;
    func.opts.noiseVariance = 1e-6;
    
    % global opt
    func.opts.ub = 1.*ones(1,func.opts.dim);
    func.opts.lb = -1.*func.opts.ub;
    func.opts.bayOptSteps = 200;
    func.opts.initialSamplesCount = 10;
    func.opts.useMaxMean = 0;
    func.opts.useGADSToolbox = 1;
        

    if kernelIdx == 3 && strcmp(optimizerType,'local')

        ub = 1.*ones(1,func.opts.dim);
        lb = -1.*ub;
        samplesCount = 10;
        bsf = 0;
        for i = 1:samplesCount
            X = randBound(lb, ub, samplesCount);
            if minDist(X,lb,ub) > bsf
                bsf = minDist(X,lb,ub);
                samples = X;
            end
        end
        for i=1:samplesCount
            for j = 1:func.opts.trajectoriesPerSample
                [~, trajectories(i,j)] = func.eval(samples(i,:));
            end
        end

        D1 = func.opts.distanceMat(randBound(lb,ub,10000), samples, trajectories, false, func.opts);
        D2 = func.opts.distanceMat(samples, samples, trajectories, false, func.opts);
        randSamples = randBound(lb,ub,316);
        D3 = func.opts.distanceMat(randSamples, randSamples, trajectories, true, func.opts);
    %     ttt = [max(D1(:)), max(D2(:)),max(D3(:))];

        D1(isinf(D1)) = 0;
%         sigmal = max(D3(:))./mean([max(D1(:)), max(D2(:))]);
        sigmal = max(D3(:))./mean(max(D1(:)));
        func.opts.hyper = [0, log(sigmal)];
%         func.opts.hyper = [0,0];

        figure;
        subplot(2,3,1);        
        histogram(D1);
        subplot(2,3,4);
        histogram(func.opts.scaleKernel(D1,[0 0]));
        subplot(2,3,2);
        histogram(D2);
        subplot(2,3,5);
        histogram(func.opts.scaleKernel(D2,[0 0]));
        subplot(2,3,3);
        histogram(D3/sigmal);
        subplot(2,3,6);
        histogram(func.opts.scaleKernel(D3,func.opts.hyper));
%         histogram(func.opts.scaleKernel(D3,[0 0]));
        
    else
        func.opts.hyper = [0,0];
    end
    
    trial = 1;
    while trial <= trials
        func.opts.useParallel = useParallel;
        if useParallel
            try 
                if ~exist('pp','var')
                    pp = parpool(func.opts.cores);
                end
            catch me
                if strcmp(me.identifier,'parallel:cluster:LicenseUnavailable')
                    func.opts.useParallel = 0;
                else
                    hrs = datestr(now,'_dd-mm-yyyy_HH-MM');
                    save(['results/error',hrs,'.mat'],'me');
                    disp(getReport(me));
                    exit;
                end
            end
        end
        
        if func.opts.useParallel
            parfor t = trial:trials
                optiHelp(func,optimizerInput,t,seedInit,dirStr,kernel{kernelIdx});
            end
            trial = trials + 1;
        else
            optiHelp(func,optimizerInput,trial,seedInit,dirStr,kernel{kernelIdx});
            trial = trial + 1;
        end
    end  
   
%     hrs = datestr(now,'dd-mm-yyyy_HH-MM');
%     saveStr = sprintf('results/%s_%s_%s_%s_%0.0e_%s.mat', 'local_thompson_full_300', env, platform, kernel{kernelIdx}, func.opts.noiseVariance, hrs);
%     save(saveStr,'ret');
end

end

function optiHelp(func,optimizerInput,trial,seedInit,dirStr,kernelStr)
    ret = [];
    seedStartOpt = setRandom(32145);
    tic;
    if strcmp(func.opts.optimizerType, 'local')
        ret.knownY = static_optimization_algs.DensityWeightedBO_trajectory.optimizeStruct(optimizerInput, func);
    else
        ret.knownY = static_optimization_algs.globalBO.optimze(func, trial);
    end
    ret.timeTakenSeconds = toc;
    ret.hyper = func.opts.hyper;
    ret.noiseVariance = func.opts.noiseVariance;
    ret.seedStartOpt = seedStartOpt;
    ret.seedInit = seedInit;
    if ~exist(dirStr,'dir')
        mkdir(dirStr);
    end
    saveStr = sprintf('%s/%s_%02d.mat', dirStr, kernelStr, trial);
    save(saveStr,'ret');
    disp(trial);
end

function seedStartOpt = setRandom(seedStartOpt)
    if nargin == 0
        seed = rng('shuffle');
        seedStartOpt = seed.State(2);
    end
    rng(seedStartOpt);
end

%% performance plotting
% fname = [rootPlot 'perfOn_' funSignature '_' all_signatures{1}];
% hnd = figure(5);
% hold on;
% for k = 1:length(optimizers)
%     plot(all_perfs{k});
%     perfs = all_perfs{k};
% end
% legHnd = legend(all_signatures{:}, 'Location','southeast');
% set(legHnd, 'interpreter', 'none');
% set(legHnd, 'FontSize', 7);
% hgexport(hnd, [fname '.eps']);

%% kl plotting
% fname = [rootPlot 'klOn_' funSignature '_' all_signatures{1}];
% hnd = figure(6);
% for k = 1:length(optimizers)
%     semilogy(all_perfs{k}(:, 1), all_kls{k});
%     hold on;
% end
% hold off;
% legHnd = legend(all_signatures{:}, 'Location','southeast');
% set(legHnd, 'interpreter', 'none');
% set(legHnd, 'FontSize', 7);
% hgexport(hnd, [fname '.eps']); 

