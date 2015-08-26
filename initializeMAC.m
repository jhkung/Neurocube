function [ ] = initializeMAC( )
% sim_t > est_time, then set compute_flag as 0 & operand_cnt as 0 & set packets to zeros(1,6) & est_time to 0
            
global sim_t;
global PE;      global NETWORK;
global CNN;     global stallMAC;

nNodes  = NETWORK.num_rows * NETWORK.num_cols;

for idx = 1:nNodes
    for curr_mac = 1:PE(idx).num_MAC
        
        iRow  = floor((idx-1)/NETWORK.num_cols) + 1;
        iCol  = mod(idx-1, NETWORK.num_cols) + 1;
        
        if ( (PE(idx).MAC(curr_mac).est_time ~= 0) && (PE(idx).MAC(curr_mac).est_time < sim_t) )
            PE(idx).MAC(curr_mac).compute_flag  = 0;
            PE(idx).MAC(curr_mac).operand_cnt   = 0;
            PE(idx).MAC(curr_mac).packet        = zeros(3,6);
            PE(idx).MAC(curr_mac).est_time      = 0;
            
            PE(idx).MAC(curr_mac).conv_cnt      = PE(idx).MAC(curr_mac).conv_cnt + 1;

        end
    end
            
    if (PE(idx).MAC(curr_mac).conv_cnt == CNN.tempWidth*CNN.tempHeight)
        stallMAC(iRow,iCol) = 1;
    end
end


end

