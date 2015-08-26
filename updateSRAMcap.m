function [ ] = updateSRAMcap( neighborList )
% Update boundCap of SRAM construct

global SRAM;    global NETWORK;

nNodes  = NETWORK.num_rows * NETWORK.num_cols;

for i = 1:nNodes
    SRAM(i).boundCap = length(find(neighborList(:,2) == i));
end

end

