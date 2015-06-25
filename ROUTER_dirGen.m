function [ dirLUT ] = ROUTER_dirGen( router_idx )
% Generates LUT for deciding ROUTER direction
% dirLUT (dir_1): X+, (dir_2): X-, (dir_3): Y+, (dir_4): Y-


global NETWORK;
nRows   = NETWORK.num_rows;
nCols   = NETWORK.num_cols;
nROUTER = nRows*nCols;

% current router node index
ref_row = ceil(router_idx/nRows);
ref_col = mod(router_idx, nRows);

if (ref_col == 0)
    ref_col = nCols;
end

dirLUT  = {};
dir1    = [];   dir2    = [];
dir3    = [];   dir4    = [];

for idx = 1:nROUTER
    % destination index
    row_idx = ceil(idx/nRows);
    col_idx = mod(idx, nRows);
    
    if (col_idx == 0)
        col_idx = nCols;
    end
    
    if (col_idx > ref_col)  % X+ direction
        dir1 = [dir1, idx];
    elseif (col_idx < ref_col)  % X- direction
        dir2 = [dir2, idx];
    else
        if (row_idx > ref_row)  % Y+ direction
            dir3 = [dir3, idx];
        elseif (row_idx < ref_row)  % Y- direction
            dir4 = [dir4, idx];
        end 
    end
end

dirLUT = {dir1; dir2; dir3; dir4};

end

