function [ outPacket ] = popNeighborData( inPacket )
% Fetches data from DRAM to SRAM for neighbor cells
% inPacket: input neighbor packet list

global DRAM;    global DRAM_router_node;
global ROUTER;  global NETWORK;
global packetHistory;
global nNeighborRead;   global sim_t;

[M, N]      = size(DRAM_router_node);   % M*N = # channels

if (~isempty(inPacket))
%     estimated_arr_time = neighborPacket(:,3) + DRAM(1).t_access + DRAM(1).t_interc;
          
    packetPTR = find(inPacket(:,3) == (sim_t - (DRAM(1).t_access + DRAM(1).t_interc)));
    
    for i = 1:length(packetPTR)
        curr_row = packetPTR(i);
        [row_idx, col_idx] = find(DRAM_router_node == inPacket(curr_row,1));
        
        DRAM_idx    = (row_idx-1)*N + col_idx;      % DRAM index
        ROUTER_idx  = DRAM_router_node(row_idx, col_idx);   % ROUTER index
        
        DRAM(DRAM_idx).busy = 1;
        
        % if router buffer connected to DRAM input is not full -> fetch packet from DRAM
        buf_idx     = 2;    % DRAM input buffer in each router node
        
        if (~ROUTER(ROUTER_idx,buf_idx).full)
            % update arrival time of data packet depending on DRAM latency
            ROUTER(ROUTER_idx,buf_idx).packet(ROUTER(ROUTER_idx,buf_idx).buf_ptr+1,:) = [inPacket(curr_row,:), inPacket(curr_row,3)+DRAM(DRAM_idx).t_access+DRAM(DRAM_idx).t_interc];
            
            packetHistory     = [packetHistory; inPacket(curr_row,:), inPacket(curr_row,3)+DRAM(DRAM_idx).t_access+DRAM(DRAM_idx).t_interc];
            
            if (packetHistory(end,5) == 2 || packetHistory(end,5) == 3)
                nNeighborRead = nNeighborRead + 1;      % number of neighbor pixels (cell states) read from DRAM
            end
            
            % update neighborPacket queue
            if (curr_row == 1)
                inPacket   = inPacket(2:end,:);
            elseif (curr_row == size(inPacket,1))
                inPacket   = inPacket(1:end-1,:);
            else
                inPacket   = [inPacket(1:curr_row-1,:); inPacket(curr_row+1:end,:)];
            end
            
            packetPTR = packetPTR - 1;
            
            ROUTER(ROUTER_idx,buf_idx).buf_ptr = ROUTER(ROUTER_idx,buf_idx).buf_ptr + 1;    % increaes buffer pointer in ROUTER node connected to DRAM channel
            
            if (ROUTER(ROUTER_idx,buf_idx).buf_ptr == NETWORK.buffer_size)
                ROUTER(ROUTER_idx,buf_idx).full     = 1;    % make full signal high if the DRAM input buffer is filled with packets
            end            
        else
            str = sprintf('[sim_t @ %d] DRAM_IN buffer in ROUTER(%d) is full (Neighbor)...', sim_t, ROUTER_idx);
            disp(str);
            
            inPacket(:,3)   = inPacket(:,3) + 1;      % increase 'gen_t' in neighbor packets if buffer is full
        end
    end
        
        
end

outPacket = inPacket;
    
end

