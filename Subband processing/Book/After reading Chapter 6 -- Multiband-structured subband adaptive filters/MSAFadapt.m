function [en,S] = MSAFadapt(un,dn,S)

% MSAFadapt         Multiband-structured Subband Adaptive Filter (MSAF)
%
% Arguments:
% un                Input signal
% dn                Desired signal
% S                 Adptive filter parameters as defined in MSAFinit.m
% en                History of error signal

M = length(S.coeffs);
[L,N] = size(S.analysis);
mu = S.step;
alpha = S.alpha;
AdaptStart = S.AdaptStart;
H = S.analysis;
F = S.synthesis;
w = S.coeffs; U = zeros(M,N);                      % Adaptive filtering
a = zeros(L,1); d = zeros(L,1); A = zeros(L,N);    % Analysis filtering
z = zeros(L,1);                                    % Synthesis filtering

ITER = length(un);
en = zeros(1,ITER);

if isfield(S,'unknownsys')
    b = S.unknownsys;
    norm_b = norm(b);
    eml = zeros(1,ITER);
    ComputeEML = 1;
    u = zeros(M,1);
else
    ComputeEML = 0;
end
	
for n = 1:ITER
    
    d = [dn(n); d(1:end-1)];                       % Update tapped-delay line of d(n)
    a = [un(n); a(1:end-1)];                       % Update tapped-delay line of u(n)
    A = [a, A(:,1:end-1)];                         % Update buffer
    if ComputeEML == 1;
        eml(n) = norm(b-w)/norm_b;                 % System error norm (normalized)
        u = [un(n); u(1:end-1)];
        UDerr(n) = (b-w)'*u;                       % Undisturbed error 
    end
    
    if (mod(n,N)==0)                               % Tap-weight adaptation at decimated rate
        U1 = (H'*A)';                              % Partitioning u(n) 
        U2 = U(1:end-N,:);
        U = [U1', U2']';                           % Subband data matrix
        dD = H'*d;                                 % Partitioning d(n) 
        eD = dD - U'*w;                            % Error estimation
        if n >= AdaptStart
            w = w + U*(eD./(sum(U.*U)+alpha)')*mu; % Tap-weight adaptation
            S.iter = S.iter + 1;
        end
        z = F*eD + z;                                       
        en(n-N+1:n) = z(1:N); 
        z = [z(N+1:end); zeros(N,1)];
    end
                          
end

S.coeffs = w;
if ComputeEML == 1;
    S.eml = eml;
    S.UDerr = UDerr;
end


    
