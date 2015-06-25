function [ ] = routerPacketTransfer( )
% Packet transfer in each ROUTER node
% TODO: consider 'C_IN' data transfer as well

global NETWORK;     global ROUTER;      global sim_t;

nRows       = NETWORK.num_rows;
nCols       = NETWORK.num_cols;
nROUTER     = nRows * nCols;
nIN_buf     = 6;            % 'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN'
% nOUT_buf = 6;           % 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'

% parfor (r_idx = 1:nROUTER, 4)
for r_idx = 1:nROUTER

    % decide which packet to transfer to output buffer
    packet_list   = [];     buf_idx_list  = [];    
    buf_cnt       = 0;      dst_idx       = 0;
    
    for b_idx = 1:nIN_buf
        if (ROUTER(r_idx,b_idx).buf_ptr ~= 0)
            buf_cnt         = buf_cnt + 1;
            buf_idx_list    = [buf_idx_list, b_idx];
            packet_list     = [packet_list; ROUTER(r_idx,b_idx).packet(1,:)];       % list of packets on top list of each input buffers
        end
    end
    
    if (buf_cnt ~= 0)       % transfer packet if there is any packet stored in input buffers
        [~,I]       = min(packet_list(:,4)');
        packet_dst  = packet_list(I,2);
        packet_buf  = buf_idx_list(I);      % buffer index for a package to be transferred
        src_buf     = NETWORK.buffer_arr{packet_buf};
        
        % switch the path from selected buffer to proper output buffer
        if (packet_dst == r_idx)
            dst_idx = 7;      dst_buf = NETWORK.buffer_arr{dst_idx};        % 'C_OUT'
        else
            for idxLUT = 1:length(ROUTER(r_idx).directionLUT)
                find_result = find(ROUTER(r_idx).directionLUT{idxLUT} == packet_dst);
                
                if ~isempty(find_result)
                    % dir_idx (1: X+, 2: X-, 3: Y+, 4: Y-)
                    dir_idx = idxLUT;
                    
                    switch dir_idx
                        case 1
                            dst_idx     = 10;
                        case 2
                            dst_idx     = 11;
                        case 3
                            dst_idx     = 12;
                        case 4
                            dst_idx     = 9;
                        otherwise
                            warning('\nDestination direction not found!')
                    end
                end
            end
            
            
            dst_buf = NETWORK.buffer_arr{dst_idx};                     
        end
        
        
        
        % move packet to output buffer at 'arr_time + router latency (internal transfer latency)'
        new_arr_time   = packet_list(I,6) + ROUTER(r_idx).latency;
        if (sim_t >= new_arr_time)      
            if (~ROUTER(r_idx,dst_idx).full)    % if dst output buffer is not full (move a packet)
                
                % update buf_ptr
                ROUTER(r_idx,dst_idx).buf_ptr = ROUTER(r_idx,dst_idx).buf_ptr + 1;
                
                % move packet from input buffer to output buffer
                ROUTER(r_idx,dst_idx).packet(ROUTER(r_idx,dst_idx).buf_ptr,:)   = ROUTER(r_idx,packet_buf).packet(1,:);
                ROUTER(r_idx,dst_idx).packet(ROUTER(r_idx,dst_idx).buf_ptr,6)   = sim_t;
                
                if (ROUTER(r_idx,dst_idx).buf_ptr == NETWORK.buffer_size)
                    ROUTER(r_idx,dst_idx).full  = 1;
                end
                
                % update input buffer and its pointer
                ROUTER(r_idx,packet_buf).packet         = [ROUTER(r_idx,packet_buf).packet(2:end,:); zeros(1,size(ROUTER(r_idx,packet_buf).packet, 2))];
                ROUTER(r_idx,packet_buf).buf_ptr        = ROUTER(r_idx,packet_buf).buf_ptr - 1;                
                if (ROUTER(r_idx,packet_buf).full == 1)
                    ROUTER(r_idx,packet_buf).full   = 0;
                end
                                
                msg = sprintf('[sim_t @ %d] Packet{%d}(%d->%d) moved from [%s] to [%s] in ROUTER(%d)...\n', sim_t, packet_list(I,4), packet_list(I,1), packet_dst, src_buf, dst_buf, r_idx);      disp(msg);
            end
        end
        
    end
   
        
end


end

