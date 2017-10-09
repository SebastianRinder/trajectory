function D = trajectoryDistance(xi, xj, traji, trajj, customKernel)    
    
    if isempty(traji) && isempty(trajj)
        execPolicyFcn = customKernel.simOpts.execPolicyFcn;
        simOpts = customKernel.simOpts;
        trajectoriesPerPolicy = customKernel.trajectoriesPerPolicy; 
        
        for n = trajectoriesPerPolicy:-1:1
            [~, traji{1,n}] = execPolicyFcn(xi, simOpts);
        end
        
        for n = trajectoriesPerPolicy:-1:1
            [~, trajj{1,n}] = execPolicyFcn(xj, simOpts);
        end
        D = monteCarloEst(xi, xj, traji, trajj, customKernel);
        if D ~= 0
            keyboard;
        end
    elseif isempty(traji) && ~isempty(trajj)
        D = importanceSampling(xi, xj, trajj, customKernel);
        
    elseif ~isempty(traji) && isempty(trajj)
        D = importanceSampling(xi, xj, traji, customKernel); 
        
    elseif ~isempty(traji) && ~isempty(trajj)
        D = monteCarloEst(xi, xj, traji, trajj, customKernel);
        
    end
end

function D = importanceSampling(xi, xj, knownTrajectory, customKernel)
    trajectoriesPerPolicy = customKernel.trajectoriesPerPolicy;
    actionSelectionFcn = customKernel.actionSelectionFcn;
    
    Dtemp1 = 1;
    Dtemp2 = 0;
    Dtemp3 = 0;
    D = 0;

    for k = 1:trajectoriesPerPolicy
        traj = knownTrajectory{1,k};

        for t=1:size(traj,1)
            state = traj{t,1}.state;
            action = traj{t,1}.action;
            [~,quadNew] = actionSelectionFcn(xi, state, action);
            [~,quadj] = actionSelectionFcn(xj, state, action);
            Dtemp1 = Dtemp1 * exp(quadNew - quadj);
            Dtemp2 = Dtemp2 + quadNew - quadj;
            Dtemp3 = Dtemp3 + quadj - quadNew;
        end

        D = D + (Dtemp1 * Dtemp2 + Dtemp3) ./ size(traj,1);
    end

    D = D / trajectoriesPerPolicy;
end

function D = monteCarloEst(xi, xj, traji, trajj, customKernel)
    trajectoriesPerPolicy = customKernel.trajectoriesPerPolicy;
    actionSelectionFcn = customKernel.actionSelectionFcn;
    
    Dtemp = 0;
    D1 = 0;

    for k = 1:trajectoriesPerPolicy
        traj = traji{1,k};

        for t=1:size(traj,1)
            state = traj{t,1}.state;
            action = traj{t,1}.action;
            [~,quadi] = actionSelectionFcn(xi, state, action);
            [~,quadj] = actionSelectionFcn(xj, state, action);
            Dtemp = Dtemp + quadi - quadj;
        end
        
        D1 = D1 + Dtemp ./ size(traj,1);
    end
    
    Dtemp = 0;
    D2 = 0;

    for k = 1:trajectoriesPerPolicy
        traj = trajj{1,k};

        for t=1:size(traj,1)
            state = traj{t,1}.state;
            action = traj{t,1}.action;
            [~,quadi] = actionSelectionFcn(xi, state, action);
            [~,quadj] = actionSelectionFcn(xj, state, action);
            Dtemp = Dtemp + quadj - quadi;
        end
        
        D2 = D2 + Dtemp ./ size(traj,1);
    end

    D = (D1 + D2) / trajectoriesPerPolicy;
end
