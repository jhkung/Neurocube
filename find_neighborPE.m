function [neighbor_pe_idx] = find_neighborPE( searchID )
% finds PE index which stores neighboring cell state

global NETWORK;     global SRAM;

for iRow = 1:NETWORK.num_rows
    for iCol = 1:NETWORK.num_cols
        
        pe_idx  = (iRow-1)*NETWORK.num_cols + iCol;
        
        searchResult  = find(SRAM(pe_idx).packet(:,4) == searchID);
        
        if (~isempty(searchResult))
            neighbor_pe_idx = pe_idx;
        end
        
    end
end

end

