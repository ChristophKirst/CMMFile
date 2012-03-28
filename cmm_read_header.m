function [t s] = cmm_read_header(fid)
   t = cmm_read_type(fid);
   s = cmm_read_dim(fid);
end