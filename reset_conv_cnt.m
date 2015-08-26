function [ ] = reset_conv_cnt( )
% reset convolution counter to zeros

global PE;      global NETWORK;

nNodes  = NETWORK.num_rows * NETWORK.num_cols;

for idx = 1:nNodes
    for curr_mac = 1:PE(idx).num_MAC
        PE(idx).MAC(curr_mac).conv_cnt  = 0;
    end
end

