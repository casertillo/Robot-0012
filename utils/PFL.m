function [ pose isPFLdone ] = PFL( num, botScan, particles, isPFLdone )
%% create spaces to store information for the purpose of resampling
newPos = zeros(num, 2);
newAng = zeros(num, 1);

%% Parameters setting
sigma = 5;
dampling = 0.01;

%% Updating weights
weights = ones(num, 1) * (1 / num); % initialize weights

for i = 1:num
    pScan = particles(i).ultraScan(); % get scan for each particle
    %delta = sum( (pScan - botScan).^2 );
    delta = sum( abs(pScan - botScan) );
    weights(i) = exp( - delta / (2 * sigma.^2) ) + dampling;
end

% normalize weights
weights = weights / sum(weights);

%% Resampling
count = 0;
totalNum = 0;
for i = 1:num
    % get max weight and the corresponding index of particle
    [w, index] = max(weights);
    
    % set current max weight to 0 for convenience of finding next max
    weights(index) = 0;
    
    % define number of particles that is going to be re-sampled
    offspringNum = round(w * num);
    
    % to avoid total number of particles exceeds pre-defined size
    if (totalNum + offspringNum) > num
        offspringNum = num - totalNum;
    end
    
    % copy particles
    for j = 1:offspringNum
        count = count + 1; % update count
        newPos(count, :) = particles(index).getBotPos();
        newAng(count) = particles(index).getBotAng();
        
        % motion model: for spreading out particles
        transstd = 2;
        orientstd = 1;
        e = 0 + transstd * randn(1, 2);
        f = 0 + orientstd * randn(1,1) * (pi/180);
        newPos(count, :) = newPos(count, :) + e;
        newAng(count) = newAng(count) + f;
        
    end
    
    % update total number of new-born particles
    totalNum = totalNum + offspringNum;
    if totalNum == num
        break
    end
    
end

%% update current particles
for i = 1:num
    particles(i).setBotPos( newPos(i, :) );
    particles(i).setBotAng( newAng(i) );
end

%% Write code to check for convergence
if isPFLdone == 0
    covmat = cov(newPos);
    eigval = eig(covmat);
    sumeig = sum(eigval); % threshold: 30(num=500)
end

%% return
position = mean(newPos);
angle = mean(newAng);
pose = [position, angle];
if isPFLdone == 0 && sumeig < 30
    isPFLdone = 1;
end

end
