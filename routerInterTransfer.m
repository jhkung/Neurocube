function [ ] = routerInterTransfer( )
% Packet transfer btw ROUTER nodes
% TODO(1): consider 'M_OUT' data transfer as well

global NETWORK;     global ROUTER;      global SRAM;
global PE;
global sim_t;       global stallMAC;

nRows       = NETWORK.num_rows;
nCols       = NETWORK.num_cols;
nROUTER     = nRows * nCols;
nIN_buf     = 6;           % 'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN'
nOUT_buf    = 6;           % 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'


% parfor (r_idx = 1:nROUTER, 4)
for r_idx = 1:nROUTER
    for b_idx = (nIN_buf+1):1:(nIN_buf+nOUT_buf)
        
        if (ROUTER(r_idx,b_idx).buf_ptr ~= 0)
            if (b_idx == 7)     % 'C_OUT': move packet to SRAM cache
                
%                 if ( (SRAM(r_idx).ptr < SRAM(r_idx).capacity) && (sim_t >= ROUTER(r_idx,b_idx).packet(1,6)+ROUTER(r_idx).latency) )
                if ( (SRAM(r_idx).ptr < (SRAM(r_idx).capacity + SRAM(r_idx).boundCap)) && (sim_t >= ROUTER(r_idx,b_idx).packet(1,6)+ROUTER(r_idx).latency) )
                    SRAM(r_idx).ptr = SRAM(r_idx).ptr + 1;
                    SRAM(r_idx).packet(SRAM(r_idx).ptr,:) = ROUTER(r_idx,b_idx).packet(1,:);    % move packet
                    
                    msg = sprintf('[sim_t @ %d] Packet{%d}(%d->%d) moved from [%s] to [%s] in ROUTER(%d)...\n', ...
                        sim_t, ROUTER(r_idx,b_idx).packet(1,4), ROUTER(r_idx,b_idx).packet(1,1), ROUTER(r_idx,b_idx).packet(1,2), NETWORK.buffer_arr{b_idx}, 'SRAM', r_idx);
                    disp(msg);
                    
                    SRAM(r_idx).packet(SRAM(r_idx).ptr,6) = sim_t;      % update arrival time
                    update_buffer(r_idx, b_idx);    % update input buffer struct
                end
                
                % exception handler for packet from neighboring SRAM to MAC
                % directly (do not harm SRAM capacity since it goes to MAC register)
                if (ROUTER(r_idx,b_idx).packet(1,5) == 4)
                    mac_idx = PE(r_idx).mac_idx;
                    PE(r_idx).MAC(mac_idx).packet(2,:)  = ROUTER(r_idx,b_idx).packet(1,:);
                    
                    msg = sprintf('[sim_t @ %d] Packet{%d}(%d->%d) moved from [%s] to [%s] in ROUTER(%d)...\n', ...
                        sim_t, ROUTER(r_idx,b_idx).packet(1,4), ROUTER(r_idx,b_idx).packet(1,1), ROUTER(r_idx,b_idx).packet(1,2), NETWORK.buffer_arr{b_idx}, 'PE', r_idx);
                    disp(msg);
                    
                    PE(r_idx).MAC(mac_idx).packet(2,6)  = sim_t;
                    update_buffer(r_idx, b_idx);    % update input buffer struct
                    
                    PE(r_idx).MAC(mac_idx).operand_cnt  = PE(r_idx).MAC(mac_idx).operand_cnt + 1;
                    
                    iRow  = floor((r_idx-1)/NETWORK.num_cols) + 1;
                    iCol  = mod(r_idx-1, NETWORK.num_cols) + 1;
                    stallMAC(iRow,iCol)    = 0;
                end
                      
            elseif (b_idx == 8) % 'M_OUT': move packet to DRAM
                warning('TODO: not implemented yet!! make DKim work!!');
            else               
                switch b_idx
                    case 9  % 'N_OUT'
                        dst_idx = 6;
                        dst_r_idx = r_idx - nCols;                        
                    case 10 % 'E_OUT'
                        dst_idx = 5;
                        dst_r_idx = r_idx + 1;                        
                    case 11 % 'W_OUT'
                        dst_idx = 4;
                        dst_r_idx = r_idx - 1; 
                    case 12 % 'S_OUT'
                        dst_idx = 3;
                        dst_r_idx = r_idx + nCols; 
                end
                
                if ( (~ROUTER(dst_r_idx,dst_idx).full) && (sim_t >= ROUTER(r_idx,b_idx).packet(1,6)+ROUTER(r_idx).latency) )
                    ROUTER(dst_r_idx,dst_idx).buf_ptr = ROUTER(dst_r_idx,dst_idx).buf_ptr + 1;
                    ROUTER(dst_r_idx,dst_idx).packet(ROUTER(dst_r_idx,dst_idx).buf_ptr,:) = ROUTER(r_idx,b_idx).packet(1,:);
                    
                    msg = sprintf('[sim_t @ %d] Packet{%d}(%d->%d) moved from [%s(R%d)] to [%s(R%d)]...\n', ...
                        sim_t, ROUTER(r_idx,b_idx).packet(1,4), ROUTER(r_idx,b_idx).packet(1,1), ROUTER(r_idx,b_idx).packet(1,2), NETWORK.buffer_arr{b_idx}, r_idx, NETWORK.buffer_arr{dst_idx}, dst_r_idx);
                    disp(msg);
                    
                    ROUTER(dst_r_idx,dst_idx).packet(ROUTER(dst_r_idx,dst_idx).buf_ptr,6) = sim_t;
                    update_buffer(r_idx, b_idx);
                end
            end
                        
        end
        
    end        
end
   


end

