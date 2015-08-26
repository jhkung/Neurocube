function [ ] = updateDRAM_gen_t( )
% Update packet generation time for DRAM when readDRAM is idle (increment gne_t by 1)

global DRAM;    global DRAM_router_node;
[M, N]      = size(DRAM_router_node);

if (~isempty(DRAM(1).packet))
    for iRow = 1:M
        for iCol = 1:N
            
            DRAM_idx    = (iRow-1)*N + iCol;
            DRAM(DRAM_idx).packet(:,3)   = DRAM(DRAM_idx).packet(:,3) + 1;
            
        end
    end
end

end

