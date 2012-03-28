function cmm_write_header(fid, type, size)
   cmm_write_type(fid, type);
   cmm_write_dim(fid, size);
end