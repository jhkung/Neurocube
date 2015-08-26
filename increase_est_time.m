function [ ] = increase_est_time( )
% increase 'est_time' by 1 if MAC is stalled

global PE;
global NETWORK;

nNodes  = NETWORK.num_rows*NETWORK.num_cols;

for idx = 1:nNodes
    for curr_mac = 1:PE(idx).num_MAC
        temp_est_t  = PE(idx).MAC(curr_mac).est_time;
        
        if (temp_est_t ~= 0)
            PE(idx).MAC(curr_mac).est_time = PE(idx).MAC(curr_mac).est_time + 1;
        end
    end
end


end

