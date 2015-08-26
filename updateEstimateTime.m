function [currPosition] = updateEstimateTime(prevPosition)
% update compute_flag & est_time & mac_idx

global PE;
global NETWORK;
global sim_t;   global p_imgSize;

nNodes  = NETWORK.num_rows * NETWORK.num_cols;


for iRow = 1:NETWORK.num_rows
    for iCol = 1:NETWORK.num_cols
        
        idx   = (iRow-1)*NETWORK.num_cols + iCol;
        
        curr_mac    = PE(idx).mac_idx;
        if (PE(idx).MAC(curr_mac).operand_cnt == 3 && PE(idx).MAC(curr_mac).est_time == 0)
            
            PE(idx).MAC(curr_mac).compute_flag  = 1;
            PE(idx).MAC(curr_mac).est_time      = sim_t + PE(idx).t_compute;
            
            PE(idx).mac_idx = PE(idx).mac_idx + 1;
            if (PE(idx).mac_idx > PE(idx).num_MAC)
                PE(idx).mac_idx = 1;
            end
            
            % update position
            currPosition{iRow,iCol} = [prevPosition{iRow,iCol}(1), prevPosition{iRow,iCol}(2)+1];
            
            if (currPosition{iRow,iCol}(2) > p_imgSize)
                currPosition{iRow,iCol}(1) = currPosition{iRow,iCol}(1) + 1;      % increase row index
                currPosition{iRow,iCol}(2) = 1;
            end
            
            if (currPosition{iRow,iCol}(1) > p_imgSize)
                currPosition{iRow,iCol}(1) = 1;
            end
        else
            currPosition{iRow,iCol} = prevPosition{iRow,iCol};
        end
        
    end
end


end

