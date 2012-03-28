%write next data in a sequence 
%defined when calling cmm_write_header_seqeunce
function cmm_write_data_sequence(fid, data)

   global CMMHeaderSequence;
   global CMMActualHeader;
   
   %check correct type
   t = CMMHeaderSequence{CMMActualHeader, 1};
   if ~(strcmp(cmm_type(data), t))
      error(['cmm_write_data_sequence type mismatch: ' t '<->' cmm_type(data)]);
   end
   
   %check correct dimensions
   s = CMMHeaderSequence{CMMActualHeader, 2};
   if (~isempty(s) && s(1) == -1)
      s(1) = length(data);
      cmm_write_size(fid, s(1));
   end
   
   ss = cmm_dim(data);
   if ~(length(s) == length(ss) && isequal(s,ss))
      error(['cmm_write_data_sequence size mismatch: ' num2str(s) '<->' num2str(ss)]);
   end
   
   cmm_write_data(fid, data, t, s);
   
   CMMActualHeader = mod(CMMActualHeader, length(CMMHeaderSequence)) + 1;
end