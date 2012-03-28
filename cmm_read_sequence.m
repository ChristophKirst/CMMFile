%read sequence of binary data form fid
function data = cmm_read_sequence(fid)
   hs = cmm_read_header_sequence(fid);
   data = cmm_read_data_sequence(fid,hs);
end