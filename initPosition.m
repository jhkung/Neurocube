function [ outPosition ] = initPosition( )
% initialize initial position for PE compuation position in each partial image

global NETWORK;

outPosition = cell(NETWORK.num_rows, NETWORK.num_cols);

for i = 1:NETWORK.num_rows
    for j = 1:NETWORK.num_cols
        outPosition{i,j} = [1, 1];
    end   
end

end

