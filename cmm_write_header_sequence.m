function cmm_write_header_sequence(fid, hs)
   cmm_write_start_sequence(fid);
   for i=1:length(hs)
      cmm_write_type(fid, hs{i,1});
      cmm_write_dim(fid, hs{i,2});
   end
   cmm_write_end_sequence(fid);
   global CMMHeaderSequence;
   CMMHeaderSequence = hs;
   global CMMActualHeader;
   CMMActualHeader = 1;
end