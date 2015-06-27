%% Check Indexing Error
function [ flag ] = checkBound(idx, idy, num_row, num_col)

    if ( idx < 1 || idy < 1 || idx > num_row || idy > num_col )
        flag = 1;
    else
        flag = 0;

end