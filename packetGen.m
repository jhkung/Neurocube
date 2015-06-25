function [ genPacket, packetID ] = packetGen( NN_type, DRAM_type, num_MAC )
% Packet generation for various types of NNs


% variable declaration
global DRAM;    global SRAM;
global NETWORK; global CNN;
global DRAM_router_node;

nRows       = NETWORK.num_rows;
nCols       = NETWORK.num_cols;
nCores      = nRows * nCols * num_MAC;

imgWidth    = CNN.imgWidth;     imgHeight   = CNN.imgHeight;
p_imgWidth  = CNN.p_imgWidth;   p_imgHeight = CNN.p_imgHeight;
tempWidth   = CNN.tempWidth;    tempHeight  = CNN.tempHeight;

if (mod(imgWidth,nCols) > 0 || mod(imgHeight,nRows) > 0)
    warning ('imgWidth/nCols or imgHeight/nRows should be integer!');
end


% packet generation (DRAM packet has format '[src, dst, gen_time, packetID, data_type]')
if strcmp(DRAM_type, 'DDR3')
    
    % ROUTER node connected to each DRAM channel (MUST REPRESENT IT BY A MATRIX AS ACTUAL TOPOLOGY!!!)
%     DRAM_router_node    = [6, 7; 10, 11];     % 4 channels
    DRAM_router_node    = [6, 7];       % 2 channels

else
    error('DRAM TYPE NOT RECOGNIZED!');
end

[M, N]      = size(DRAM_router_node);   % M*N = # channels
packetID    = 1;    % packet index for generated packets in global controller
if strcmp(NN_type, 'CNN')
    for chan_row_idx = 1:M
        for chan_col_idx = 1:N
            
            gen_t   = 1;    % packet generation order
            chan_idx    = (chan_row_idx-1)*N + chan_col_idx;

            % feedback template (A): each SRAM address (Nr = 1: 1~9)
            % connected to each ROUTER node (assume space invariance)
            for row_idx = (nRows/M)*(chan_row_idx-1)+1:1:(nRows*chan_row_idx)/M
                for col_idx = (nCols/N)*(chan_col_idx-1)+1:1:(nCols*chan_col_idx)/N
                    for temp_row = 1:tempHeight
                        for temp_col = 1:tempWidth
                            
                            dst         = (row_idx - 1)*nCols + col_idx;
                            DRAM(chan_idx).packet(gen_t,:)  = [DRAM_router_node(chan_idx), dst, gen_t, packetID, 1];
                            gen_t       = gen_t + 1;
                            packetID    = packetID + 1;
                            
                        end
                    end
                end
            end
            
%             msg = sprintf('[channel:%d] template packets for DRAM has been generated', chan_idx);
%             display(msg);
            
            remain_cap  = SRAM(1).capacity - tempHeight * tempWidth;    % remaining capacity per SRAM (# words)
            
            % cell states (each SRAM stores of each partial image)
            % offset (B*U + Z)
            if (remain_cap > 2*p_imgWidth*p_imgHeight)
                % if SRAM capacity can cover cell states of a partial image
                for row_idx = (nRows/M)*(chan_row_idx-1)+1:1:(nRows*chan_row_idx)/M
                    for col_idx = (nCols/N)*(chan_col_idx-1)+1:1:(nCols*chan_col_idx)/N
                        for p_row_idx = 1:p_imgHeight
                            for p_col_idx = 1:p_imgWidth
                                % cell state
                                dst         = (row_idx - 1)*nCols + col_idx;
                                DRAM(chan_idx).packet(gen_t,:)  = [DRAM_router_node(chan_idx), dst, gen_t, packetID, 2];
                                gen_t       = gen_t + 1;
                                packetID    = packetID + 1;
                                
                                % offset
                                dst         = (row_idx - 1)*nCols + col_idx;
                                DRAM(chan_idx).packet(gen_t,:)  = [DRAM_router_node(chan_idx), dst, gen_t, packetID, 3];
                                gen_t       = gen_t + 1;
                                packetID    = packetID + 1;
                                
                            end
                        end     % END partial image loop
                    end
                end     % END entire image loop
            else
                %% TODO: if SRAM cannot store all cell states in a partial image
            end
            
%             msg = sprintf('[channel:%d] state & offset packets for DRAM has been generated', chan_idx);
%             display(msg);
        end
    end
else
    error('NN TYPE NOT RECOGNIZED!');
end

genPacket   = [];
for idx = 1:M*N
    genPacket = [genPacket; DRAM(idx).packet];
end


end

