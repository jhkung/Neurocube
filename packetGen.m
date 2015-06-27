function [ genPacket, packetID, image_idx ] = packetGen( NN_type, DRAM_type, num_MAC )
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
    DRAM_router_node    = [6, 7];       % 2 channels
%     DRAM_router_node    = [6, 7; 10, 11];     % 4 channels
else
    error('DRAM TYPE NOT RECOGNIZED!');
end


[M, N]      = size(DRAM_router_node);   % M*N = # channels
packetID    = 1;    % packet index for generated packets in global controller
image_idx   = [];
if strcmp(NN_type, 'CNN')
    
    for chan_row_idx = 1:M
        for chan_col_idx = 1:N
            
            gen_t   = 1;    % packet generation order
            chan_idx    = (chan_row_idx-1)*N + chan_col_idx;
            
            % feedback template (A): each SRAM address (Nr=1: 1~9, Nr=2: 1~25)
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
        end
    end    
    
    init_gen_t  = gen_t;
    remain_cap  = SRAM(1).capacity - tempHeight*tempWidth;    % remaining capacity per SRAM (# words)
    
    % to generate an image of packetID to be used as a reference in SRAM-PE interaction
    img_ptr_x = 0;      img_ptr_y = 0;      
    
    if (remain_cap >= 2*p_imgWidth*p_imgHeight)
        % if SRAM capacity can cover cell states of a partial image
        for chan_row_idx = 1:M
            for chan_col_idx = 1:N
                gen_t       = init_gen_t;    % packet generation order
                chan_idx    = (chan_row_idx-1)*N + chan_col_idx;
                
                % cell states (each SRAM stores of each partial image)
                % offset (B*U + Z)
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
                                                                
                                % 'image_idx' generation
                                tmp_row   = mod(row_idx,nRows/M);      tmp_col   = mod(col_idx,nCols/N);
                                if (tmp_row == 0)
                                    tmp_row = nRows/M;
                                end
                                
                                if (tmp_col == 0)
                                    tmp_col = nCols/N;
                                end
                                
                                img_ptr_x   = (chan_row_idx-1)*imgHeight/M + (tmp_row-1)*p_imgHeight + p_row_idx;
                                img_ptr_y   = (chan_col_idx-1)*imgWidth/N + (tmp_col-1)*p_imgWidth + p_col_idx;                              
                                image_idx(img_ptr_x,img_ptr_y) = packetID;
                                
                                packetID    = packetID + 1;
                            end
                        end     % END partial image loop
                    end
                end     % END entire image loop                                
                %             msg = sprintf('[channel:%d] state & offset packets for DRAM has been generated', chan_idx);
                %             display(msg);
            end
        end        
    else
        % if SRAM capacity can't cover cell states of a partial image
        p_len       = floor(sqrt(remain_cap));     p_len = p_len/2;     % partial length covered by each ROUTER/PE node (divided by 2 because SRAM needs to store both state and offset)
        pixel_cnt   = 0;        nPixel = imgWidth*imgHeight;    read_done   = 0;
                
        if (mod(imgWidth,p_len*nCols) ~= 0 || mod(imgHeight,p_len*nRows))
            error('Please check SRAM capacity to make computation simple!');
        else
            nRow_blk = imgHeight/(p_len*nRows);
            nCol_blk = imgWidth/(p_len*nCols);
        end
        
        while (~read_done)
            for blk_row_idx = 1:nRow_blk
                for blk_col_idx = 1:nCol_blk
                    offset = (blk_row_idx-1)*(p_len*nRows) + (blk_col_idx-1)*(p_len*nCols);     % pixel offset depending on router nodes covering at each time frame
                    
                    for chan_row_idx = 1:M
                        for chan_col_idx = 1:N
                            gen_t       = init_gen_t;    % packet generation order
                            chan_idx    = (chan_row_idx-1)*N + chan_col_idx;
                            
                            % cell states (each SRAM stores of each partial image)
                            % offset (B*U + Z)
                            for row_idx = (nRows/M)*(chan_row_idx-1)+1:1:(nRows*chan_row_idx)/M
                                for col_idx = (nCols/N)*(chan_col_idx-1)+1:1:(nCols*chan_col_idx)/N
                                    for p_row_idx = 1:p_len
                                        for p_col_idx = 1:p_len
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
                                                                                        
                                            pixel_cnt   = pixel_cnt + 1;
                                        end
                                    end                                    
                                end
                            end
                            
                        end
                    end
                    
                    init_gen_t  = gen_t;                    
                end
            end           
            
            if (pixel_cnt == nPixel)
                read_done = 1;
            end
        end     % END while loop until whole pixels are read out as a packet
    end
else    % TODO: add more NN types (MLP, ConvNN, RNN, HTM, ...)
    error('NN TYPE NOT RECOGNIZED!');
end

genPacket   = [];
for idx = 1:M*N
    genPacket = [genPacket; DRAM(idx).packet];
end


end

