classdef RepsTrueGaussian
    methods (Static)
        function sign = getSignature(optimizerInput)
            sign = ['NonParamRepsGauss' '_' num2str(optimizerInput.epsiKL) '_' num2str(optimizerInput.nbIter) '_' ...
                num2str(optimizerInput.nbSamplesPerIter) '_' num2str(optimizerInput.maxIterReuse) '_' ...
                num2str(optimizerInput.initVar)];
        end
        
        function [perf] = optimizeStruct(optimizerInput)
            perf = static_optimization_algs.RepsTrueGaussian.optimize(optimizerInput.initDistrib, optimizerInput.epsiKL,...
                optimizerInput.nbIter, optimizerInput.nbSamplesPerIter, optimizerInput.maxIterReuse,...
                optimizerInput.fun, optimizerInput.videoFile);
        end
        
        function [perf] = optimize(initDistrib, epsiKL, nbIter, nbSamplesPerIter, maxIterReuse, fun, videoFile)
            perf = zeros(nbIter, 2);
            sum1OverEta = 0;
            lastPolicies{1} = initDistrib;
            samples = [];
            vals = [];
            nbSamplesEval = 100;
            
            %% animation
            open(videoFile);
            
            for iter = 1:nbIter
                %% generating new samples
                newSamples = lastPolicies{end}.getSamples(nbSamplesPerIter);
                nsInitProbas = exp(initDistrib.getLogProbas(newSamples));
                nsVals = fun.eval(newSamples);
                samples = [samples; newSamples];
                vals = [vals; nsVals];
                diffVals = vals - max(vals);
                
                %% computing importance weights
                mixtureProba = zeros(size(vals));
                for k = 1:length(lastPolicies)
                    mixtureProba = mixtureProba + exp(lastPolicies{k}.getLogProbas(samples));
                end
                sampleWeights = exp(diffVals * sum1OverEta);
                sampleWeights(isnan(sampleWeights)) = 1; % resulting from exp(0 * inf)
                sampleWeights = sampleWeights ./ mixtureProba .* exp(initDistrib.getLogProbas(samples));
                sampleWeights = sampleWeights / sum(sampleWeights);
                
                %% evaluation
                newPerf = mean(fun.eval(lastPolicies{end}.getSamples(nbSamplesEval)));
                perf(iter, :) = [((iter-1) * nbSamplesPerIter) newPerf];
                
                %% current distrib plotting
                frame = static_optimization_algs.RepsTrueGaussian.getFrame(fun, lastPolicies{end}, samples, nbSamplesPerIter);
                writeVideo(videoFile, frame);
                
                %% update
                eta = static_optimization_algs.RepsBandits.optimizeDual(vals, epsiKL, sampleWeights);
                sum1OverEta = sum1OverEta + 1/eta;
                newPolicy = initDistrib.wmle(samples, sampleWeights);
                lastPolicies{end+1} = newPolicy;
                if(length(lastPolicies) > maxIterReuse)
                    lastPolicies = lastPolicies(2:end);
                    samples = samples(nbSamplesPerIter+1:end, :);
                    vals = vals(nbSamplesPerIter+1:end, :);
                end
            end
            close(videoFile);
        end
        
        function frame = getFrame(fun, policy, samples, nbSamplesPerIter)
            persistent currPlot;
            if(isempty(currPlot))
                 currPlot = figure;
            end
            hold off;
            fun.plot();
            hold on;
            policy.plot();
            plot(samples((size(samples, 1) + 1 - nbSamplesPerIter):end, 1),...
                samples((size(samples, 1) + 1 - nbSamplesPerIter):end, 2), '*r');
            %             markerSize = 1;
            %             finalMarkerSize = 15;
            %             increaseMarkerSize = (finalMarkerSize - markerSize) / (size(samples, 1) / nbSamplesPerIter - 1);
            %             for k = 1:nbSamplesPerIter:(size(samples, 1) + 1 - nbSamplesPerIter)
            %                 plot(samples(k:(k + nbSamplesPerIter - 1), 1), ...
            %                     samples(k:(k + nbSamplesPerIter - 1), 2), '.r', ...
            %                     'MarkerSize', floor(markerSize));
            %                 markerSize = markerSize + increaseMarkerSize;
            %             end
            frame = getframe(gcf,[0 0 560 420]);
        end
        
    end
end
