function hs = cmm_read_header_sequence(fid)
   t = cmm_read_type(fid);
   if ~strcmp(t,'S')
      error(['cmm_read_header_sequence not at start of sequence: ' t]);
   end
   
   t = cmm_read_type(fid);
   k = 1;
   while (~strcmp(t, 'E') && ~feof(fid))
      s = cmm_read_dim(fid);
      hs{k,1} = t;
      hs{k,2} = s;
      k=k+1;
      t = cmm_read_type(fid);
   end
   
   if ~strcmp(t,'E')
      error(['cmm_read_header_sequence no end of sequence: ' t]);
   end
end