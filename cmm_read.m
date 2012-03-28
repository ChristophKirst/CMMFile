% read data entry form binary file fid 
% created by c++ via cmmfile.h or or by Mathematica via CMMFile.m
% a list with Dimensions = {d1 d2 ... dn} in Mathematica/c++ 
% results in a matlab matrix of size =[dn-1 dn dn-2 dn-3 ... d2 d1] !

% note: 1) a flat list of values as written to the binary file is
% read via fread as a column vector [a; b; c] of size = n
% 2) reshape is working column wise whereas
% Flatten in Mathematica and write out in c++ is working row wise !!!

function data = cmm_read(fid, nr, ns) 
    if nargin < 2
       nr = -1; 
       ns = 0;
    elseif nargin <3
       ns = nr;
       nr = 1;
    end
    

    % read type
    t = cmm_read_type(fid);

    if isempty(t) % t == ''
        if feof(fid)
           data = [];
           return
        end
    end

    if strcmp(t, 'S')
       %have a sequence of data
       fseek(fid, -1, 'cof');
       data = cmm_read_sequence(fid);
    else
      % read dim
      s = cmm_read_dim(fid);
      % read data
      data = cmm_read_data(fid, t, s, nr, ns);
    end
end






