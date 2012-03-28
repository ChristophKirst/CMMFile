function s = cmm_read_dim(fid)
    d = fread(fid,1,'int32');
    s = fread(fid,d,'int32')';
end