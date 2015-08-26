function [ ] = shrinkSRAMcap( )
% remove SRAM contents before DRAM fetching

global SRAM;
global CNN;     global NETWORK;

n_kernel    = CNN.tempWidth*CNN.tempHeight;
nNodes      = NETWORK.num_rows*NETWORK.num_cols;

% update SRAM pointer 'ptr'
for idx = 1:nNodes
    SRAM(idx).ptr = n_kernel;
    SRAM(idx).packet = SRAM(idx).packet(1:SRAM(idx).capacity,:);
    SRAM(idx).boundCap = 0;
end

end

