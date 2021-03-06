function [X,G,acc] = samplerLipMHSGLD(funh,N,x0,tauk,nthin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MH-SGLD with adaptive Lipschitz step-length
%   
%   Reference: Izzatullah et al. (2020) Langevin dynamics MCMC solutions
%              for seismic inversion
%              Nemeth and Fearnhead (2019) Stochastic gradient MCMC
%
%     
%   Implemented by  : Muhammad Izzatullah, KAUST
%   Version         : May 8, 2020
%
%   Input:
%   N         - Number of samples
%   x0        - Initial point, vector of dimension-by-one
%   tauk      - Set of initial step-length
%   nthin     - Number of thinning window
%
%   Output:
%   X         - Samples matrix, dimension-by-number of samples
%   G         - Samples gradient matrix, dimension-by-number of samples
%   acc       - Set of acceptance rate
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Checking the input arguments
if nargin < 5
    nthin = 0;
end
% Size of random vector
[xi, xi2] = size(x0);        
% If x0 is a row vector, turn it to column vector
if xi2 > xi
    x0 = x0';
end

%% Initialisation
Ntau = length(tauk);     % Number of element of tauk
X = zeros(xi,N,Ntau);    % Samples
G = zeros(xi,N,Ntau);    % Gradients of log-normal distribution
acc = zeros(Ntau,1);     % Collections of acceptance rate

for s = 1:Ntau        
        
    k               = 1;           % Step
    xk              = x0;          % Initial step
    tau             = tauk(s);     % Step-length
    accept          = 0;           % Acceptance
    theta           = Inf;         % Lipschitz-tau coefficient
    
    tic;
    while k<=N

        disp(['Step: ', num2str(k)]);

        [fk,gk] = funh(xk);
        
        % MH-SGLD
        xk1     = xk - 0.5*tau*gk + sqrt(0.01)*tau*randn(xi,1) +...
            sqrt(tau)*randn(xi,1);

        [fk1,gk1]   = funh(xk1);

        if isnan(fk1) || isinf(fk1)
            X(:,k,s)  = 0;
            break;
        end
        
        pk1         = exp(-fk1); 
        pk          = exp(-fk);

        xqk1        = xk1 - 0.5*tau*gk1;
        xqk         = xk - 0.5*tau*gk;

        qk1         = exp(-(0.5/tau)*norm(xk1 - xqk)^2); 
        qk          = exp(-(0.5/tau)*norm(xk - xqk1)^2);

        alpha       = min(1, ( pk1*qk )/( pk*qk1 ));

        % Metropolis-Hastings acceptance step
        if rand < alpha
            X(:,k,s)  = xk1;
            G(:,k,s)  = -gk1;
            
            % Compute Lipschitz-tau
            t1    = 0.5*norm(xk1 - xk)/norm(gk1 - gk);
            t2    = sqrt(1 + theta)*tau;

            tk    = min(t1,t2);

            theta = tk/tau;
            tau   = tk;

            xk      = xk1;

            k       = k + 1;
            accept  = accept + 1;
        else
            X(:,k,s)  = xk;
            G(:,k,s)  = -gk;
            k       = k + 1;
        end
 
    end
    toc;
    
    % Calculate acceptance rate
    accept = accept/N;
    acc(s) = accept*100;
    disp(['Acceptance rate: ', num2str(accept)]);
    
end

if nthin ~= 0
    X = X(:,1:nthin:end,:);
    G = G(:,1:nthin:end,:);
end

end