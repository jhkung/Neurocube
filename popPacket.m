function [ ] = popPacket( )
% Fetch packet from DRAM to connected ROUTER node
% Simply increase 'gen_time' of packet by 't_access + t_interc'

global DRAM;    global ROUTER;  global NETWORK;
global DRAM_router_node;        global packetHistory;
global sim_t;

[M, N]      = size(DRAM_router_node);   % M*N = # channels


% packet: [src, dst, gen_time, packetID, data_type]
% router buffer arr: 'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN', 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'
if (~isempty(DRAM(1).packet))
    estimated_arr_time = DRAM(1).packet(1,3) + +DRAM(1).t_access+DRAM(1).t_interc;
    if (sim_t == estimated_arr_time)
        
        for row_idx = 1:M
            for col_idx = 1:N
                
                DRAM_idx    = (row_idx-1)*N + col_idx;      % DRAM index
                ROUTER_idx  = DRAM_router_node(row_idx, col_idx);   % ROUTER index
                
                % if router buffer connected to DRAM input is not full -> fetch packet from DRAM
                buf_idx     = 2;    % DRAM input buffer in each router node
                
                if (~ROUTER(ROUTER_idx,buf_idx).full)
                    
                    % update arrival time of data packet depending on DRAM latency
                    ROUTER(ROUTER_idx,buf_idx).packet(ROUTER(ROUTER_idx,buf_idx).buf_ptr+1,:) = [DRAM(DRAM_idx).packet(1,:), DRAM(DRAM_idx).packet(1,3)+DRAM(DRAM_idx).t_access+DRAM(DRAM_idx).t_interc];
                    
                    packetHistory     = [packetHistory; DRAM(DRAM_idx).packet(1,:), DRAM(DRAM_idx).packet(1,3)+DRAM(DRAM_idx).t_access+DRAM(DRAM_idx).t_interc];
                    
                    
                    DRAM(DRAM_idx).packet   = DRAM(DRAM_idx).packet(2:end,:);       % update packet queue in DRAM
                    ROUTER(ROUTER_idx,buf_idx).buf_ptr = ROUTER(ROUTER_idx,buf_idx).buf_ptr + 1;    % increaes buffer pointer in ROUTER node connected to DRAM channel
                    
                    if (ROUTER(ROUTER_idx,buf_idx).buf_ptr == NETWORK.buffer_size)
                        ROUTER(ROUTER_idx,buf_idx).full     = 1;    % make full signal high if the DRAM input buffer is filled with packets
                    end
                    
                    %                 packetHistory(DRAM_idx).packet(num_history+1,:)     = ROUTER(ROUTER_idx,buf_idx).packet(ROUTER(ROUTER_idx,buf_idx).buf_ptr,:);
                else
                    str = sprintf('[sim_t @ %d] DRAM_IN buffer in ROUTER(%d) is full...', sim_t, ROUTER_idx);
                    disp(str);
                    
                    DRAM(DRAM_idx).packet(:,3)   = DRAM(DRAM_idx).packet(:,3) + 1;      % increase 'gen_t' in DRAM package if buffer is full
                end
            end
        end
        
    end
end


end

