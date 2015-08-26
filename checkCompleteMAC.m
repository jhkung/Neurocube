function [ flag ] = checkCompleteMAC()
% returns flag indicating whether MAC operation is completed or not

global NETWORK;     global CNN;
global PE;


nNodes      = NETWORK.num_rows * NETWORK.num_cols;
cnt_done    = 0;    flag    = 0;

for idx = 1:nNodes
    for curr_mac = 1:PE(idx).num_MAC
        if (PE(idx).MAC(curr_mac).conv_cnt == CNN.tempWidth*CNN.tempHeight)
            cnt_done = cnt_done + 1;
        end
    end
end

if (cnt_done == nNodes*PE(1).num_MAC)
    flag = 1;
end

end

