function [ nNeighbor, neighborPacket ] = genNeighborArray(genPacket, image_idx)
% Generates array of the number of neighboring cells for each partial block

global SRAM;    global NETWORK;     global CNN;
global SRAM_cap;

% '[src, dst, gen_t, packetID, data_type]'
neighborPacket  = [];

if (SRAM_cap)
    p_imgSize = sqrt((SRAM(1).capacity - CNN.tempHeight*CNN.tempWidth)/2);
    imgSize   = p_imgSize*NETWORK.num_cols;
    p_blkRow  = CNN.imgWidth/(p_imgSize*NETWORK.num_rows);
    p_blkCol  = CNN.imgHeight/(p_imgSize*NETWORK.num_cols);
else
    p_imgSize = CNN.imgWidth/NETWORK.num_cols;
    imgSize   = p_imgSize*NETWORK.num_cols;
    p_blkRow  = 1;   p_blkCol  = 1;
end

global DRAM_router_node;    global PacketID;

[M, N]      = size(DRAM_router_node);
gen_t       = ones(M,N);

arr_idx     = 1;
Nr          = CNN.radius;
nBlk        = p_blkRow * p_blkCol;
nNeighbor   = zeros(1,nBlk);

if (nBlk > 1)
    for iRow = 1:p_blkRow
        for iCol = 1:p_blkCol            
            blk_idx = (iRow-1) * p_blkCol + iCol;
            
            % 1. left neighbor cells (includes corner)
            if (iCol > 1)
                neighbor_blk_idx = (iRow-1) * p_blkCol + (iCol-1);

                for idxR = 1:Nr
                    for idxCell = 1:imgSize
                        cellID = image_idx{neighbor_blk_idx}(idxCell, end-idxR+1);
                                                
                        % cell state
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                        
                        new_dst     = floor((idxCell-1)/p_imgSize)*NETWORK.num_cols + 1;      % update 'dst'
                        neighborPacket(arr_idx,2) = new_dst;
                        
                        [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        
                        
                        % cell offset
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                        
                        neighborPacket(arr_idx,2) = new_dst;                        
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;                        
                    end
                end
                
                % LT corner
                if (iRow > 1)
                    neighbor_blk_idx = (iRow-2) * p_blkCol + (iCol-1);
                    
                    for i_row = 1:Nr
                        for i_col = 1:Nr
                            cellID = image_idx{neighbor_blk_idx}(imgSize-i_row+1, imgSize-i_col+1);
                            
                            % cell state
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                            
                            new_dst     = 1;      % update 'dst'
                            neighborPacket(arr_idx,2) = new_dst;
                            
                            [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                            
                            
                            % cell offset
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                            
                            neighborPacket(arr_idx,2) = new_dst;                            
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        end
                    end
                end
                
                % LB corner
                if (iRow < p_blkRow)
                    neighbor_blk_idx = iRow * p_blkCol + (iCol-1);
                    
                    for i_row = 1:Nr
                        for i_col = 1:Nr
                            cellID = image_idx{neighbor_blk_idx}(i_row, imgSize-i_col+1);
                            
                            % cell state
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                            
                            new_dst     = (NETWORK.num_rows-1)*NETWORK.num_cols + 1;      % update 'dst'
                            neighborPacket(arr_idx,2) = new_dst;
                            
                            [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                            
                            
                            % cell offset
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                            
                            neighborPacket(arr_idx,2) = new_dst;                            
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        end
                    end
                end
            end
            
            
            % 2. right neighbor cells (includes corner)
            if (iCol < p_blkCol)
                neighbor_blk_idx = (iRow-1) * p_blkCol + (iCol+1);
                
                for idxR = 1:Nr
                    for idxCell = 1:imgSize
                        cellID = image_idx{neighbor_blk_idx}(idxCell, idxR);
                                                
                        % cell state
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                        
                        new_dst     = (floor((idxCell-1)/p_imgSize) + 1)*NETWORK.num_cols;      % update 'dst'
                        neighborPacket(arr_idx,2) = new_dst;
                        
                        [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        
                        
                        % cell offset
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                        
                        neighborPacket(arr_idx,2) = new_dst;                        
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                    end
                end
                
                % RT corner
                if (iRow > 1)
                    neighbor_blk_idx = (iRow-2) * p_blkCol + (iCol+1);
                    
                    for i_row = 1:Nr
                        for i_col = 1:Nr
                            cellID = image_idx{neighbor_blk_idx}(imgSize-i_row+1, i_col);
                            
                            % cell state
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                            
                            new_dst     = NETWORK.num_cols;      % update 'dst'
                            neighborPacket(arr_idx,2) = new_dst;
                            
                            [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                            
                            
                            % cell offset
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                            
                            neighborPacket(arr_idx,2) = new_dst;                            
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        end
                    end
                end
                
                % RB corner
                if (iRow < p_blkRow)
                    neighbor_blk_idx = iRow * p_blkCol + (iCol+1);
                    
                    for i_row = 1:Nr
                        for i_col = 1:Nr
                            cellID = image_idx{neighbor_blk_idx}(i_row, i_col);
                            
                            % cell state
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                            
                            new_dst     = NETWORK.num_rows*NETWORK.num_cols;      % update 'dst'
                            neighborPacket(arr_idx,2) = new_dst;
                            
                            [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                            
                            
                            % cell offset
                            neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                            
                            neighborPacket(arr_idx,2) = new_dst;                            
                            neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                                                        
                            gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                            arr_idx     = arr_idx + 1;                        
                            nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        end
                    end
                end
            end
            
            
            % 3. bottom neighbor cells (excludes corner)
            if (iRow < p_blkRow)
                neighbor_blk_idx = iRow * p_blkCol + iCol;
                
                for idxR = 1:Nr
                    for idxCell = 1:imgSize
                        cellID = image_idx{neighbor_blk_idx}(idxR, idxCell);
                                                
                        % cell state
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                        
                        new_dst     = (NETWORK.num_rows-1)*NETWORK.num_cols + floor((idxCell-1)/p_imgSize) + 1;      % update 'dst'
                        neighborPacket(arr_idx,2) = new_dst;
                        
                        [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        
                        
                        % cell offset
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                        
                        neighborPacket(arr_idx,2) = new_dst;                        
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                    end
                end
            end
            
            
            % 4. top neighbor cells (excludes corner)
            if (iRow > 1)
                neighbor_blk_idx = (iRow-2) * p_blkCol + iCol;

                for idxR = 1:Nr
                    for idxCell = 1:imgSize
                        cellID = image_idx{neighbor_blk_idx}(end-idxR+1, idxCell);
                                                
                        % cell state
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID-1),:);
                        
                        new_dst     = floor((idxCell-1)/p_imgSize) + 1;      % update 'dst'
                        neighborPacket(arr_idx,2) = new_dst;
                        
                        [src_i, src_j]  = find(DRAM_router_node == neighborPacket(arr_idx,1));
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                        
                        
                        % cell offset
                        neighborPacket(arr_idx,:) = genPacket(find(genPacket(:,4) == cellID),:);                        
                        neighborPacket(arr_idx,2) = new_dst;                        
                        neighborPacket(arr_idx,3) = gen_t(src_i, src_j);     % update gen_t of DRAM channel connected to 'src' node
                        
                        gen_t(src_i, src_j) = gen_t(src_i, src_j) + 1;
                        arr_idx     = arr_idx + 1;
                        
                        nNeighbor(blk_idx) = nNeighbor(blk_idx) + 1;
                    end
                end
            end
            
            
        end
    end
end



end

