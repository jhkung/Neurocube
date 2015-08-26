function [currPosition] = prepareData(prevPosition)
% Data preparation for operation of PE (MACs)

global p_imgSize;
global PE;      global NETWORK;

nNodes  = NETWORK.num_rows*NETWORK.num_cols;
currPosition   = prevPosition;

for iRow = 1:NETWORK.num_rows
    for iCol = 1:NETWORK.num_cols
        
        n_idx   = (iRow-1)*NETWORK.num_cols + iCol;
        
        if (PE(n_idx).mac_idx)
            currPosition{iRow,iCol} = [prevPosition{iRow,iCol}(1), prevPosition{iRow,iCol}(2)+1];
            
            if (currPosition{iRow,iCol}(2) > p_imgSize)
                currPosition{iRow,iCol}(1) = currPosition{iRow,iCol}(1) + 1;      % increase row index
                currPosition{iRow,iCol}(2) = 1;
            end
            
            if (currPosition{iRow,iCol}(1) > p_imgSize)
                currPosition{iRow,iCol}(1) = 1;
            end
        end
        
    end
end
    
    
end

