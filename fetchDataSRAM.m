function [ pushedPackets ] = fetchDataSRAM( NN_type, image_idx, blk_idx, currPosition )
% Fetches data from SRAM to MACs

global p_imgSize;   global imgSize;
global NETWORK;     global CNN;         global ROUTER;
global SRAM;        global PE;          global SRAM_cap;
global stallMAC;    global packetID;
global pushedPackets;

if (SRAM_cap)
    p_blkRow  = CNN.imgWidth/(p_imgSize*NETWORK.num_rows);
    p_blkCol  = CNN.imgHeight/(p_imgSize*NETWORK.num_cols);
else
    p_blkRow  = 1;   p_blkCol  = 1;
end

blk_idxRow  = floor((blk_idx-1)/p_blkCol) + 1;
blk_idxCol  = mod(blk_idx-1, p_blkCol) + 1;

whole_image = [];
for i = 1:p_blkRow
    one_row     = [];
    for j = 1:p_blkCol
        one_row = [one_row, image_idx{(i-1)*p_blkCol + j}];
    end
    whole_image = [whole_image; one_row];
end

currImg         = image_idx{blk_idx};       % current image that is being handled by PEs (a group of MACs)
currImg_offset  = [(blk_idxRow-1)*imgSize, (blk_idxCol-1)*imgSize];
% pushedPackets   = [];

global sim_t;       % needs 'sim_t' to generate new packet for SRAM->SRAM transfer (neighboring cells)


% convolutional layer
if strcmp(NN_type, 'CNN')

    for iRow = 1:NETWORK.num_rows
        for iCol = 1:NETWORK.num_cols
            
            pe_idx  = (iRow-1)*NETWORK.num_cols + iCol;           
            
            mac_idx = PE(pe_idx).mac_idx;
            
            % find the (center) pixel location for convolution operation
            pixel_offset = [(iRow-1), (iCol-1)];
            pixel_addr  = p_imgSize * pixel_offset + currPosition{iRow,iCol};        % pixel address in currImg (ex: [1, 3])
            
            % find relative kernel offset for convolution operation
            conv_cnt    = PE(pe_idx).MAC(mac_idx).conv_cnt;
            kernel_row  = floor(conv_cnt/CNN.tempWidth) - 1;
            kernel_col  = mod(conv_cnt,CNN.tempWidth) - 1;
                        
            % fetch in data from local SRAM if data is present
            kernelID_offset = SRAM(pe_idx).packet(1,4);    % weights are all stored in local SRAM of each PE
            currID  = image_idx{blk_idx}(pixel_addr(1), pixel_addr(2));
            
            % fetch in data from SRAM to MAC if corresponding MAC is not computing 
            if (~PE(pe_idx).MAC(mac_idx).compute_flag && ~stallMAC(iRow,iCol) && (PE(pe_idx).MAC(mac_idx).conv_cnt < CNN.tempWidth*CNN.tempHeight) && PE(pe_idx).MAC(mac_idx).operand_cnt == 0)
                %% fetch kernel/weights into PE register
                % always in local SRAM
                packet_idx = find(SRAM(pe_idx).packet(:,4) == kernelID_offset+conv_cnt);
                PE(pe_idx).MAC(mac_idx).packet(1,:) = SRAM(pe_idx).packet(packet_idx,:);
                PE(pe_idx).MAC(mac_idx).operand_cnt = PE(pe_idx).MAC(mac_idx).operand_cnt + 1;
                
                %% fetch cell state for convolution operation
                % ** check boundary **
                % if 'out of bound' in terms of whole image, there is no neighbor cells connected
                % then, generate null packet with 'gen_t'='arr_t'='sim_t' with
                % 'src'='dst'=current node index (ex: 1 ~ 16)
                idx_x   = currImg_offset(1) + pixel_addr(1) + kernel_row;
                idx_y   = currImg_offset(2) + pixel_addr(2) + kernel_col;
                
                [ bound_flag ] = checkBound(idx_x, idx_y, p_blkRow*imgSize, p_blkCol*imgSize);
                
                if (bound_flag == 0)
                    state_idx  = find(SRAM(pe_idx).packet(:,4) == whole_image(idx_x, idx_y));
                    % pixel index of neighboring/self cell state for convolution
                    if (~isempty(state_idx))
%                         packet_idx = find(SRAM(pe_idx).packet(:,4) == (state_idx-1))
                        PE(pe_idx).MAC(mac_idx).packet(2,:) = SRAM(pe_idx).packet(state_idx-1,:);
                        PE(pe_idx).MAC(mac_idx).operand_cnt = PE(pe_idx).MAC(mac_idx).operand_cnt + 1;
                    else
                        % generate packet to neighboring SRAM who requires packet
                        [neighbor_pe_idx] = find_neighborPE( whole_image(idx_x, idx_y) );
                        
                        buf_idx     = 1;
                        tempPacket  = [neighbor_pe_idx, pe_idx, sim_t, whole_image(idx_x, idx_y)-1, 4, sim_t];     % data type '4' indicates packet generated from MAC units
                        if (~ROUTER(neighbor_pe_idx,buf_idx).full)
                            ROUTER(neighbor_pe_idx,buf_idx).packet(ROUTER(neighbor_pe_idx,buf_idx).buf_ptr+1,:) = tempPacket;
                            ROUTER(neighbor_pe_idx,buf_idx).buf_ptr = ROUTER(neighbor_pe_idx,buf_idx).buf_ptr + 1;    % increaes buffer pointer in ROUTER node
                            
                            if (ROUTER(neighbor_pe_idx,buf_idx).buf_ptr == NETWORK.buffer_size)
                                ROUTER(neighbor_pe_idx,buf_idx).full     = 1;    % make full signal high if the CORE input buffer is filled with packets
                            end
                            
                            msg = sprintf('DEBUG: neighboring packet generated!! [%d]->[%d]\n', neighbor_pe_idx, pe_idx);    disp(msg);
                        else
                            pushedPackets = [pushedPackets; tempPacket];
                        end
                        
                        stallMAC(iRow,iCol)    = 1;
                    end
                else
                    PE(pe_idx).MAC(mac_idx).packet(2,:) = [pe_idx, pe_idx, sim_t, 0, 0, sim_t];     % 'packetID = 0' means cell with zero state value (with non-zero 'gen_t'='arr_t')
                    PE(pe_idx).MAC(mac_idx).operand_cnt = PE(pe_idx).MAC(mac_idx).operand_cnt + 1;
                end
                
                %% fetch cell offset for convolution operation
                % offset always in local SRAM
                packet_idx = find(SRAM(pe_idx).packet(:,4) == currID);
                PE(pe_idx).MAC(mac_idx).packet(3,:) = SRAM(pe_idx).packet(packet_idx,:);
                PE(pe_idx).MAC(mac_idx).operand_cnt = PE(pe_idx).MAC(mac_idx).operand_cnt + 1;
            end
            
        end        
    end

end


end

